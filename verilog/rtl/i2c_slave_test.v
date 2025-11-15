`default_nettype none

module i2c_slave_test #(
    parameter SLAVE_ADDR = 7'h50
)(
    input  wire clk,
    input  wire rst_n,
    
    input  wire scl_i,
    input  wire sda_i,
    output wire sda_o,
    output wire sda_oe
);

    localparam STATE_IDLE = 4'd0;
    localparam STATE_ADDR = 4'd1;
    localparam STATE_ADDR_ACK = 4'd2;
    localparam STATE_REG_ADDR = 4'd3;
    localparam STATE_REG_ACK = 4'd4;
    localparam STATE_WRITE_DATA = 4'd5;
    localparam STATE_WRITE_ACK = 4'd6;
    localparam STATE_READ_DATA = 4'd7;
    localparam STATE_READ_ACK = 4'd8;

    reg [3:0] state;
    reg [3:0] bit_cnt;
    reg [7:0] shift_reg;
    /* verilator lint_off UNUSEDSIGNAL */
    reg [7:0] reg_addr;
    /* verilator lint_on UNUSEDSIGNAL */
    reg [7:0] registers [0:3];
    reg sda_out;
    reg sda_oen_reg;
    
    reg scl_sync1, scl_sync2, scl_sync3;
    reg sda_sync1, sda_sync2, sda_sync3;
    
    wire sda = sda_sync3;
    wire scl_posedge = scl_sync3 & ~scl_sync2;
    wire scl_negedge = ~scl_sync3 & scl_sync2;
    
    wire start_cond = sda_sync2 & ~sda_sync3 & scl_sync3;
    wire stop_cond = ~sda_sync2 & sda_sync3 & scl_sync3;
    
    reg addr_match;
    reg rw_bit;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scl_sync1 <= 1'b1;
            scl_sync2 <= 1'b1;
            scl_sync3 <= 1'b1;
            sda_sync1 <= 1'b1;
            sda_sync2 <= 1'b1;
            sda_sync3 <= 1'b1;
        end else begin
            scl_sync1 <= scl_i;
            scl_sync2 <= scl_sync1;
            scl_sync3 <= scl_sync2;
            sda_sync1 <= sda_i;
            sda_sync2 <= sda_sync1;
            sda_sync3 <= sda_sync2;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= STATE_IDLE;
            bit_cnt <= 4'd0;
            shift_reg <= 8'h00;
            reg_addr <= 8'h00;
            sda_out <= 1'b1;
            sda_oen_reg <= 1'b0;
            addr_match <= 1'b0;
            rw_bit <= 1'b0;
            registers[0] <= 8'h00;
            registers[1] <= 8'h00;
            registers[2] <= 8'h00;
            registers[3] <= 8'h00;
        end else begin
            if (start_cond) begin
                state <= STATE_ADDR;
                bit_cnt <= 4'd0;
                shift_reg <= 8'h00;
                sda_oen_reg <= 1'b0;
                addr_match <= 1'b0;
            end else if (stop_cond) begin
                state <= STATE_IDLE;
                sda_oen_reg <= 1'b0;
            end else begin
                case (state)
                    STATE_IDLE: begin
                        sda_oen_reg <= 1'b0;
                    end
                    
                    STATE_ADDR: begin
                        if (scl_posedge) begin
                            shift_reg <= {shift_reg[6:0], sda};
                            if (bit_cnt == 4'd7) begin
                                if (shift_reg[7:1] == SLAVE_ADDR) begin
                                    addr_match <= 1'b1;
                                    rw_bit <= sda;
                                    state <= STATE_ADDR_ACK;
                                end else begin
                                    state <= STATE_IDLE;
                                end
                                bit_cnt <= 4'd0;
                            end else begin
                                bit_cnt <= bit_cnt + 1'b1;
                            end
                        end
                    end
                    
                    STATE_ADDR_ACK: begin
                        if (scl_negedge) begin
                            if (addr_match) begin
                                sda_out <= 1'b0;
                                sda_oen_reg <= 1'b1;
                            end
                        end else if (scl_posedge) begin
                            sda_oen_reg <= 1'b0;
                            if (rw_bit) begin
                                state <= STATE_READ_DATA;
                                shift_reg <= registers[reg_addr[1:0]];
                                bit_cnt <= 4'd0;
                            end else begin
                                state <= STATE_REG_ADDR;
                                bit_cnt <= 4'd0;
                            end
                        end
                    end
                    
                    STATE_REG_ADDR: begin
                        if (scl_posedge) begin
                            shift_reg <= {shift_reg[6:0], sda};
                            if (bit_cnt == 4'd7) begin
                                reg_addr <= {shift_reg[6:0], sda};
                                state <= STATE_REG_ACK;
                                bit_cnt <= 4'd0;
                            end else begin
                                bit_cnt <= bit_cnt + 1'b1;
                            end
                        end
                    end
                    
                    STATE_REG_ACK: begin
                        if (scl_negedge) begin
                            sda_out <= 1'b0;
                            sda_oen_reg <= 1'b1;
                        end else if (scl_posedge) begin
                            sda_oen_reg <= 1'b0;
                            state <= STATE_WRITE_DATA;
                            bit_cnt <= 4'd0;
                        end
                    end
                    
                    STATE_WRITE_DATA: begin
                        if (scl_posedge) begin
                            shift_reg <= {shift_reg[6:0], sda};
                            if (bit_cnt == 4'd7) begin
                                registers[reg_addr[1:0]] <= {shift_reg[6:0], sda};
                                state <= STATE_WRITE_ACK;
                                bit_cnt <= 4'd0;
                            end else begin
                                bit_cnt <= bit_cnt + 1'b1;
                            end
                        end
                    end
                    
                    STATE_WRITE_ACK: begin
                        if (scl_negedge) begin
                            sda_out <= 1'b0;
                            sda_oen_reg <= 1'b1;
                        end else if (scl_posedge) begin
                            sda_oen_reg <= 1'b0;
                            state <= STATE_IDLE;
                        end
                    end
                    
                    STATE_READ_DATA: begin
                        if (scl_negedge) begin
                            sda_out <= shift_reg[7];
                            sda_oen_reg <= 1'b1;
                            shift_reg <= {shift_reg[6:0], 1'b0};
                            if (bit_cnt == 4'd7) begin
                                bit_cnt <= 4'd0;
                            end else begin
                                bit_cnt <= bit_cnt + 1'b1;
                            end
                        end else if (scl_posedge && bit_cnt == 4'd0) begin
                            sda_oen_reg <= 1'b0;
                            state <= STATE_READ_ACK;
                        end
                    end
                    
                    STATE_READ_ACK: begin
                        if (scl_posedge) begin
                            if (sda) begin
                                state <= STATE_IDLE;
                            end else begin
                                state <= STATE_READ_DATA;
                                shift_reg <= registers[reg_addr[1:0]];
                                bit_cnt <= 4'd0;
                            end
                        end
                    end
                    
                    default: begin
                        state <= STATE_IDLE;
                    end
                endcase
            end
        end
    end
    
    assign sda_o = sda_out;
    assign sda_oe = sda_oen_reg;

endmodule

`default_nettype wire
