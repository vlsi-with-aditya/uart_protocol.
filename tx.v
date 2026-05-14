module tx(
    input        clk,
    input        i_Rst,
    input        i_TX_Start,
    input [7:0]  i_TX_Byte,
    output       o_TX_Active,
    output reg   o_TX_Serial,
    output reg   o_TX_Done
);

parameter clk_per_bit = 868;

reg [9:0] clk_count = 0;

localparam IDLE      = 3'b000,
           START     = 3'b001,
           DATA_BITS = 3'b010,
           STOP      = 3'b011,
           CLEANUP   = 3'b100;

reg [2:0] current_state;
reg [2:0] next_state;


always @(posedge clk) begin
    if (i_Rst) begin
        clk_count <= 0;
    end else if (current_state == IDLE) begin
        clk_count <= 0;
    end else begin
        if (clk_count < clk_per_bit - 1)
            clk_count <= clk_count + 1;
        else
            clk_count <= 0;
    end
end

wire bit_done;
assign bit_done = (clk_count == clk_per_bit - 1);

reg [2:0] r_bit_index;

always @(posedge clk) begin
    if (i_Rst) begin
        r_bit_index <= 0;
    end else begin
        case (current_state)
            IDLE      : r_bit_index <= 0;
            DATA_BITS : begin
                if (bit_done) begin
                    if (r_bit_index < 7)
                        r_bit_index <= r_bit_index + 1;
                    else
                        r_bit_index <= 0;
                end
            end
            default   : r_bit_index <= 0;
        endcase
    end
end

always @(posedge clk) begin
    if (i_Rst)
        current_state <= IDLE;
    else
        current_state <= next_state;
end


always @(*) begin
    next_state = current_state;

    case (current_state)
        IDLE : begin
            if (i_TX_Start)
                next_state = START;
            else
                next_state = IDLE;
        end

        START : begin
            if (bit_done)
                next_state = DATA_BITS;
            else
                next_state = START;
        end

        DATA_BITS : begin
            if (bit_done) begin
                if (r_bit_index < 7)
                    next_state = DATA_BITS;
                else
                    next_state = STOP;
            end else
                next_state = DATA_BITS;
        end

        STOP : begin
            if (bit_done)
                next_state = CLEANUP;
            else
                next_state = STOP;
        end

        CLEANUP : begin
            next_state = IDLE;
        end

        default : next_state = IDLE;
    endcase
end


always @(posedge clk) begin
    if (i_Rst)
        o_TX_Serial <= 1'b1;
    else begin
        case (next_state)
            IDLE      : o_TX_Serial <= 1'b1;
            START     : o_TX_Serial <= 1'b0;
            DATA_BITS : o_TX_Serial <= i_TX_Byte[r_bit_index];
            STOP      : o_TX_Serial <= 1'b1;
            CLEANUP   : o_TX_Serial <= 1'b1;
            default   : o_TX_Serial <= 1'b1;
        endcase
    end
end

assign o_TX_Active = (current_state != IDLE);


always @(posedge clk) begin
    if (i_Rst)
        o_TX_Done <= 1'b0;
    else if (current_state == STOP && bit_done)
        o_TX_Done <= 1'b1;
    else
        o_TX_Done <= 1'b0;
end

endmodule
