// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.2 (win64) Build 2258646 Thu Jun 14 20:03:12 MDT 2018
// Date        : Sun Dec 15 13:16:34 2024
// Host        : DESKTOP-BB1CHJF running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               C:/Users/Nimsara/Desktop/vga_image/Image_processing_accelerator_final1.xpr/Image_processing_accelerator/Image_processing_accelerator.srcs/sources_1/ip/blk_mem_gen_0/blk_mem_gen_0_stub.v
// Design      : blk_mem_gen_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tcsg324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_1,Vivado 2018.2" *)
module blk_mem_gen_0(clka, wea, addra, dina, douta, clkb, web, addrb, dinb, 
  doutb)
/* synthesis syn_black_box black_box_pad_pin="clka,wea[0:0],addra[19:0],dina[3:0],douta[3:0],clkb,web[0:0],addrb[19:0],dinb[3:0],doutb[3:0]" */;
  input clka;
  input [0:0]wea;
  input [19:0]addra;
  input [3:0]dina;
  output [3:0]douta;
  input clkb;
  input [0:0]web;
  input [19:0]addrb;
  input [3:0]dinb;
  output [3:0]doutb;
endmodule
