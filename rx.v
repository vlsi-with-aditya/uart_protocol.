module rx(
    input clk,
    input rst,
    input i_rx_serial,
    output o_rx_dv,
    output [7:0] o_rx_byte
);

parameter clks_per_bit    = 868;
parameter clks_per_sample = 54;

localparam IDLE      = 3'b000;
localparam START     = 3'b001;
localparam DATA_BITS = 3'b010;
localparam STOP      = 3'b011;
localparam CLEANUP   = 3'b100;

reg [2:0] current_state;
reg [2:0] next_state;

reg r_rx_data_r = 1'b1;
reg r_rx_data   = 1'b1;

reg [9:0] r_clk_count  = 0;
reg [3:0] r_tick_count = 0;
reg [2:0] r_bit_index  = 0;
reg [7:0] r_rx_byte    = 0;
reg       r_rx_dv      = 0;


always @(posedge clk) begin
    if (rst)
        current_state <= IDLE;
    else
        current_state <= next_state;
end


always @(posedge clk) begin
    if (rst) begin
        r_tick_count <= 0;
        r_clk_count  <= 0;
    end else begin
        if (current_state == START && r_tick_count == 7 && r_clk_count == clks_per_sample - 1) begin
            r_clk_count  <= 0;
            r_tick_count <= 0;
        end else if (current_state != IDLE) begin
            if (r_clk_count < clks_per_sample - 1) begin
                r_clk_count <= r_clk_count + 1;
            end else begin
                r_clk_count <= 0;
                if (r_tick_count < 15)
                    r_tick_count <= r_tick_count + 1;
                else
                    r_tick_count <= 0;
            end
        end else begin
            r_clk_count  <= 0;
            r_tick_count <= 0;
        end
    end
end

always @(posedge clk) begin
    if (rst) begin
        r_rx_data_r <= 1'b1;
        r_rx_data   <= 1'b1;
    end else begin
        r_rx_data_r <= i_rx_serial;
        r_rx_data   <= r_rx_data_r;
    end
end


always @(*) begin
    next_state = current_state;

    case (current_state)
        IDLE : begin
            if (r_rx_data == 1'b0)
                next_state = START;
            else
                next_state = IDLE;
        end

        START : begin
            if (r_tick_count == 7) begin
                if (r_rx_data == 1'b0)
                    next_state = DATA_BITS;
                else
                    next_state = IDLE;
            end else
                next_state = START;
        end

        DATA_BITS : begin
            if (r_tick_count == 15 && r_bit_index == 7)
                next_state = STOP;
        end

      
        STOP : begin
            if (r_tick_count == 15) begin
                if (r_rx_data == 1'b1)
                    next_state = CLEANUP;
                else
                    next_state = IDLE;
            end
        end

        CLEANUP : begin
            next_state = IDLE;
        end

        default : next_state = IDLE;
    endcase
end

always @(posedge clk) begin
    if (rst) begin
        r_bit_index <= 0;
        r_rx_dv     <= 0;
        r_rx_byte   <= 0;
    end else begin
        case (current_state)
            IDLE : begin
                r_rx_dv     <= 0;
                r_bit_index <= 0;
            end

          
            DATA_BITS : begin
                if (r_tick_count == 15) begin
                    r_rx_byte[r_bit_index] <= r_rx_data;
                    if (r_bit_index < 7)
                        r_bit_index <= r_bit_index + 1;
                end
            end

            CLEANUP : begin
                r_rx_dv <= 1;
            end

            default : begin
                r_rx_dv <= 0;
            end
        endcase
    end
end

assign o_rx_dv   = r_rx_dv;
assign o_rx_byte = r_rx_byte;

endmodule
