`timescale 1ns/1ps
module gpio_tb;
    reg clk;
    reg resetn;
    reg isIO;
    reg mem_wstrb;
    reg [31:0] mem_addr;
    reg [31:0] mem_wdata;
    reg [31:0] gpio_in;
    wire [31:0] gpio_rdata;
    wire [31:0] gpio_out;
    wire        gpio_sel;

    localparam GPIO_BASE = 32'h0040_2000;
    localparam OFF_DATA  = 32'h00;
    localparam OFF_DIR   = 32'h04;
    localparam OFF_READ  = 32'h08;

    gpio_ip DUT (
        .clk(clk), .resetn(resetn), .isIO(isIO),
        .mem_wstrb(mem_wstrb), .mem_addr(mem_addr), .mem_wdata(mem_wdata),
        .gpio_in(gpio_in),
        .gpio_rdata(gpio_rdata), .gpio_out(gpio_out), .gpio_sel(gpio_sel)
    );

    always #5 clk = ~clk;

    task gpio_write(input [31:0] off, input [31:0] data);
        begin
            @(posedge clk);
            mem_addr  = GPIO_BASE + off;
            mem_wdata = data;
            mem_wstrb = 1;
            @(posedge clk);
            mem_wstrb = 0;
        end
    endtask

    task gpio_read(input [31:0] off, output [31:0] rval);
        begin
            mem_addr = GPIO_BASE + off;
            #1;
            rval = gpio_rdata;
        end
    endtask

    integer errors = 0;
    reg [31:0] val;

    initial begin
        $dumpfile("gpio_tb.vcd");
        $dumpvars(0, gpio_tb);

        clk = 0; resetn = 0; isIO = 1;
        mem_wstrb = 0; mem_addr = 0; mem_wdata = 0; gpio_in = 32'h0;
        #20 resetn = 1;

        // Test 1: all outputs
        gpio_write(OFF_DIR,  32'hFFFFFFFF);
        gpio_write(OFF_DATA, 32'hDEADBEEF);
        gpio_read(OFF_READ, val);
        $display("Test 1 (all output): READ=0x%h", val);
        if (val == 32'hDEADBEEF) $display("Test 1 PASS");
        else begin $display("Test 1 FAIL"); errors = errors + 1; end

        // Test 2: all inputs, gpio_in drives the readback
        gpio_in = 32'hCCCCCCCC;
        gpio_write(OFF_DIR,  32'h00000000);
        gpio_write(OFF_DATA, 32'hCAFEBABE); // should not reach pins
        gpio_read(OFF_READ, val);
        $display("Test 2 (all input): READ=0x%h", val);
        if (val == 32'hCCCCCCCC) $display("Test 2 PASS");
        else begin $display("Test 2 FAIL"); errors = errors + 1; end

        // Test 3: mixed — top 16 output, bottom 16 input
        gpio_in = 32'h0000AAAA;
        gpio_write(OFF_DIR,  32'hFFFF0000);
        gpio_write(OFF_DATA, 32'h12345678);
        gpio_read(OFF_READ, val);
        $display("Test 3 (mixed): READ=0x%h", val);
        if (val == 32'h1234AAAA) $display("Test 3 PASS");
        else begin $display("Test 3 FAIL"); errors = errors + 1; end

        // Test 4: DATA readback is direction-independent
        gpio_read(OFF_DATA, val);
        if (val == 32'h12345678) $display("Test 4 PASS: DATA readback unaffected by DIR");
        else begin $display("Test 4 FAIL: got 0x%h", val); errors = errors + 1; end

        // Test 5: undefined offset returns 0
        gpio_read(32'h10, val);
        if (val == 32'h0) $display("Test 5 PASS: undefined offset reads 0");
        else begin $display("Test 5 FAIL: got 0x%h", val); errors = errors + 1; end

        // Test 6: access outside GPIO window returns 0 / doesn't assert gpio_sel
        mem_addr = 32'h0040_1000; // PWM's window, not GPIO's
        #1;
        if (gpio_sel == 1'b0 && gpio_rdata == 32'h0)
            $display("Test 6 PASS: out-of-window access ignored");
        else begin $display("Test 6 FAIL"); errors = errors + 1; end

        if (errors == 0) $display("ALL GPIO TESTS PASSED");
        else              $display("%0d GPIO TEST(S) FAILED", errors);

        $finish;
    end
endmodule
