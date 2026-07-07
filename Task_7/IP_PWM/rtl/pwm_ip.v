module pwm_ip (
    input  wire        clk,
    input  wire        resetn,
    input  wire        isIO,
    input  wire        mem_wstrb,
    input  wire [31:0] mem_addr,
    input  wire [31:0] mem_wdata,
    output reg  [31:0] pwm_rdata,
    output wire         pwm_out,
    output wire         pwm_sel
);
    localparam PWM_BASE   = 32'h0040_1000;
    localparam OFF_CTRL   = 4'h0;
    localparam OFF_PERIOD = 4'h4;
    localparam OFF_DUTY   = 4'h8;
    localparam OFF_STATUS = 4'hC;

    assign pwm_sel = isIO & (mem_addr[31:12] == PWM_BASE[31:12]);
    wire wr = pwm_sel & mem_wstrb;

    reg [31:0] ctrl, period, duty;
    wire en  = ctrl[0];
    wire pol = ctrl[1];

    always @(posedge clk) begin
        if (!resetn) begin
            ctrl   <= 32'h3;       // Bit 0 (EN)=1, Bit 1 (POL)=1
            period <= 32'd1000;    // 1000 ticks period
            duty   <= 32'd100;     // 100 ticks duty (10% brightness)
        end else if (wr && mem_addr[11:4] == 8'h0) begin
            if (mem_addr[3:2] == (OFF_CTRL>>2))   ctrl   <= mem_wdata;
            if (mem_addr[3:2] == (OFF_PERIOD>>2)) period <= (mem_wdata == 0) ? 32'h1 : mem_wdata;
            if (mem_addr[3:2] == (OFF_DUTY>>2))   duty   <= mem_wdata;
            // OFF_STATUS: read-only
        end
    end

    // Free-running counter, wraps at PERIOD-1
    reg [31:0] cnt;
    always @(posedge clk) begin
        if (!resetn)                cnt <= 32'h0;
        else if (!en)                cnt <= 32'h0;
        else if (cnt >= period - 1) cnt <= 32'h0;
        else                         cnt <= cnt + 1'b1;
    end

    wire pwm_raw = (cnt < duty);
    wire pwm_active = pol ? ~pwm_raw : pwm_raw;
    assign pwm_out = en ? pwm_active : (pol ? 1'b1 : 1'b0);

    always @(*) begin
        if (!pwm_sel || mem_addr[11:4] != 8'h0) pwm_rdata = 32'h0;
        else case (mem_addr[3:2])
            (OFF_CTRL>>2):   pwm_rdata = ctrl;
            (OFF_PERIOD>>2): pwm_rdata = period;
            (OFF_DUTY>>2):   pwm_rdata = duty;
            (OFF_STATUS>>2): pwm_rdata = {cnt[15:0], 15'h0, en};
            default:         pwm_rdata = 32'h0;
        endcase
    end
endmodule


