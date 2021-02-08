//============================================================================
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [45:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output [11:0] VIDEO_ARX,
	output [11:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler

`ifdef USE_FB
	// Use framebuffer in DDRAM (USE_FB=1 in qsf)
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

`ifdef USE_DDRAM
	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
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
`endif

`ifdef USE_SDRAM
	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,
`endif

`ifdef DUAL_SDRAM
	//Secondary SDRAM
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

///////// Default values for ports not used in this core /////////
wire [15:0] kbd_audio;

assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = '0;  

assign VGA_SL = 0;
assign VGA_F1 = 0;
assign VGA_SCALER = 0;

// the CADR does have a 1-bit speaker of no specific frequency (it is CPU controlled)
assign AUDIO_S = 0;
assign AUDIO_L = kbd_audio;
assign AUDIO_R = kbd_audio;
assign AUDIO_MIX = 0;

assign LED_DISK = 0;
assign LED_POWER = 0;
assign BUTTONS = 0;

//////////////////////////////////////////////////////////////////

assign VIDEO_ARX = 12'd5;
assign VIDEO_ARY = 12'd4; 

`include "build_id.v" 
/// TODO make an options/configuration string that makes sense
localparam CONF_STR = {
	"CADR Lisp Machine;;",
	"-;",
	"S0,img,Lisp Machine Disk Image;",
	"O1,Aspect ratio,5:4,5:4;",
	"O2,TV Mode,NTSC,PAL;",
	"O34,Noise,White,Red,Green,Blue;",
	"-;",
	"P1,Test Page 1;",
	"P1-;",
	"P1-, -= Options in page 1 =-;",
	"P1-;",
	"P1O5,Option 1-1,Off,On;",
	"d0P1F1,BIN;",
	"H0P1O6,Option 1-2,Off,On;",
	"-;",
	"P2,Test Page 2;",
	"P2-;",
	"P2-, -= Options in page 2 =-;",
	"P2-;",
	"P2S0,DSK;",
	"P2O67,Option 2,1,2,3,4;",
	"-;",
	"-;",
	"T0,Reset;",
	"R0,Reset and close OSD;",
	"V,v",`BUILD_DATE 
};


//// emulated ps2 keyboard
wire        ps2_kbd_clk_out;
wire        ps2_kbd_data_out;
wire        ps2_kbd_clk_in;
wire        ps2_kbd_data_in;
wire [10:0] ps2_key;

//// emulated ps2 mouse
wire        ps2_mouse_clk_out;
wire        ps2_mouse_data_out;
wire        ps2_mouse_clk_in;
wire        ps2_mouse_data_in;

//// Emulated block device
// info about block device
wire img_mounted;
wire [63:0] img_size;
// 
wire [31:0] sd_lba;
wire sd_rd;
wire sd_wr;
wire sd_ack;
// buffer
wire [7:0] sd_buff_addr;
wire [15:0] sd_buff_dout;
wire [15:0] sd_buff_din;
wire sd_buff_wr;
wire [15:0] sd_req_type;
// config
wire sd_conf;
wire sd_ack_conf;

////
wire forced_scandoubler;
wire  [1:0] buttons;
wire [31:0] status;
wire [10:0] ps2_key;

hps_io #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),
	.EXT_BUS(),
	.gamma_bus(),

	.conf_str(CONF_STR),
	.forced_scandoubler(forced_scandoubler),

	.buttons(buttons),
	.status(status),
	.status_menumask({status[5]}),
	
	.ps2_key(ps2_key),
	.ps2_kbd_clk_out(ps2_kbd_clk_in),
	.ps2_kbd_data_out(ps2_kbd_data_in),
	.ps2_kbd_clk_in(ps2_kbd_clk_out),
	.ps2_kbd_data_in(ps2_kbd_data_out),

	.ps2_mouse_clk_out(ps2_mouse_clk_in),
	.ps2_mouse_data_out(ps2_mouse_data_in),
	.ps2_mouse_clk_in(ps2_mouse_clk_out),
	.ps2_mouse_data_in(ps2_mouse_data_out),
	
	.sd_lba(sd_lba),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack),
	//.sd_conf(sd_conf),
	.sd_ack_conf(sd_ack_conf),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din(sd_buff_din),
	.sd_buff_wr(sd_buff_wr)
);

