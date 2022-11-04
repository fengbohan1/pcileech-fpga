//
// PCILeech FPGA.
//
// Top module for the kc705 board.
//
// (c) Ulf Frisk, 2019-2020
// Author: Ulf Frisk, pcileech@frizk.net
//

`timescale 1ns / 1ps
`include "pcileech_header.svh"

module pcileech_kc705_top #(
    // DEVICE IDs as follows:
    // 0 = SP605, 1 = PCIeScreamer R1, 2 = AC701, 3 = PCIeScreamer R2, 4 = Screamer M2, 5 = NeTV2, 6-7 = RaptorDMA
    parameter       PARAM_DEVICE_ID = 5,
    parameter       PARAM_VERSION_NUMBER_MAJOR = 4,
    parameter       PARAM_VERSION_NUMBER_MINOR = 9,
    parameter       PARAM_CUSTOM_VALUE = 32'hffffffff,
    parameter       PARAM_UDP_STATIC_ADDR = 32'hc0a800de,   // 192.168.0.222
    parameter       PARAM_UDP_STATIC_FORCE = 1'b1,
    parameter       PARAM_UDP_PORT = 16'h6f3a               // 28474
) (
    // SYS
    input           sysclk_p,
    input           sysclk_n,
    // SYSTEM LEDs and BUTTONs
    output          led00,
    output          led01,
    output          led10,
    output          led11,
    output          led20,
    output          led21,
    
    // PCI-E FABRIC
    output  [0:0]   pcie_tx_p,
    output  [0:0]   pcie_tx_n,
    input   [0:0]   pcie_rx_p,
    input   [0:0]   pcie_rx_n,
    input           pcie_clk_p,
    input           pcie_clk_n,
    input           pcie_perst_n,
    output reg      pcie_wake_n = 1'b1,
      
    //MAC/RGMII
    output RGMII_TXC,              // 
    output [3:0] RGMII_TXD,        // 
    output RGMII_TX_CTL,           // 
    input  RGMII_RXC,              // 
    input  [3:0] RGMII_RXD,        // 
    input  RGMII_RX_CTL,           // 
    output RGMII_MDC,              // 
    inout  RGMII_MDIO,             // 

    output phy_reset_n,
    input  phy_int_n
        
    );
    
    // SYS
    wire            clkwiz_out_125;     // 125MHz
    wire            clkwiz_out_125_90;  // 125MHz 90
    wire            clkwiz_out_100;     // 100MHz
    wire            rst;
    wire            locked;
    assign phy_reset_n = locked;
    assign rst = ~locked;
    
    // FIFO CTL <--> COM CTL
    IfComToFifo     dcom_fifo();
    
    // FIFO CTL <--> PCIe
    IfPCIeFifoCfg   dcfg();
    IfPCIeFifoTlp   dtlp();
    IfPCIeFifoCore  dpcie();
    IfShadow2Fifo   dshadow2fifo();
    
    // ----------------------------------------------------
    // CLK 200MHz -> 125MHz:
    // ----------------------------------------------------
    clk_wiz i_clk_wiz(
    .clkwiz_out_125         ( clkwiz_out_125        ),     // output clkwiz_out_125
    .clkwiz_out_125_90      ( clkwiz_out_125_90     ),     // output clkwiz_out_125_90
    .clkwiz_out_100         ( clkwiz_out_100        ),     // output 100
    .locked                 ( locked                ),     // output locked
    .clk_in1_p              ( sysclk_p              ),     // input clk_in1_p
    .clk_in1_n              ( sysclk_n              ));    // input clk_in1_n

    assign i_pcileech_com.i_pcileech_eth.clk_90 = clkwiz_out_125_90;
    // ----------------------------------------------------
    // BUFFERED COMMUNICATION DEVICE (ETH)
    // ----------------------------------------------------
    
    pcileech_com i_pcileech_com (
        // SYS
        .clk                ( clkwiz_out_100        ),
        .clk_com            ( clkwiz_out_125        ),
        .rst                ( rst                   ),
        .led_state_txdata   ( led10                 ),  // ->
        .led_state_invert   ( 1'b0                  ),  // <-
        // FIFO CTL <--> COM CTL
        .dfifo              ( dcom_fifo.mp_com      ),
        // MAC/RMII
        .RGMII_TXC          ( RGMII_TXC             ),
        .RGMII_TXD          ( RGMII_TXD             ),
        .RGMII_TX_CTL       ( RGMII_TX_CTL          ),
        .RGMII_RXC          ( RGMII_RXC             ),
        .RGMII_RXD          ( RGMII_RXD             ),
        .RGMII_RX_CTL       ( RGMII_RX_CTL          ),
        .RGMII_MDC          ( RGMII_MDC             ),
        .RGMII_MDIO         ( RGMII_MDIO            ),

        .eth_cfg_static_addr ( PARAM_UDP_STATIC_ADDR    ),  // <- [31:0]
        .eth_cfg_static_force ( PARAM_UDP_STATIC_FORCE  ),  // <-
        .eth_cfg_port       ( PARAM_UDP_PORT        ),  // <- [15:0]
        .eth_led_state_red  ( led20                 ),  // ->
        .eth_led_state_green( led21                 )   // ->
    );
    
    // ----------------------------------------------------
    // FIFO CTL
    // ----------------------------------------------------
    
    pcileech_fifo #(
        .PARAM_DEVICE_ID            ( PARAM_DEVICE_ID               ),
        .PARAM_VERSION_NUMBER_MAJOR ( PARAM_VERSION_NUMBER_MAJOR    ),
        .PARAM_VERSION_NUMBER_MINOR ( PARAM_VERSION_NUMBER_MINOR    ),
        .PARAM_CUSTOM_VALUE         ( PARAM_CUSTOM_VALUE            )
    ) i_pcileech_fifo (
        .clk                ( clkwiz_out_100        ),
        .rst                ( rst                   ),
        .pcie_present       ( 1'b1                  ),
        .pcie_perst_n       ( pcie_perst_n          ),
        // FIFO CTL <--> COM CTL
        .dcom               ( dcom_fifo.mp_fifo     ),
        // FIFO CTL <--> PCIe
        .dcfg               ( dcfg.mp_fifo          ),
        .dtlp               ( dtlp.mp_fifo          ),
        .dpcie              ( dpcie.mp_fifo         ),
        .dshadow2fifo       ( dshadow2fifo.fifo     )
    );
    
    // ----------------------------------------------------
    // PCIe
    // ----------------------------------------------------
    
    pcileech_pcie_a7 i_pcileech_pcie_a7(
        .clk_100            ( clkwiz_out_100        ),
        .rst                ( rst                   ),
        // PCIe fabric
        .pcie_tx_p          ( pcie_tx_p             ),
        .pcie_tx_n          ( pcie_tx_n             ),
        .pcie_rx_p          ( pcie_rx_p             ),
        .pcie_rx_n          ( pcie_rx_n             ),
        .pcie_clk_p         ( pcie_clk_p            ),
        .pcie_clk_n         ( pcie_clk_n            ),
        .pcie_perst_n       ( pcie_perst_n          ),
        // State and Activity LEDs
        .led_state          ( led00                 ),
        // FIFO CTL <--> PCIe
        .dfifo_cfg          ( dcfg.mp_pcie          ),
        .dfifo_tlp          ( dtlp.mp_pcie          ),
        .dfifo_pcie         ( dpcie.mp_pcie         ),
        .dshadow2fifo_src   ( dshadow2fifo.src      ),
        .dshadow2fifo_tlp   ( dshadow2fifo.tlp      )
    );

endmodule
