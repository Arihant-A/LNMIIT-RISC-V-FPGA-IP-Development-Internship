module gpio_ip (
    input  wire        clk,
    input  wire        resetn,
    input  wire        isIO,
    input  wire        mem_wstrb,
    input  wire [31:0] mem_addr,
    input  wire [31:0] mem_wdata,
    input  wire [31:0] gpio_in,     // real external pin state
    output reg  [31:0] gpio_rdata,
    output wire [31:0] gpio_out,
    output wire         gpio_sel
);
    localparam GPIO_BASE   = 32'h0040_2000;  // 4KB-aligned window
    localparam OFF_DATA    = 4'h0;  // 0x00
    localparam OFF_DIR     = 4'h4;  // 0x04
    localparam OFF_READ    = 4'h8;  // 0x08

    assign gpio_sel = isIO & (mem_addr[31:12] == GPIO_BASE[31:12]);
    wire [3:0] off = mem_addr[5:2] << 2; // byte-aligned offset for readability only

    wire wr = gpio_sel & mem_wstrb;

    reg [31:0] gpio_data_reg;
    reg [31:0] gpio_dir_reg;

    always @(posedge clk) begin
        if (!resetn) begin
            gpio_data_reg <= 32'h0;
            gpio_dir_reg  <= 32'h0;
        end else begin
            if (wr && mem_addr[5:2] == (OFF_DATA>>2)) gpio_data_reg <= mem_wdata;
            if (wr && mem_addr[5:2] == (OFF_DIR>>2))  gpio_dir_reg  <= mem_wdata;
            // OFF_READ: deliberately no write — read-only
        end
    end

    wire [31:0] live_pins = (gpio_dir_reg & gpio_data_reg) | (~gpio_dir_reg & gpio_in);

    always @(*) begin
        if (!gpio_sel) gpio_rdata = 32'h0;   // outside window -> 0
        else case (mem_addr[5:2])
            (OFF_DATA>>2): gpio_rdata = gpio_data_reg;
            (OFF_DIR>>2):  gpio_rdata = gpio_dir_reg;
            (OFF_READ>>2): gpio_rdata = live_pins;
            default:       gpio_rdata = 32'h0;  // undefined offset in window -> 0
        endcase
    end

    assign gpio_out = gpio_data_reg;

endmodule
