//////////////////////////////////////////////////////////////////////
////                                                              ////
////  spi_top.v                                                   ////
////                                                              ////
////  This file is part of the SPI IP core project                ////
////  http://www.opencores.org/projects/spi/                      ////
////                                                              ////
////  Author(s):                                                  ////
////      - Simon Srot (simons@opencores.org)                     ////
////                                                              ////
////  All additional information is avaliable in the Readme.txt   ////
////  file.                                                       ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2002 Authors                                   ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////


`include "timescale.vh"

//
// Number of bits used for devider register. If used in system with
// low frequency of system clock this can be reduced.
// Use SPI_DIVIDER_LEN for fine tuning theexact number.
//
//`define SPI_DIVIDER_LEN_8
`define SPI_DIVIDER_LEN_16
//`define SPI_DIVIDER_LEN_24
//`define SPI_DIVIDER_LEN_32


//
// Maximum nuber of bits that can be send/received at once. 
// Use SPI_MAX_CHAR for fine tuning the exact number, when using
// SPI_MAX_CHAR_32, SPI_MAX_CHAR_24, SPI_MAX_CHAR_16, SPI_MAX_CHAR_8.
//
`define SPI_MAX_CHAR_128
//`define SPI_MAX_CHAR_64
//`define SPI_MAX_CHAR_32
//`define SPI_MAX_CHAR_24
//`define SPI_MAX_CHAR_16
//`define SPI_MAX_CHAR_8

//
// Number of device select signals. Use SPI_SS_NB for fine tuning the 
// exact number.
//
`define SPI_SS_NB_1
//`define SPI_SS_NB_8
//`define SPI_SS_NB_16
//`define SPI_SS_NB_24
//`define SPI_SS_NB_32

module spi_top
  (
    // Wishbone signals
    wb_clk_i, wb_rst_i, wb_adr_i, wb_dat_i, wb_dat_o, wb_sel_i,
    wb_we_i, wb_stb_i, wb_cyc_i, wb_ack_o, wb_err_o, wb_int_o,

    // SPI signals
    ss_pad_o, sclk_pad_o, mosi_pad_o, miso_pad_i, card_detect_i
  );

  parameter Tp = 1;



  // Wishbone signals
  input                            wb_clk_i;         // master clock input
  input                            wb_rst_i;         // synchronous active high reset
  input                      [4:0] wb_adr_i;         // lower address bits
  input                   [32-1:0] wb_dat_i;         // databus input
  output                  [32-1:0] wb_dat_o;         // databus output
  input                      [3:0] wb_sel_i;         // byte select inputs
  input                            wb_we_i;          // write enable input
  input                            wb_stb_i;         // stobe/core select signal
  input                            wb_cyc_i;         // valid bus cycle input
  output                           wb_ack_o;         // bus cycle acknowledge output
  output                           wb_err_o;         // termination w/ error
  output                           wb_int_o;         // interrupt request signal output

  // SPI signals                                     
  output                  [32-1:0] ss_pad_o;         // slave select
  output                           sclk_pad_o;       // serial clock
  output                           mosi_pad_o;       // master out slave in
  input                            miso_pad_i;       // master in slave out
  input                            card_detect_i;     // Card detection

  reg                     [32-1:0] wb_dat_o;
  reg                              wb_ack_o;
  reg                              wb_int_o;

  //
  // Bits of WISHBONE address used for partial decoding of SPI registers.
  //
  localparam SPI_OFS_BITS_MSB = 4;
  localparam SPI_OFS_BITS_LSB = 2;

  //
  // Register offset
  //
  localparam SPI_RX_0    = 0;
  localparam SPI_RX_1    = 1;
  localparam SPI_RX_2    = 2;
  localparam SPI_RX_3    = 3;
  localparam SPI_TX_0    = 0;
  localparam SPI_TX_1    = 1;
  localparam SPI_TX_2    = 2;
  localparam SPI_TX_3    = 3;
  localparam SPI_CTRL    = 4;
  localparam SPI_DEVIDE  = 5;
  localparam SPI_SS      = 6;

  //
  // Number of bits in ctrl register
  //
  localparam SPI_CTRL_BIT_NB = 14;

  //
  // Control register bit position
  //
  localparam SPI_CARD_PRESENT        = 15;
  localparam SPI_CARD_REMOVED        = 14;
  localparam SPI_CTRL_ASS            = 13;
  localparam SPI_CTRL_IE             = 12;
  localparam SPI_CTRL_LSB            = 11;
  localparam SPI_CTRL_TX_NEGEDGE     = 10;
  localparam SPI_CTRL_RX_NEGEDGE     = 9;
  localparam SPI_CTRL_GO             = 8;
  localparam SPI_CTRL_RES_1          = 7;
  localparam SPI_CTRL_CHAR_LEN_MSB   = 6;
  localparam SPI_CTRL_CHAR_LEN_LSB   = 0;



