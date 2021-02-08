// 
// sd_card.v
//
// Copyright (c) 2014 Till Harbaum <till@harbaum.org>
// Copyright (c) 2015-2018 Sorgelig
//
// This source file is free software: you can redistribute it and/or modify
// it under the terms of the Lesser GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This source file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
// http://elm-chan.org/docs/mmc/mmc_e.html
//
/////////////////////////////////////////////////////////////////////////
`default_nettype none

module sdbuf #(parameter WIDE)
(
	input             clock_a,
	input      [AW:0] address_a,
	input      [DW:0] data_a, 
	input             wren_a,
	output reg [DW:0] q_a,

	input             clock_b,
	input       [8:0] address_b,
	input       [7:0] data_b, 
	input             wren_b,
	output reg  [7:0] q_b
);

localparam AW = WIDE ?  7 : 8;
localparam DW = WIDE ? 15 : 7;

always@(posedge clock_a) begin
	if(wren_a) begin
		ram[address_a] <= data_a;
		q_a <= data_a;
	end
	else begin
		q_a <= ram[address_a];
	end
end

generate
	if(WIDE) begin
		reg [1:0][7:0] ram[1<<8];
		always@(posedge clock_b) begin
			if(wren_b) begin
				ram[address_b[8:1]][address_b[0]] <= data_b;
				q_b <= data_b;
			end
			else begin
				q_b <= ram[address_b[8:1]][address_b[0]];
			end
		end
	end
	else begin
		reg [7:0] ram[1<<9];
		always@(posedge clock_b) begin
			if(wren_b) begin
				ram[address_b] <= data_b;
				q_b <= data_b;
			end
			else begin
				q_b <= ram[address_b];
			end
		end
	end
endgenerate

endmodule
`default_nettype wire
