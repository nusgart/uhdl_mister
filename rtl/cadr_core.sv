/******************************************************************************* 
 * Engineer: Nicholas Nusgart
 * Design Name: LM-3 CADR implementation
 * Module Name: cadr_core
 * Project Name: LM-3
 * Description: This module is the system-implementation of the LM-3.
					 TODO: possibly get rid of lm3.v
 * Dependencies:  support_cyc2, ram_controller_mister, lm3
 * Revision:
 * Revision 0.01 - File Created
 * Additional Comments: 
******************************************************************************/

`default_nettype none
module cadr_core
(
	input         clk,
	input			  cpu_clk,
	input         clk_vga,
	input         reset,
	
	input         pal,
	input         scandouble,

	//
	output logic promdisable,
	/// VGA video out
	// pixel sampling strobe
	output reg    ce_pix,
	// pixel colors
	output wire vga_r,
	output wire vga_g,
	output wire vga_b,
	// sync signals
	output wire vga_hsync,
	output wire vga_vsync,
	// is the "beam" on-screen
	output wire vga_blank,
	
	/// MMC interface
	output wire mmc_cs, 
	input wire mmc_di,
	output wire mmc_do,
	output wire mmc_sclk,
	
	/// DDR memory interface
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,
	
	// Keyboard and Mouse
	output wire        ps2_kbd_clk_out,
	output wire        ps2_kbd_data_out,
	input wire        ps2_kbd_clk_in,
	input wire        ps2_kbd_data_in,
	output [15:0]		kbd_audio,
	
	// emulated ps2 mouse
	output wire        ps2_mouse_clk_out,
	output wire        ps2_mouse_data_out,
	input wire        ps2_mouse_clk_in,
	input wire        ps2_mouse_data_in
);

	reg [3:0] clkcnt;
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire			boot;			// From support of support_lx45.v
   wire [15:0]		busint_spyout;		// From lm3 of lm3.v
   wire			dcm_reset;		// From support of support_lx45.v
   wire [4:0]		disk_state;		// From lm3 of lm3.v
   wire			halt;			// From support of support_lx45.v
   wire			interrupt;		// From support of support_lx45.v
   wire			lpddr_calib_done;	// From rc of ram_controller_lx45.v
   wire			lpddr_reset;		// From support of support_lx45.v
   wire [13:0]		mcr_addr;		// From lm3 of lm3.v
   wire [48:0]		mcr_data_out;		// From lm3 of lm3.v
	wire [48:0]    mcr_data_in;   // From lm3 of lm3.v
   wire			mcr_done;		// From rc of ram_controller_lx45.v
   wire			mcr_ready;		// From rc of ram_controller_lx45.v
   wire			mcr_write;		// From lm3 of lm3.v
   wire [21:0]		sdram_addr;		// From lm3 of lm3.v
   wire [31:0]		sdram_data_cpu2rc;	// From lm3 of lm3.v
	wire [31:0]    sdram_data_rc2cpu; // From lm3 of lm3.v
   wire			sdram_done;		// From rc of ram_controller_lx45.v
   wire			sdram_ready;		// From rc of ram_controller_lx45.v
   wire			sdram_req;		// From lm3 of lm3.v
   wire			sdram_write;		// From lm3 of lm3.v
   wire			spy_rd;			// From lm3 of lm3.v
   wire [3:0]		spy_reg;		// From lm3 of lm3.v
   wire			spy_wr;			// From lm3 of lm3.v
   wire [14:0]		vram_cpu_addr;		// From lm3 of lm3.v
   wire [31:0]		vram_cpu_data_out;	// From lm3 of lm3.v
   wire			vram_cpu_done;		// From rc of ram_controller_lx45.v
   wire			vram_cpu_ready;		// From rc of ram_controller_lx45.v
   wire			vram_cpu_req;		// From lm3 of lm3.v
   wire			vram_cpu_write;		// From lm3 of lm3.v
   wire [14:0]		vram_vga_addr;		// From lm3 of lm3.v
   wire [31:0]		vram_vga_data_out;	// From rc of ram_controller_lx45.v
	wire [31:0]    vram_cpu_data_in; // From rc of ram_controller_lx45.v
   wire			vram_vga_ready;		// From rc of ram_controller_lx45.v
   wire			vram_vga_req;		// From lm3 of lm3.v
   // End of automatics
   
   ////////////////////////////////////////////////////////////////////////////////
	
	wire clk50;
	
	wire rs232_txd, rs232_rxd;
	assign clk50 = clk;
	wire sup_reset;
	
   support_mister support
     (
      .sysclk(clk50),
      .button_r(reset),
      .button_b(1'b0),
      .button_h(1'b0),
      .button_c(1'b0),
      /*AUTOINST*/
      // Outputs
      .boot				(boot),
      .dcm_reset			(dcm_reset),
      .halt				(halt),
      .interrupt			(interrupt),
      .reset				(sup_reset),
      // Inputs
      .cpu_clk				(cpu_clk),
      .lpddr_calib_done			(~reset));
   
   ram_controller_mister rc
     (
      .clk(clk50),
      .mcr_data_out(mcr_data_in),
      .mcr_data_in(mcr_data_out),
      .sdram_data_in(sdram_data_cpu2rc),
      .sdram_data_out(sdram_data_rc2cpu),
      .vram_cpu_data_in(vram_cpu_data_out),
      .vram_cpu_data_out(vram_cpu_data_in),
		
      //
		.DDRAM_CLK(DDRAM_CLK),
		.DDRAM_ADDR(DDRAM_ADDR),
		.DDRAM_BURSTCNT(DDRAM_BURSTCNT),
		.DDRAM_BUSY(DDRAM_BUSY),
		.DDRAM_DOUT(DDRAM_DOUT),
		.DDRAM_DOUT_READY(DDRAM_DOUT_READY),
		.DDRAM_RD(DDRAM_RD),
		.DDRAM_DIN(DDRAM_DIN),
		.DDRAM_BE(DDRAM_BE),
		.DDRAM_WE(DDRAM_WE),
		
      // Outputs
      .vram_vga_data_out		(vram_vga_data_out[31:0]),
      .mcr_done				(mcr_done),
      .mcr_ready			(mcr_ready),
      .sdram_done			(sdram_done),
      .sdram_ready			(sdram_ready),
      .vram_cpu_done			(vram_cpu_done),
      .vram_cpu_ready			(vram_cpu_ready),
      .vram_vga_ready			(vram_vga_ready),
      // Inouts
      // Inputs
      .mcr_addr				(mcr_addr[13:0]),
      .vram_cpu_addr			(vram_cpu_addr[14:0]),
      .vram_vga_addr			(vram_vga_addr[14:0]),
      .sdram_addr			(sdram_addr[21:0]),
      .cpu_clk				(cpu_clk),
      .mcr_write			(mcr_write),
      .reset				(reset),
      .sdram_req			(sdram_req),
      .sdram_write			(sdram_write),
      .vga_clk				(clk_vga),
      .vram_cpu_req			(vram_cpu_req),
      .vram_cpu_write			(vram_cpu_write),
      .vram_vga_req			(vram_vga_req));
   
   lm3 lm3(/*AUTOINST*/
	   // Outputs
	   .sdram_addr			(sdram_addr[21:0]),
	   .sdram_data_cpu2rc		(sdram_data_cpu2rc[31:0]),
	   .sdram_req			(sdram_req),
	   .sdram_write			(sdram_write),
	   .vram_cpu_addr		(vram_cpu_addr[14:0]),
	   .vram_cpu_data_out		(vram_cpu_data_out[31:0]),
	   .vram_cpu_req		(vram_cpu_req),
	   .vram_cpu_write		(vram_cpu_write),
	   .spy_reg			(spy_reg[3:0]),
	   .busint_spyout		(busint_spyout[15:0]),
	   .spy_rd			(spy_rd),
	   .spy_wr			(spy_wr),
	   .disk_state			(disk_state[4:0]),
	   .mcr_addr			(mcr_addr[13:0]),
	   .mcr_data_out		(mcr_data_out[48:0]),
	   .mcr_write			(mcr_write),
	   .mmc_cs			(mmc_cs),
	   .mmc_do			(mmc_do),
	   .mmc_sclk			(mmc_sclk),
	   .vram_vga_addr		(vram_vga_addr[14:0]),
	   .vram_vga_req		(vram_vga_req),
	   .vga_blank			(vga_blank),
	   .vga_r			(vga_r),
	   .vga_g			(vga_g),
	   .vga_b			(vga_b),
	   .vga_hsync		(vga_hsync),
	   .vga_vsync		(vga_vsync),
		.rs232_txd			(rs232_txd),
		.o_audio(kbd_audio),
		.promdisable(promdisable),
	   // Inouts
	   .ps2_mouse_clk_in		(ps2_mouse_clk_in),
	   .ps2_mouse_data_in	(ps2_mouse_data_in),
		.ps2_mouse_clk_out	(ps2_mouse_clk_out),
	   .ps2_mouse_data_out	(ps2_mouse_data_out),
	   // Inputs
	   .clk50			(clk50),
	   .reset			(reset),
	   .sdram_data_rc2cpu		(sdram_data_rc2cpu[31:0]),
	   .sdram_done			(sdram_done),
	   .sdram_ready			(sdram_ready),
	   .vram_cpu_data_in		(vram_cpu_data_in[31:0]),
	   .vram_cpu_done		(vram_cpu_done),
	   .vram_cpu_ready		(vram_cpu_ready),
	   .cpu_clk			(cpu_clk),
	   .boot			(boot),
	   .halt			(halt),
	   .interrupt			(interrupt),
	   .mcr_data_in			(mcr_data_in[48:0]),
	   .mcr_ready			(mcr_ready),
	   .mcr_done			(mcr_done),
	   .mmc_di			(mmc_di),
	   .vram_vga_data_out		(vram_vga_data_out[31:0]),
	   .vram_vga_ready		(vram_vga_ready),
	   .vga_clk			(clk_vga),
	   .kb_ps2_clk			(ps2_kbd_clk_in),
	   .kb_ps2_data			(ps2_kbd_data_in),
	   .rs232_rxd			(rs232_rxd));
   /*
   assign led[3] = 1'b0;
   assign led[2] = disk_state[1];
   assign led[1] = disk_state[2];
   assign led[0] = reset;
*/


/*
/////////////////////////// ORIGINAL STUFF
reg   [9:0] hc;
reg   [9:0] vc;
reg   [9:0] vvc;
reg  [63:0] rnd_reg;

wire  [5:0] rnd_c = {rnd_reg[0],rnd_reg[1],rnd_reg[2],rnd_reg[2],rnd_reg[2],rnd_reg[2]};
wire [63:0] rnd;

lfsr random(rnd);

always @(posedge clk) begin
	if(scandouble) ce_pix <= 1;
		else ce_pix <= ~ce_pix;

	if(reset) begin
		hc <= 0;
		vc <= 0;
	end
	else if(ce_pix) begin
		if(hc == 637) begin
			hc <= 0;
			if(vc == (pal ? (scandouble ? 623 : 311) : (scandouble ? 523 : 261))) begin 
				vc <= 0;
				vvc <= vvc + 9'd6;
			end else begin
				vc <= vc + 1'd1;
			end
		end else begin
			hc <= hc + 1'd1;
		end

		rnd_reg <= rnd;
	end
end

always @(posedge clk) begin
	if (hc == 529) HBlank <= 1;
		else if (hc == 0) HBlank <= 0;

	if (hc == 544) begin
		HSync <= 1;

		if(pal) begin
			if(vc == (scandouble ? 609 : 304)) VSync <= 1;
				else if (vc == (scandouble ? 617 : 308)) VSync <= 0;

			if(vc == (scandouble ? 601 : 300)) VBlank <= 1;
				else if (vc == 0) VBlank <= 0;
		end
		else begin
			if(vc == (scandouble ? 490 : 245)) VSync <= 1;
				else if (vc == (scandouble ? 496 : 248)) VSync <= 0;

			if(vc == (scandouble ? 480 : 240)) VBlank <= 1;
				else if (vc == 0) VBlank <= 0;
		end
	end
	
	if (hc == 590) HSync <= 0;
end

reg  [7:0] cos_out;
wire [5:0] cos_g = cos_out[7:3]+6'd32;
cos cos(vvc + {vc>>scandouble, 2'b00}, cos_out);

assign video = (cos_g >= rnd_c) ? {cos_g - rnd_c, 2'b00} : 8'd0;
*/
endmodule
`default_nettype wire