`ifdef SPI_MAX_CHAR_128
      localparam SPI_CHAR_LEN_BITS = 7;
      localparam SPI_MAX_CHAR = 128;
      localparam SPI_MAX_CHAR_128 = 1;
      localparam SPI_MAX_CHAR_64 = 0;
      localparam SPI_MAX_CHAR_32 = 0;
      localparam SPI_MAX_CHAR_24 = 0;
      localparam SPI_MAX_CHAR_16 = 0;
      localparam SPI_MAX_CHAR_8 = 0;
`endif
`ifdef SPI_MAX_CHAR_64
      localparam SPI_CHAR_LEN_BITS = 6;
      localparam SPI_MAX_CHAR = 64;
      localparam SPI_MAX_CHAR_128 = 0;
      localparam SPI_MAX_CHAR_64 = 1;
      localparam SPI_MAX_CHAR_32 = 0;
      localparam SPI_MAX_CHAR_24 = 0;
      localparam SPI_MAX_CHAR_16 = 0;
      localparam SPI_MAX_CHAR_8 = 0;
`endif
`ifdef SPI_MAX_CHAR_32
      localparam SPI_CHAR_LEN_BITS = 5;
      localparam SPI_MAX_CHAR = 32;
      localparam SPI_MAX_CHAR_128 = 0;
      localparam SPI_MAX_CHAR_64 = 0;
      localparam SPI_MAX_CHAR_32 = 1;
      localparam SPI_MAX_CHAR_24 = 0;
      localparam SPI_MAX_CHAR_16 = 0;
      localparam SPI_MAX_CHAR_8 = 0;
`endif
`ifdef SPI_MAX_CHAR_24
      localparam SPI_CHAR_LEN_BITS = 5;
      localparam SPI_MAX_CHAR = 24;
      localparam SPI_MAX_CHAR_128 = 0;
      localparam SPI_MAX_CHAR_64 = 0;
      localparam SPI_MAX_CHAR_32 = 0;
      localparam SPI_MAX_CHAR_24 = 1;
      localparam SPI_MAX_CHAR_16 = 0;
      localparam SPI_MAX_CHAR_8 = 0;
`endif
`ifdef SPI_MAX_CHAR_16
      localparam SPI_CHAR_LEN_BITS = 4;
      localparam SPI_MAX_CHAR = 16;
      localparam SPI_MAX_CHAR_128 = 0;
      localparam SPI_MAX_CHAR_64 = 0;
      localparam SPI_MAX_CHAR_32 = 0;
      localparam SPI_MAX_CHAR_24 = 0;
      localparam SPI_MAX_CHAR_16 = 1;
      localparam SPI_MAX_CHAR_8 = 0;
`endif
`ifdef SPI_MAX_CHAR_8
      localparam SPI_CHAR_LEN_BITS = 3;
      localparam SPI_MAX_CHAR = 8;
      localparam SPI_MAX_CHAR_128 = 0;
      localparam SPI_MAX_CHAR_64 = 0;
      localparam SPI_MAX_CHAR_32 = 0;
      localparam SPI_MAX_CHAR_24 = 0;
      localparam SPI_MAX_CHAR_16 = 0;
      localparam SPI_MAX_CHAR_8 = 1;
`endif

