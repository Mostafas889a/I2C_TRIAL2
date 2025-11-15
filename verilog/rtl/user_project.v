`default_nettype none

`define USE_USER_VIP



`define USER_VIP \
    wire i2c_scl_o = gpio5_monitor; \
    wire i2c_sda_o = gpio6_monitor; \
    tri1  sda_pin = ~i2c_sda_o ? 1'b0 : 1'bz; \
    tri1  scl_pin = ~i2c_scl_o ? 1'b0 : 1'bz; \
    assign  gpio5_en = 1'b1; \
    assign  gpio6_en = 1'b1; \
    assign  gpio5 = scl_pin; \
    assign  gpio6 = sda_pin; \
    M24AA64 slave(.A0(1), .A1(0), .A1(1), .WP(0), .SDA(sda_pin), .SCL(scl_pin), .RESET(resetb_tb));


module user_project (
`ifdef USE_POWER_PINS
    inout vccd1,
    inout vssd1,
`endif
    input wb_clk_i,
    input wb_rst_i,

    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    input [127:0] la_data_in,
    output [127:0] la_data_out,
    input [127:0] la_oenb,

    input [37:0] io_in,
    output [37:0] io_out,
    output [37:0] io_oeb,

    output [2:0] user_irq
);

    wire scl_i;
    wire scl_o;
    wire scl_oen;
    wire sda_i;
    wire sda_o;
    wire sda_oen;
    wire i2c_irq;

    CF_I2C_WB #(
        .DEFAULT_PRESCALE(1),
        .FIXED_PRESCALE(0),
        .CMD_FIFO(1),
        .CMD_FIFO_DEPTH(16),
        .WRITE_FIFO(1),
        .WRITE_FIFO_DEPTH(16),
        .READ_FIFO(1),
        .READ_FIFO_DEPTH(16)
    ) i2c_master (
        .clk_i(wb_clk_i),
        .rst_i(wb_rst_i),
        .adr_i(wbs_adr_i),
        .dat_i(wbs_dat_i),
        .dat_o(wbs_dat_o),
        .sel_i(wbs_sel_i),
        .cyc_i(wbs_cyc_i),
        .stb_i(wbs_stb_i),
        .ack_o(wbs_ack_o),
        .we_i(wbs_we_i),
        .IRQ(i2c_irq),

        .scl_i(scl_i),
        .scl_o(scl_o),
        .scl_oen_o(scl_oen),
        .sda_i(sda_i),
        .sda_o(sda_o),
        .sda_oen_o(sda_oen)
    );

    assign scl_i = io_in[5];
    assign io_out[5] = scl_o;
    assign io_oeb[5] = ~scl_oen;

    assign sda_i = io_in[6];
    assign io_out[6] = sda_o;
    assign io_oeb[6] = ~sda_oen;

    assign io_out[37:7] = 31'b0;
    assign io_out[4:0] = 5'b0;
    assign io_oeb[37:7] = 31'b1;
    assign io_oeb[4:0] = 5'b1;

    assign user_irq[0] = i2c_irq;
    assign user_irq[2:1] = 2'b0;

    assign la_data_out = 128'b0;

endmodule

`default_nettype wire
