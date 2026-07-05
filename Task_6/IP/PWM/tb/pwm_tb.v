`timescale 1ns/1ps
module pwm_tb;
    reg clk;
    reg resetn;
    reg isIO;
    reg mem_wstrb;
    reg [31:0] mem_addr;
    reg [31:0] mem_wdata;
    wire [31:0] pwm_rdata;
    wire        pwm_out;
    wire        pwm_sel;

    localparam PWM_BASE   = 32'h0040_1000;
    localparam OFF_CTRL   = 32'h00;
    localparam OFF_PERIOD = 32'h04;
    localparam OFF_DUTY   = 32'h08;
    localparam OFF_STATUS = 32'h0C;

    pwm_ip DUT (
        .clk(clk), .resetn(resetn), .isIO(isIO),
        .mem_wstrb(mem_wstrb), .mem_addr(mem_addr), .mem_wdata(mem_wdata),
        .pwm_rdata(pwm_rdata), .pwm_out(pwm_out), .pwm_sel(pwm_sel)
    );

    always #5 clk = ~clk;

    task pwm_write(input [31:0] off, input [31:0] data);
        begin
            @(posedge clk);
            mem_addr  = PWM_BASE + off;
            mem_wdata = data;
            mem_wstrb = 1;
            @(posedge clk);
            mem_wstrb = 0;
        end
    endtask

    integer errors = 0;
    integer high_count, low_count, i;

    initial begin
        $dumpfile("pwm_tb.vcd");
        $dumpvars(0, pwm_tb);

        clk = 0; resetn = 0; isIO = 1;
        mem_wstrb = 0; mem_addr = 0; mem_wdata = 0;
        #20 resetn = 1;

        // --- Test 1: PERIOD=10, DUTY=4, POL=0, EN=1 -> expect 4 high, 6 low per cycle ---
        pwm_write(OFF_PERIOD, 32'd10);
        pwm_write(OFF_DUTY,   32'd4);
        pwm_write(OFF_CTRL,   32'b01); // EN=1, POL=0

        high_count = 0; low_count = 0;
        for (i = 0; i < 10; i = i + 1) begin
            @(posedge clk);
            if (pwm_out) high_count = high_count + 1;
            else         low_count  = low_count + 1;
        end

        $display("Test 1 (PERIOD=10 DUTY=4 POL=0): high=%0d low=%0d", high_count, low_count);
        if (high_count == 4 && low_count == 6) $display("Test 1 PASS");
        else begin $display("Test 1 FAIL"); errors = errors + 1; end

        // --- Test 2: same PERIOD/DUTY, POL=1 (inverted) -> expect 4 low, 6 high ---
        pwm_write(OFF_CTRL, 32'b11); // EN=1, POL=1

        high_count = 0; low_count = 0;
        for (i = 0; i < 10; i = i + 1) begin
            @(posedge clk);
            if (pwm_out) high_count = high_count + 1;
            else         low_count  = low_count + 1;
        end

        $display("Test 2 (POL=1 inverted): high=%0d low=%0d", high_count, low_count);
        if (high_count == 6 && low_count == 4) $display("Test 2 PASS");
        else begin $display("Test 2 FAIL"); errors = errors + 1; end

        // --- Test 3: EN=0 forces inactive level (low, since POL=0 here) ---
        pwm_write(OFF_CTRL, 32'b00); // EN=0, POL=0
        @(posedge clk);
        if (pwm_out == 1'b0) $display("Test 3 PASS: EN=0 forces low");
        else begin $display("Test 3 FAIL: pwm_out=%b, expected 0", pwm_out); errors = errors + 1; end

        // --- Test 4: DUTY=0 -> always low while enabled ---
        pwm_write(OFF_DUTY, 32'd0);
        pwm_write(OFF_CTRL, 32'b01); // EN=1, POL=0
        high_count = 0;
        for (i = 0; i < 10; i = i + 1) begin
            @(posedge clk);
            if (pwm_out) high_count = high_count + 1;
        end
        if (high_count == 0) $display("Test 4 PASS: DUTY=0 always low");
        else begin $display("Test 4 FAIL: saw %0d high cycles", high_count); errors = errors + 1; end

        // --- Test 5: DUTY >= PERIOD -> always high ---
        pwm_write(OFF_DUTY, 32'd20); // > PERIOD(10)
        low_count = 0;
        for (i = 0; i < 10; i = i + 1) begin
            @(posedge clk);
            if (!pwm_out) low_count = low_count + 1;
        end
        if (low_count == 0) $display("Test 5 PASS: DUTY>=PERIOD always high");
        else begin $display("Test 5 FAIL: saw %0d low cycles", low_count); errors = errors + 1; end

        // --- Test 6: read-back sanity ---
        pwm_write(OFF_PERIOD, 32'd50);
        @(posedge clk);
        mem_addr = PWM_BASE + OFF_PERIOD;
        #1;
        if (pwm_rdata == 32'd50) $display("Test 6 PASS: PERIOD readback correct");
        else begin $display("Test 6 FAIL: got 0x%h", pwm_rdata); errors = errors + 1; end

        // --- Test 7: undefined offset returns 0 ---
        mem_addr = PWM_BASE + 32'h10; // beyond STATUS
        #1;
        if (pwm_rdata == 32'h0) $display("Test 7 PASS: undefined offset reads 0");
        else begin $display("Test 7 FAIL: got 0x%h", pwm_rdata); errors = errors + 1; end

        if (errors == 0) $display("ALL PWM TESTS PASSED");
        else              $display("%0d PWM TEST(S) FAILED", errors);

        $finish;
    end
endmodule
