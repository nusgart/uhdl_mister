// VCTL2 --- VMA/MD CONTROL
//
// ---!!! Add description.
//
// History:
//
//   (20YY-MM-DD HH:mm:ss BRAD) Converted to Verilog.
//	???: Nets added.
//	???: Nets removed.
//   (1978-08-16 06:38:11 TK) Initial.

`timescale 1ns/1ps
`default_nettype none

module VCTL2(/*AUTOARG*/
   // Outputs
   mdsel, memdrive, memrd, memwr, vm0rp, vm0wp, vm1rp, vm1wp, vmaenb,
   vmasel, wmap,
   // Inputs
   state_decode, state_mmu, state_read, state_write, vma, ir, destmdr,
   destmem, destvma, dispwr, dmapbenb, ifetch, irdisp, loadmd,
   memprepare, memstart, nopa, srcmap, srcmd, wrcyc
   );

   input state_decode;
   input state_mmu;
   input state_read;
   input state_write;

   input [31:0] vma;
   input [48:0] ir;
   input destmdr;
   input destmem;
   input destvma;
   input dispwr;
   input dmapbenb;
   input ifetch;
   input irdisp;
   input loadmd;
   input memprepare;
   input memstart;
   input nopa;
   input srcmap;
   input srcmd;
   input wrcyc;
   output mdsel;
   output memdrive;
   output memrd;
   output memwr;
   output vm0rp;
   output vm0wp;
   output vm1rp;
   output vm1wp;
   output vmaenb;
   output vmasel;
   output wmap;

   ////////////////////////////////////////////////////////////////////////////////

   wire early_vm0_rd;
   wire early_vm1_rd;
   wire normal_vm0_rd;
   wire normal_vm1_rd;
   wire use_md;
   wire mapwr0;
   wire mapwr1;
   wire lm_drive_enb;

   ////////////////////////////////////////////////////////////////////////////////

   assign mapwr0 = wmap & vma[26];
   assign mapwr1 = wmap & vma[25];
   assign early_vm0_rd = (irdisp && dmapbenb) | srcmap;
   assign early_vm1_rd = (irdisp && dmapbenb) | srcmap;
   assign normal_vm0_rd = wmap;
   assign normal_vm1_rd = 1'b0;
   assign vm0rp = (state_decode && early_vm0_rd) | (state_write && normal_vm0_rd) | (state_write && memprepare);
   assign vm1rp = (state_read && early_vm1_rd) | (state_mmu && normal_vm1_rd) | (state_mmu && memstart);
   assign vm0wp = mapwr0 & state_write;
   assign vm1wp = mapwr1 & state_mmu;
   assign vmaenb = destvma | ifetch;
   assign vmasel = ~ifetch;
   assign lm_drive_enb = 0;
   assign memdrive = wrcyc & lm_drive_enb;
   assign mdsel = destmdr & ~loadmd;
   assign use_md = srcmd & ~nopa;
   assign {wmap, memwr, memrd}
     = ~destmem ? 3'b000 :
       (ir[20:19] == 2'b01) ? 3'b001 :
       (ir[20:19] == 2'b10) ? 3'b010 :
       (ir[20:19] == 2'b11) ? 3'b100 :
       3'b000 ;

endmodule

`default_nettype wire

// Local Variables:
// verilog-library-directories: ("..")
// End:
