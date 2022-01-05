/******************************************************************************* 
 * Engineer: Nicholas Nusgart
 * Design Name: LM-3 CADR implementation
 * Module Name: ram_controller_mister
 * Project Name: LM-3
 * Description: This module is acts as the memory controller for the LM-3.  It
                acts as the interface from the LM-3 sdram bus to the MiSTer's
					 DDR3 and from the LM-3 vram bus to the VRAM (implemented as
					 block ram).  
 * Dependencies:  alt_vram
 * Revision:
 * Revision 0.01 - File Created
 * Additional Comments: 
******************************************************************************/

`timescale 1ns/1ps
//`default_nettype none

module ram_controller_mister (
	// system interface
	input logic clk,
   input logic cpu_clk,
   input logic vga_clk,
   input logic reset,
	
	// DDR interface
	// this isn't made explicit, but this is just an Avalon-MM master
	output logic        DDRAM_CLK,
	input  logic        DDRAM_BUSY, // waitrequest
	output logic [7:0]  DDRAM_BURSTCNT,
	output logic [28:0] DDRAM_ADDR,
	input  logic [63:0] DDRAM_DOUT,
	input  logic        DDRAM_DOUT_READY,
	output logic        DDRAM_RD,
	output logic [63:0] DDRAM_DIN,
	output logic [7:0]  DDRAM_BE,
	output logic        DDRAM_WE,
	
   //// CADR xbus_sdram interface
	input wire [21:0] sdram_addr,
   input wire [31:0] sdram_data_in,
	output [31:0] sdram_data_out,
	input wire sdram_req,
   input wire sdram_write,
	// is the write previously requested finished
	output reg sdram_done,
	// is the data from the read ready
   output reg sdram_ready,
	
	
	// CADR microcode interface
   input wire [13:0] mcr_addr,
	input wire [48:0] mcr_data_in,
	output [48:0] mcr_data_out,
	input  logic mcr_write,
	output logic mcr_done,
   output logic mcr_ready,
	
	// CADR & VGA VRAM interface
   input  logic [14:0] vram_cpu_addr,
	input  logic [31:0] vram_cpu_data_in,
	output logic [31:0] vram_cpu_data_out,
	input  logic        vram_cpu_req,
   input  logic        vram_cpu_write,
	output logic        vram_cpu_done,
   output logic        vram_cpu_ready,
	
	input  logic [14:0] vram_vga_addr,
   output logic [31:0] vram_vga_data_out,
   input  logic        vram_vga_req,
   output logic        vram_vga_ready
   );

	
	////// SDRAM support -- this probably needs work.  Probably doesn't meet xbus requirements
	////// -- specifically, it might not take enough clock cycles.
	// TODO since there is a large amount of free block ram, implement a 64 KW cache (256 KB).
	// I think using a direct mapped cache would be fine here since the cachable portion of the
	// address space is only 3.75 MW, so that's only 60 addresses mapping to 1 cache line.
	
	typedef enum logic [3:0] {
	  RST,
	  IDLE,
	  WRITE,
	  WRITE_BUSY,
	  WRITE_WAIT,
	  READ,
	  READ_BUSY,
	  READ_WAIT
	} State;
		
	State state;
	logic i_sdram_rdone;
	logic i_sdram_wdone;
	logic [21:0] i_sdram_addr;
	logic [31:0] i_sdram_wdata;
	logic [31:0] i_sdram_rdata;
	
	// DDRAM control
	always_comb begin
		DDRAM_CLK = clk;
		DDRAM_BURSTCNT = 1;
		DDRAM_BE = 8'hff;
		/// put ram at 0x3000_0000 --> other cores do this, probably to avoid overwriting important things
		DDRAM_ADDR = {7'b0011_000, i_sdram_addr};
		DDRAM_DIN = i_sdram_wdata;
		DDRAM_RD = (state == READ);
		DDRAM_WE = (state == WRITE);
	end
	
	
	// xbus_sdram interface
	always_ff @(posedge cpu_clk) begin
		sdram_ready <= i_sdram_rdone && sdram_req;
		sdram_done <= i_sdram_wdone && sdram_write;
	end
	assign sdram_data_out = i_sdram_rdata;
		
	// core DDR SDRAM state machine
	always_ff @(posedge clk) begin
		if (reset) begin
			state <= IDLE;
			i_sdram_rdone <= 0;
			i_sdram_wdone <= 0;
			i_sdram_addr <= 0;
			i_sdram_wdata <= 0;
			i_sdram_rdata <= 32'hffff_ffff;
		end else begin
			case (state)
				// idle state
				IDLE: begin
					if (DDRAM_BUSY) begin
						// if there is a refresh going on, can't do anything
						state <= IDLE;
					end else if (sdram_req) begin
						// start read
						state <= READ;
						i_sdram_addr <= sdram_addr;
						i_sdram_rdone <= 1'b0;
					end else if (sdram_write) begin
						// start write
						state <= WRITE;
						i_sdram_wdata <= sdram_data_in;
						i_sdram_addr <= sdram_addr;
						i_sdram_wdone <= 1'b0;
					end
				end
				// write states
				WRITE: begin
					i_sdram_wdone <= 1'b0;
					
					/*
					 * this was based on a bad model of how the DDR controller worked
					 * the DDR interface is actually an Avalon-MM master
					 * This will be deleted soon, but I want this comment to be in the
					 * git history
					 * // wait for write to start
					 * //if (DDRAM_BUSY) state <= WRITE_BUSY;
					 */
					state <= WRITE_BUSY;
				end
				WRITE_BUSY: begin
					// this state only exists to slow things down (I think Xbus might have problems with
					// peripherals responding too quickly???)
					state <= WRITE_WAIT;
				end
				WRITE_WAIT: begin
					// notify xbus that the write is complete
					i_sdram_wdone <= 1'b1;
					// once xbus stops requesting a write, return to idle
					// note that this is correct behavior because xbus doesn't support bursts.
					if (~sdram_write) state <= IDLE;
				end
				// read states
				READ: begin
					i_sdram_rdone <= 1'b0;
					
					// wait for read to start
					//if (DDRAM_BUSY) state <= READ_BUSY;
					state <= READ_BUSY;
				end
				READ_BUSY: begin
					// wait for DDRAM to complete the read
					if (DDRAM_DOUT_READY) begin
						state <= READ_WAIT;
						i_sdram_rdata <= DDRAM_DOUT[31:0];
					end
				end
				READ_WAIT: begin
					// notify xbus that the read is complete
					i_sdram_rdone <= 1'b1;
					// once xbus stops requesting a read, return to idle
					// note that this is correct behavior because xbus doesn't support bursts
					if (~sdram_req) state <= IDLE;
				end
			endcase
		end
	end
	

   ////////////////////////////////////////////////////////////////////////////////
   logic [31:0] vram_vga_data;
   logic [3:0]  vram_vga_ready_dly;
	logic [31:0] vram_vga_ram_out;
	
	logic [31:0] vram_cpu_data;
	logic [3:0]  vram_cpu_ready_dly;
	logic [31:0] vram_cpu_ram_out;

	alt_vram inst (
		.address_a(vram_cpu_addr),
		.address_b(vram_vga_addr),
		.clock_a(cpu_clk),
		.clock_b(vga_clk),
		.data_a(vram_cpu_data_in),
		.data_b(32'b0),
		.wren_a(vram_cpu_write),
		.wren_b(1'b0),
		.q_a(vram_cpu_ram_out),
		.q_b(vram_vga_ram_out)
	);
	
	//
   assign vram_vga_data_out = vram_vga_ready ? vram_vga_ram_out : vram_vga_data;

	always_ff @(posedge vga_clk) begin
		if (reset) begin
			vram_vga_data <= 32'h0;
		end else if (vram_vga_ready) begin
			vram_vga_data <= vram_vga_ram_out;
		end
	end
	
	
	always_ff @(posedge vga_clk) begin
		if (reset) begin
			vram_vga_ready_dly <= 4'h0;
		end else begin
			vram_vga_ready_dly <= { vram_vga_ready_dly[2:0], vram_vga_req };
		end
	end

   assign vram_vga_ready = vram_vga_ready_dly[0];
   assign vram_cpu_done = 1'b1;

	always_ff @(posedge cpu_clk) begin
		if (reset) begin
			vram_cpu_ready_dly <= 4'h0;
		end else begin
			vram_cpu_ready_dly <= { vram_cpu_ready_dly[2:0], vram_cpu_req };
		end
	end
	
	
	always_ff @(posedge cpu_clk) begin
		if (reset) begin
			vram_cpu_data <= 32'h0;
		end else if (~vram_cpu_ready_dly[1] & vram_cpu_ready_dly[0]) begin
			// assign at start of request
			vram_cpu_data <= vram_cpu_ram_out;
		end
	end
	assign vram_cpu_data_out = vram_cpu_ram_out;//vram_cpu_data;
   assign vram_cpu_ready = vram_cpu_ready_dly[3];

`ifndef EXTERNAL_MCR
   assign mcr_data_out = 0;
   assign mcr_ready = 0;
   assign mcr_done = 0;
`else
	//TODO
`endif

endmodule
//`default_nettype wire