wire mmc_cs, mmc_di, mmc_do, mmc_sclk;

/////////////////////// SD CARD EMULATION ////////////////////////

sd_card #(.WIDE(1)) sd (
		.clk_sys(clk_sys),
		.reset(reset),
		
		.sdhc(1'b0),
		.sd_lba(sd_lba),
		.sd_rd(sd_rd),
		.sd_wr(sd_wr),
		.sd_ack(sd_ack),
		//.sd_conf(sd_conf),
		.sd_ack_conf(sd_ack_conf),
		.sd_buff_dout(sd_buff_dout),
		.sd_buff_din(sd_buff_din),
		.sd_buff_wr(sd_buff_wr),
		
		.clk_spi(clk_sys),
		.ss(mmc_cs),
		.sck(mmc_sclk),
		.mosi(mmc_do),
		.miso(mmc_di)
);


///////////////////////   CLOCKS   ///////////////////////////////

wire clk_sys;
wire clk_vga;
wire clk_cpu;
pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_sys),
	.outclk_1(clk_vga),
	.outclk_2(clk_cpu)
);

wire reset = RESET | status[0] | buttons[1];

//////////////////////////////////////////////////////////////////

wire [1:0] col = status[4:3];

wire vga_r, vga_g, vga_b, vga_hsync, vga_vsync, vga_blank;

wire ce_pix;
wire [7:0] video;

wire promdisable;

cadr_core cadr
(
	.clk(clk_sys),
	.clk_vga(clk_vga),
	.cpu_clk(clk_cpu),
	.reset(reset),
	
	.pal(status[2]),
	.scandouble(forced_scandoubler),

	/// vga
	.ce_pix(ce_pix),
	.vga_blank			(vga_blank),
	.vga_r			(vga_r),
	.vga_g			(vga_g),
	.vga_b			(vga_b),
	.vga_hsync		(vga_hsync),
	.vga_vsync		(vga_vsync),
	
	/// DDR3
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
	
	/// MMC card
	.mmc_cs(mmc_cs),
	.mmc_sclk(mmc_sclk),
	.mmc_do(mmc_do),
	.mmc_di(mmc_di),
	// ps/2 interface
	.ps2_kbd_clk_out(ps2_kbd_clk_out),
	.ps2_kbd_data_out(ps2_kbd_data_out),
	.ps2_kbd_clk_in(ps2_kbd_clk_in),
	.ps2_kbd_data_in(ps2_kbd_data_in),
	.kbd_audio(kbd_audio),

	.ps2_mouse_clk_out(ps2_mouse_clk_out),
	.ps2_mouse_data_out(ps2_mouse_data_out),
	.ps2_mouse_clk_in(ps2_mouse_clk_in),
	.ps2_mouse_data_in(ps2_mouse_data_in)
);

assign CLK_VIDEO = clk_vga;
assign CE_PIXEL = 1'b1;

assign VGA_DE = ~vga_blank;
assign VGA_HS = vga_hsync;
assign VGA_VS = vga_vsync;
assign VGA_G  = vga_g ? 8'hff : 8'd0;
assign VGA_R  = vga_r ? 8'hff : 8'd0;
assign VGA_B  = vga_b ? 8'hff : 8'd0;

reg  [26:0] act_cnt;
always @(posedge clk_sys) act_cnt <= act_cnt + 1'd1; 

wire active;
assign active = act_cnt[26]  ? act_cnt[25:18]  > act_cnt[7:0]  : act_cnt[25:18]  <= act_cnt[7:0];

assign LED_USER    = ~active && promdisable;

endmodule
