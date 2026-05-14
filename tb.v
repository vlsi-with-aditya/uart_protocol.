module uart_tb();

reg clk = 0;
reg rst = 0;
reg i_TX_Start = 0;
reg [7:0] i_TX_Byte = 0;

wire w_TX_Serial;
wire w_TX_Active;
wire w_TX_Done;
wire w_RX_DV;
wire [7:0] w_RX_Byte;


tx #(.clk_per_bit(868)) TX (
    .clk        (clk),
    .i_Rst      (rst),
    .i_TX_Start (i_TX_Start),
    .i_TX_Byte  (i_TX_Byte),
    .o_TX_Active(w_TX_Active),
    .o_TX_Serial(w_TX_Serial),
    .o_TX_Done  (w_TX_Done)
);

rx #(.clks_per_bit(868), .clks_per_sample(54)) RX (
    .clk        (clk),
    .rst        (rst),
    .i_rx_serial(w_TX_Serial),
    .o_rx_dv    (w_RX_DV),
    .o_rx_byte  (w_RX_Byte)
);

always #5 clk = ~clk;

task send_byte;
    input [7:0] data;
    input [7:0] expected;
    integer timeout;
    begin
        @(posedge clk);
        i_TX_Byte  = data;
        i_TX_Start = 1;
        @(posedge clk);
        i_TX_Start = 0;

        
        timeout = 0;
        while (w_RX_DV !== 1'b1 && timeout < 200000) begin
            @(posedge clk);
            timeout = timeout + 1;
        end

        if (timeout >= 200000) begin
            $display("TIMEOUT - Sent: 0x%0h | RX never responded", data);
        end else begin
            @(posedge clk);
            if (w_RX_Byte == expected)
                $display("PASS - Sent: 0x%0h | Received: 0x%0h", data, w_RX_Byte);
            else
                $display("FAIL - Sent: 0x%0h | Expected: 0x%0h | Got: 0x%0h", data, expected, w_RX_Byte);
        end
    end
endtask

integer i;
reg [7:0] test_bytes [0:5];

initial begin
    test_bytes[0] = 8'h37;
    test_bytes[1] = 8'h55;
    test_bytes[2] = 8'hAA;
    test_bytes[3] = 8'hFF;
    test_bytes[4] = 8'h00;
    test_bytes[5] = 8'hA5;

    rst = 1;
    repeat(5) @(posedge clk);
    rst = 0;
    repeat(5) @(posedge clk);

    for (i = 0; i < 6; i = i + 1) begin
        send_byte(test_bytes[i], test_bytes[i]);
        repeat(10) @(posedge clk);
    end

    $display("Simulation complete.");
    $finish;
end

endmodule