`ifdef SPI_DIVIDER_LEN_32
      localparam SPI_DIVIDER_LEN = 32;
      localparam SPI_DIVIDER_LEN_8 = 0;
      localparam SPI_DIVIDER_LEN_16 = 0;
      localparam SPI_DIVIDER_LEN_24 = 0;
      localparam SPI_DIVIDER_LEN_32 = 1;
`endif                                                          
`ifdef SPI_DIVIDER_LEN_24     
      localparam SPI_DIVIDER_LEN = 24;
      localparam SPI_DIVIDER_LEN_8 = 0;
      localparam SPI_DIVIDER_LEN_16 = 0;
      localparam SPI_DIVIDER_LEN_24 = 1;
      localparam SPI_DIVIDER_LEN_32 = 0;
`endif                                                          
`ifdef SPI_DIVIDER_LEN_16 
      localparam SPI_DIVIDER_LEN = 16;
      localparam SPI_DIVIDER_LEN_8 = 0;
      localparam SPI_DIVIDER_LEN_16 = 1;
      localparam SPI_DIVIDER_LEN_24 = 0;
      localparam SPI_DIVIDER_LEN_32 = 0;
`endif                                                          
`ifdef SPI_DIVIDER_LEN_8
      localparam SPI_DIVIDER_LEN = 8;
      localparam SPI_DIVIDER_LEN_8 = 1;
      localparam SPI_DIVIDER_LEN_16 = 0;
      localparam SPI_DIVIDER_LEN_24 = 0;
      localparam SPI_DIVIDER_LEN_32 = 0;
`endif

`ifdef SPI_SS_NB_32
      localparam SPI_SS_NB = 32;
      localparam SPI_SS_NB_1 = 0;
      localparam SPI_SS_NB_8 = 0;
      localparam SPI_SS_NB_16 = 0;
      localparam SPI_SS_NB_24 = 0;
      localparam SPI_SS_NB_32 = 1;
`endif
`ifdef SPI_SS_NB_24
      localparam SPI_SS_NB = 24;
      localparam SPI_SS_NB_1 = 0;
      localparam SPI_SS_NB_8 = 0;
      localparam SPI_SS_NB_16 = 0;
      localparam SPI_SS_NB_24 = 1;
      localparam SPI_SS_NB_32 = 0;
`endif
`ifdef SPI_SS_NB_16
      localparam SPI_SS_NB = 16;
      localparam SPI_SS_NB_1 = 0;
      localparam SPI_SS_NB_8 = 0;
      localparam SPI_SS_NB_16 = 1;
      localparam SPI_SS_NB_24 = 0;
      localparam SPI_SS_NB_32 = 0;
`endif
`ifdef SPI_SS_NB_8
      localparam SPI_SS_NB = 8;
      localparam SPI_SS_NB_1 = 0;
      localparam SPI_SS_NB_8 = 1;
      localparam SPI_SS_NB_16 = 0;
      localparam SPI_SS_NB_24 = 0;
      localparam SPI_SS_NB_32 = 0;
`endif
`ifdef SPI_SS_NB_1
      localparam SPI_SS_NB = 1;
      localparam SPI_SS_NB_1 = 1;
      localparam SPI_SS_NB_8 = 0;
      localparam SPI_SS_NB_16 = 0;
      localparam SPI_SS_NB_24 = 0;
      localparam SPI_SS_NB_32 = 0;
`endif

  reg  card_present;

  // Internal signals
  reg       [SPI_DIVIDER_LEN-1:0]  divider;          // Divider register
  reg       [SPI_CTRL_BIT_NB-1:0]  ctrl;             // Control and status register
  reg             [SPI_SS_NB-1:0]  ss;               // Slave select register
  reg                     [32-1:0] wb_dat;           // wb data out
  wire         [SPI_MAX_CHAR-1:0]  rx;               // Rx register
  wire                             rx_negedge;       // miso is sampled on negative edge
  wire                             tx_negedge;       // mosi is driven on negative edge
  wire    [SPI_CHAR_LEN_BITS-1:0]  char_len;         // char len
  wire                             go;               // go
  wire                             lsb;              // lsb first on line
  wire                             ie;               // interrupt enable
  wire                             ass;              // automatic slave select
  wire                             spi_divider_sel;  // divider register select
  wire                             spi_ctrl_sel;     // ctrl register select
  wire                       [3:0] spi_tx_sel;       // tx_l register select
  wire                             spi_ss_sel;       // ss register select
  wire                             tip;              // transfer in progress
  wire                             pos_edge;         // recognize posedge of sclk
  wire                             neg_edge;         // recognize negedge of sclk
  wire                             last_bit;         // marks last character bit

  reg	[2:0]	raw_card_present;
  reg	[9:0]	card_detect_counter;

  wire cd_count_maxed = &card_detect_counter[9:0];

  initial	raw_card_present = 0;
  always @(posedge wb_clk_i) begin
    raw_card_present <= { raw_card_present[1:0], ~card_detect_i };
  end

  initial	card_detect_counter = 0;
  always @(posedge wb_clk_i) begin
    if (wb_rst_i || !raw_card_present[2])
      card_detect_counter <= 0;
  else if (!cd_count_maxed)
      card_detect_counter <= card_detect_counter + 1'b1;
  end

  initial card_present = 1'b0;
  always @(posedge wb_clk_i) begin
    if (wb_rst_i || !raw_card_present[2])
      card_present <= 1'b0;
    else if (cd_count_maxed)
      card_present <= 1'b1;
  end

  // Address decoder
  assign spi_divider_sel = wb_cyc_i & wb_stb_i & (wb_adr_i[SPI_OFS_BITS_MSB:SPI_OFS_BITS_LSB] == SPI_DEVIDE);
  assign spi_ctrl_sel    = wb_cyc_i & wb_stb_i & (wb_adr_i[SPI_OFS_BITS_MSB:SPI_OFS_BITS_LSB] == SPI_CTRL);
  assign spi_tx_sel[0]   = wb_cyc_i & wb_stb_i & (wb_adr_i[SPI_OFS_BITS_MSB:SPI_OFS_BITS_LSB] == SPI_TX_0);
  assign spi_tx_sel[1]   = wb_cyc_i & wb_stb_i & (wb_adr_i[SPI_OFS_BITS_MSB:SPI_OFS_BITS_LSB] == SPI_TX_1);
  assign spi_tx_sel[2]   = wb_cyc_i & wb_stb_i & (wb_adr_i[SPI_OFS_BITS_MSB:SPI_OFS_BITS_LSB] == SPI_TX_2);
  assign spi_tx_sel[3]   = wb_cyc_i & wb_stb_i & (wb_adr_i[SPI_OFS_BITS_MSB:SPI_OFS_BITS_LSB] == SPI_TX_3);
  assign spi_ss_sel      = wb_cyc_i & wb_stb_i & (wb_adr_i[SPI_OFS_BITS_MSB:SPI_OFS_BITS_LSB] == SPI_SS);

  generate
    if (SPI_DIVIDER_LEN_32 != 0) begin : div32


      // Divider register
      always @(posedge wb_clk_i)
        begin
          if (wb_rst_i)
            divider <= #Tp {SPI_DIVIDER_LEN{1'b0}};
          else if (spi_divider_sel && wb_we_i && !tip)
            begin
              if (wb_sel_i[0])
                divider[7:0] <= #Tp wb_dat_i[7:0];
              if (wb_sel_i[1])
                divider[15:8] <= #Tp wb_dat_i[15:8];
              if (wb_sel_i[2])
                divider[23:16] <= #Tp wb_dat_i[23:16];
              if (wb_sel_i[3])
                divider[SPI_DIVIDER_LEN-1:24] <= #Tp wb_dat_i[SPI_DIVIDER_LEN-1:24];
            end
        end

    end
    else if (SPI_DIVIDER_LEN_24 != 0) begin : div24


      // Divider register
      always @(posedge wb_clk_i)
        begin
          if (wb_rst_i)
            divider <= #Tp {SPI_DIVIDER_LEN{1'b0}};
          else if (spi_divider_sel && wb_we_i && !tip)
            begin
              if (wb_sel_i[0])
                divider[7:0] <= #Tp wb_dat_i[7:0];
              if (wb_sel_i[1])
                divider[15:8] <= #Tp wb_dat_i[15:8];
              if (wb_sel_i[2])
                divider[SPI_DIVIDER_LEN-1:16] <= #Tp wb_dat_i[SPI_DIVIDER_LEN-1:16];
            end
        end


    end
    else if (SPI_DIVIDER_LEN_16 != 0) begin : div16


      // Divider register
      always @(posedge wb_clk_i)
        begin
          if (wb_rst_i)
            divider <= #Tp {SPI_DIVIDER_LEN{1'b0}};
          else if (spi_divider_sel && wb_we_i && !tip)
            begin
              if (wb_sel_i[0])
                divider[7:0] <= #Tp wb_dat_i[7:0];
              if (wb_sel_i[1])
                divider[SPI_DIVIDER_LEN-1:8] <= #Tp wb_dat_i[SPI_DIVIDER_LEN-1:8];
            end
        end

    end
    else if (SPI_DIVIDER_LEN_8 != 0) begin : div8


      // Divider register
      always @(posedge wb_clk_i)
        begin
          if (wb_rst_i)
            divider <= #Tp {SPI_DIVIDER_LEN{1'b0}};
          else if (spi_divider_sel && wb_we_i && !tip)
            begin
              if (wb_sel_i[0])
                divider <= #Tp wb_dat_i[SPI_DIVIDER_LEN-1:0];
            end
        end

    end

  endgenerate

  generate
    if (SPI_SS_NB_32 != 0) begin: ss32


      // Slave select register
      always @(posedge wb_clk_i)
        begin
          if (wb_rst_i)
            ss <= #Tp {SPI_SS_NB{1'b0}};
          else if(spi_ss_sel && wb_we_i && !tip)
            begin
              if (wb_sel_i[0])
                ss[7:0] <= #Tp wb_dat_i[7:0];
              if (wb_sel_i[1])
                ss[15:8] <= #Tp wb_dat_i[15:8];
              if (wb_sel_i[2])
                ss[23:16] <= #Tp wb_dat_i[23:16];
              if (wb_sel_i[3])
                ss[SPI_SS_NB-1:24] <= #Tp wb_dat_i[SPI_SS_NB-1:24];
            end
        end

    end
    else if (SPI_SS_NB_24 != 0) begin: ss24


      // Slave select register
      always @(posedge wb_clk_i)
        begin
          if (wb_rst_i)
            ss <= #Tp {SPI_SS_NB{1'b0}};
          else if(spi_ss_sel && wb_we_i && !tip)
            begin
              if (wb_sel_i[0])
                ss[7:0] <= #Tp wb_dat_i[7:0];
              if (wb_sel_i[1])
                ss[15:8] <= #Tp wb_dat_i[15:8];
              if (wb_sel_i[2])
                ss[SPI_SS_NB-1:16] <= #Tp wb_dat_i[SPI_SS_NB-1:16];
            end
        end
    end
    else 
      if (SPI_SS_NB_16 != 0) begin: ss16


        // Slave select register
        always @(posedge wb_clk_i)
          begin
            if (wb_rst_i)
              ss <= #Tp {SPI_SS_NB{1'b0}};
            else if(spi_ss_sel && wb_we_i && !tip)
              begin
                if (wb_sel_i[0])
                  ss[7:0] <= #Tp wb_dat_i[7:0];
                if (wb_sel_i[1])
                  ss[SPI_SS_NB-1:8] <= #Tp wb_dat_i[SPI_SS_NB-1:8];
              end
          end
      end
    else 
      if (SPI_SS_NB_8 != 0) begin: ss8


        // Slave select register
        always @(posedge wb_clk_i)
          begin
            if (wb_rst_i)
              ss <= #Tp {SPI_SS_NB{1'b0}};
            else if(spi_ss_sel && wb_we_i && !tip)
              begin
                if (wb_sel_i[0])
                  ss <= #Tp wb_dat_i[SPI_SS_NB-1:0];
              end
          end

      end
    else     if (SPI_SS_NB_1 != 0) begin: ss1


      // Slave select register
      always @(posedge wb_clk_i)
        begin
          if (wb_rst_i)
            ss <= #Tp {SPI_SS_NB{1'b0}};
          else if(spi_ss_sel && wb_we_i && !tip)
            begin
              if (wb_sel_i[0])
                ss <= #Tp wb_dat_i[SPI_SS_NB-1:0];
            end
        end

    end
  endgenerate

  generate
    if (SPI_MAX_CHAR_128 != 0) begin : c128



      // Read from registers
      always @*
        begin
          case (wb_adr_i[SPI_OFS_BITS_MSB:SPI_OFS_BITS_LSB])
            SPI_RX_0:    wb_dat = rx[31:0];
            SPI_RX_1:    wb_dat = rx[63:32];
            SPI_RX_2:    wb_dat = rx[95:64];
            SPI_RX_3:    wb_dat = {{128-SPI_MAX_CHAR{1'b0}}, rx[SPI_MAX_CHAR-1:96]};
            //SPI_CTRL:    wb_dat = {{32-1-SPI_CTRL_BIT_NB{1'b0}}, card_present, ctrl};
            SPI_CTRL:    wb_dat = {{32-2-SPI_CTRL_BIT_NB{1'b0}}, raw_card_present[2], card_present, ctrl};
            SPI_DEVIDE:  wb_dat = {{32-SPI_DIVIDER_LEN{1'b0}}, divider};
            SPI_SS:      wb_dat = {{32-SPI_SS_NB{1'b0}}, ss};
            default:      wb_dat = 32'b0;
          endcase
        end

    end
    else if (SPI_MAX_CHAR_64 != 0) begin : c64



      // Read from registers
      always @*
        begin
          case (wb_adr_i[SPI_OFS_BITS_MSB:SPI_OFS_BITS_LSB])
            SPI_RX_0:    wb_dat = rx[31:0];
            SPI_RX_1:    wb_dat = {{64-SPI_MAX_CHAR{1'b0}}, rx[SPI_MAX_CHAR-1:32]};
            SPI_RX_2:    wb_dat = 32'b0;
            SPI_RX_3:    wb_dat = 32'b0;
            SPI_CTRL:    wb_dat = {{32-1-SPI_CTRL_BIT_NB{1'b0}}, card_present, ctrl};
            SPI_DEVIDE:  wb_dat = {{32-SPI_DIVIDER_LEN{1'b0}}, divider};
            SPI_SS:      wb_dat = {{32-SPI_SS_NB{1'b0}}, ss};
            default:      wb_dat = 32'b0;
          endcase
        end

    end
    else if (SPI_MAX_CHAR_32 != 0) begin : c32



      // Read from registers
      always @*
        begin
          case (wb_adr_i[SPI_OFS_BITS_MSB:SPI_OFS_BITS_LSB])
            SPI_RX_0:    wb_dat = {{32-SPI_MAX_CHAR{1'b0}}, rx[SPI_MAX_CHAR-1:0]};
            SPI_RX_1:    wb_dat = 32'b0;
            SPI_RX_2:    wb_dat = 32'b0;
            SPI_RX_3:    wb_dat = 32'b0;
            SPI_CTRL:    wb_dat = {{32-1-SPI_CTRL_BIT_NB{1'b0}}, card_present, ctrl};
            SPI_DEVIDE:  wb_dat = {{32-SPI_DIVIDER_LEN{1'b0}}, divider};
            SPI_SS:      wb_dat = {{32-SPI_SS_NB{1'b0}}, ss};
            default:      wb_dat = 32'b0;
          endcase
        end

    end
    else if (SPI_MAX_CHAR_24 != 0) begin : c24


      // Read from registers
      always @*
        begin
          case (wb_adr_i[SPI_OFS_BITS_MSB:SPI_OFS_BITS_LSB])
            SPI_RX_0:    wb_dat = {{32-SPI_MAX_CHAR{1'b0}}, rx[SPI_MAX_CHAR-1:0]};
            SPI_RX_1:    wb_dat = 32'b0;
            SPI_RX_2:    wb_dat = 32'b0;
            SPI_RX_3:    wb_dat = 32'b0;
            SPI_CTRL:    wb_dat = {{32-1-SPI_CTRL_BIT_NB{1'b0}}, card_present, ctrl};
            SPI_DEVIDE:  wb_dat = {{32-SPI_DIVIDER_LEN{1'b0}}, divider};
            SPI_SS:      wb_dat = {{32-SPI_SS_NB{1'b0}}, ss};
            default:      wb_dat = 32'b0;
          endcase
        end

    end
    else if (SPI_MAX_CHAR_16 != 0) begin : c16


      // Read from registers
      always @*
        begin
          case (wb_adr_i[SPI_OFS_BITS_MSB:SPI_OFS_BITS_LSB])
            SPI_RX_0:    wb_dat = {{32-SPI_MAX_CHAR{1'b0}}, rx[SPI_MAX_CHAR-1:0]};
            SPI_RX_1:    wb_dat = 32'b0;
            SPI_RX_2:    wb_dat = 32'b0;
            SPI_RX_3:    wb_dat = 32'b0;
            SPI_CTRL:    wb_dat = {{32-1-SPI_CTRL_BIT_NB{1'b0}}, card_present, ctrl};
            SPI_DEVIDE:  wb_dat = {{32-SPI_DIVIDER_LEN{1'b0}}, divider};
            SPI_SS:      wb_dat = {{32-SPI_SS_NB{1'b0}}, ss};
            default:      wb_dat = 32'b0;
          endcase
        end

    end
    else if (SPI_MAX_CHAR_8 != 0) begin : c8


      // Read from registers
      always @*
        begin
          case (wb_adr_i[SPI_OFS_BITS_MSB:SPI_OFS_BITS_LSB])
            SPI_RX_0:    wb_dat = {{32-SPI_MAX_CHAR{1'b0}}, rx[SPI_MAX_CHAR-1:0]};
            SPI_RX_1:    wb_dat = 32'b0;
            SPI_RX_2:    wb_dat = 32'b0;
            SPI_RX_3:    wb_dat = 32'b0;
            SPI_CTRL:    wb_dat = {{32-1-SPI_CTRL_BIT_NB{1'b0}}, card_present, ctrl};
            SPI_DEVIDE:  wb_dat = {{32-SPI_DIVIDER_LEN{1'b0}}, divider};
            SPI_SS:      wb_dat = {{32-SPI_SS_NB{1'b0}}, ss};
            default:      wb_dat = 32'b0;
          endcase
        end

    end
  endgenerate


  // Wb data out
  always @(posedge wb_clk_i)
    begin
      if (wb_rst_i)
        wb_dat_o <= #Tp 32'b0;
      else
        wb_dat_o <= #Tp wb_dat;
    end

  // Wb acknowledge
  always @(posedge wb_clk_i)
    begin
      if (wb_rst_i)
        wb_ack_o <= #Tp 1'b0;
      else
        wb_ack_o <= #Tp wb_cyc_i & wb_stb_i & ~wb_ack_o;
    end

  // Wb error
  assign wb_err_o = 1'b0;

  // Interrupt
  always @(posedge wb_clk_i)
    begin
      if (wb_rst_i)
        wb_int_o <= #Tp 1'b0;
      else if (ie && tip && last_bit && pos_edge)
        wb_int_o <= #Tp 1'b1;
      else
        wb_int_o <= #Tp 1'b0;
    end


  // Ctrl register
  always @(posedge wb_clk_i)
    begin
      if (wb_rst_i)
        ctrl <= #Tp {SPI_CTRL_BIT_NB{1'b0}};
      else if(spi_ctrl_sel && wb_we_i && !tip)
        begin
          if (wb_sel_i[0])
            ctrl[7:0] <= #Tp wb_dat_i[7:0] | {7'b0, ctrl[0]};
          if (wb_sel_i[1])
            ctrl[SPI_CTRL_BIT_NB-1:8] <= #Tp wb_dat_i[SPI_CTRL_BIT_NB-1:8];
        end
      else if(tip && last_bit && pos_edge)
        ctrl[SPI_CTRL_GO] <= #Tp 1'b0;
    end

  assign rx_negedge = ctrl[SPI_CTRL_RX_NEGEDGE];
  assign tx_negedge = ctrl[SPI_CTRL_TX_NEGEDGE];
  assign go         = ctrl[SPI_CTRL_GO];
  assign char_len   = ctrl[SPI_CTRL_CHAR_LEN_MSB:SPI_CTRL_CHAR_LEN_LSB];
  assign lsb        = ctrl[SPI_CTRL_LSB];
  assign ie         = ctrl[SPI_CTRL_IE];
  assign ass        = ctrl[SPI_CTRL_ASS];


  assign ss_pad_o = ~((ss & {SPI_SS_NB{tip & ass}}) | (ss & {SPI_SS_NB{!ass}}));

  spi_clgen #(
    .SPI_DIVIDER_LEN(SPI_DIVIDER_LEN)
  ) clgen (.clk_in(wb_clk_i), .rst(wb_rst_i), .go(go), .enable(tip), .last_clk(last_bit),
           .divider(divider), .clk_out(sclk_pad_o), .pos_edge(pos_edge), 
           .neg_edge(neg_edge));

  spi_shift #(
    .SPI_CHAR_LEN_BITS(SPI_CHAR_LEN_BITS),
    .SPI_MAX_CHAR(SPI_MAX_CHAR),
    .SPI_MAX_CHAR_128(SPI_MAX_CHAR_128),
    .SPI_MAX_CHAR_64(SPI_MAX_CHAR_64),
    .SPI_MAX_CHAR_32(SPI_MAX_CHAR_32),
    .SPI_MAX_CHAR_24(SPI_MAX_CHAR_24),
    .SPI_MAX_CHAR_16(SPI_MAX_CHAR_16),
    .SPI_MAX_CHAR_8(SPI_MAX_CHAR_8)
  ) shift (.clk(wb_clk_i), .rst(wb_rst_i), .len(char_len[SPI_CHAR_LEN_BITS-1:0]),
           .latch(spi_tx_sel[3:0] & {4{wb_we_i}}), .byte_sel(wb_sel_i), .lsb(lsb), 
           .go(go), .pos_edge(pos_edge), .neg_edge(neg_edge), 
           .rx_negedge(rx_negedge), .tx_negedge(tx_negedge),
           .tip(tip), .last(last_bit), 
           .p_in(wb_dat_i), .p_out(rx), 
           .s_clk(sclk_pad_o), .s_in(miso_pad_i), .s_out(mosi_pad_o));


endmodule

