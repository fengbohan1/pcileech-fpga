//
// PCILeech FPGA RMII ETHERNET.
//
//
// (c) Ulf Frisk, 2019-2020
// Author: Ulf Frisk, pcileech@frizk.net
//

`timescale 1ns / 1ps
`include "FC1004_RGMII.vh"

module pcileech_eth (
    // SYS
    input               clk,                // 125MHz CLK
    (* MARK_DEBUG="true" *) input               rst,
    
    //MAC/RGMII
    output RGMII_TXC,              // 
    output [3:0] RGMII_TXD,        // 
    output RGMII_TX_CTL,           // 
    input  RGMII_RXC,              // 
    input  [3:0] RGMII_RXD,        // 
    input  RGMII_RX_CTL,           // 
    output RGMII_MDC,              // 
    inout  RGMII_MDIO,             // 
    
    // CONFIG
    input   [31:0]      cfg_static_addr,
    input               cfg_static_force,
    input   [15:0]      cfg_port,
    
    // State and Activity LEDs
    output              led_state_red,
    output              led_state_green,
    
    // TO/FROM FIFO
    output reg [31:0]   dout,
    output              dout_valid,
    input [31:0]        din,
    input               din_empty,
    input               din_wr_en,
    output              din_ready
    
    );
    
    // ----------------------------------------------------
    // TickCount64
    // ----------------------------------------------------
    
    time tickcount64 = 0;
    always @ ( posedge clk )
        tickcount64 <= tickcount64 + 1;
    
    // ----------------------------------------------------
    // DHCP / NET CONFIG:
    // try DHCP for 10 seconds, if no address is received -> use static instead
    // red blink = static address, no tcp connection
    // red on = reset/error
    // green blink = dhcp, no tcp connection
    // green on = tcp connection
    // ----------------------------------------------------
    
    (* MARK_DEBUG="true" *) reg f_dhcp_is_enabled = 1'b1;
    (* MARK_DEBUG="true" *) wire f_dhcp_ip_ok;
    wire led_dimmer = tickcount64[9] & tickcount64[10]; 
    
    always @ ( posedge clk )
        if ( cfg_static_force | ((tickcount64 == 10 * 100000000) && !f_dhcp_ip_ok) )  // 10s timeout for DHCP
            f_dhcp_is_enabled <= 1'b0;  
    
    OBUF led_ld1_obuf(.O( led_state_red ),   .I( led_dimmer & ((!f_dhcp_is_enabled & tickcount64[25]) | rst) ));
    OBUF led_ld2_obuf(.O( led_state_green ), .I( f_dhcp_is_enabled & tickcount64[25] ));
    
    // ----------------------------------------------------
    // Data Transfer ETH -> FIFO
    // ----------------------------------------------------
    
    (* MARK_DEBUG="true" *) wire [7:0]  UDP0_RxData;
    (* MARK_DEBUG="true" *) wire        UDP0_RxValid;
    reg [3:0]   dout_RxValid4 = 4'b0000;
    assign dout_valid = (dout_RxValid4 == 4'b1111);
    
    always @ ( posedge clk )
        begin
            if ( UDP0_RxValid )
                dout <= (dout << 8) | UDP0_RxData;
            if ( rst )
                dout_RxValid4 <= 4'b0000;
            else if ( dout_RxValid4 == 4'b1111 )
                dout_RxValid4 <= 4'b0000 | UDP0_RxValid;
            else if ( UDP0_RxValid )
                dout_RxValid4 <= (dout_RxValid4 << 1) | UDP0_RxValid;
        end 

    // ----------------------------------------------------
    // Data Transfer FIFO -> ETH
    // ----------------------------------------------------
    
    (* MARK_DEBUG="true" *) wire        UDP0_TxReady;
    reg [3:0]   din_TxValid4 = 4'b0000;
    (* MARK_DEBUG="true" *) reg [31:0]  din_TxData32;
    wire        din_TxValid4_empty = (din_TxValid4 == 4'b0000) ? 1 : 0;
    
    
    reg [8:0]   UDP0_TxPacketCountDWORD = 0;
    
    (* MARK_DEBUG="true" *) wire UDP0_TxValid = din_TxValid4[3] & UDP0_TxReady;
    (* MARK_DEBUG="true" *) wire UDP0_TxLast = (din_TxValid4 == 4'b1000) & UDP0_TxReady & ( din_empty | (UDP0_TxPacketCountDWORD == 9'h100) );
    
    
    assign din_ready = ~din_empty & ~din_wr_en & din_TxValid4_empty;
    
    always @ ( posedge clk )
        begin
            if ( rst )
                begin
                    din_TxValid4 <= 4'b0000;
                    UDP0_TxPacketCountDWORD <= 0;
                end
            else if ( din_wr_en & din_TxValid4_empty )
                begin
                    din_TxData32 <= din;
                    din_TxValid4 <= 4'b1111;
                    UDP0_TxPacketCountDWORD <= UDP0_TxPacketCountDWORD + 1;
                end
            else
                begin
                    if ( UDP0_TxValid )
                        begin
                            din_TxData32 <= din_TxData32 << 8;
                            din_TxValid4 <= din_TxValid4 << 1;
                        end
                    if ( UDP0_TxLast )
                        UDP0_TxPacketCountDWORD <= 0;
                end
        end
    
    // ----------------------------------------------------
    // TCP Core:
    // NB! module makes use of STARTUPE2 RESOURCE
    // ----------------------------------------------------
    /*
    FC1003_RMII i_FC1003_RMII(
        .Clk                ( clk                   ),
        .Reset              ( rst                   ),
        .UseDHCP            ( f_dhcp_is_enabled     ),
        .IP_Addr            ( f_dhcp_is_enabled ? 32'h00000000 : cfg_static_addr ),
        .IP_Ok              ( f_dhcp_ip_ok          ),
    
        // MAC/RMII
        .RMII_CLK_50M       ( eth_clk50             ),
        .RMII_RST_N         ( eth_rst_n             ),
        .RMII_CRS_DV        ( eth_crs_dv            ),
        .RMII_RXD0          ( eth_rx_data[0]        ),
        .RMII_RXD1          ( eth_rx_data[1]        ),
        .RMII_RXERR         ( eth_rx_err            ),
        .RMII_TXEN          ( eth_tx_en             ),
        .RMII_TXD0          ( eth_tx_data[0]        ),
        .RMII_TXD1          ( eth_tx_data[1]        ),
        .RMII_MDC           ( eth_mdc               ),
        .RMII_MDIO          ( eth_mdio              ),
        
        // SPI/Boot Control
        .SPI_CSn            (                       ),  // ->
        .SPI_SCK            (                       ),  // ->
        .SPI_MOSI           (                       ),  // ->
        .SPI_MISO           ( 1'b0                  ),  // <-
        
        // Logic Analyzer - not used
        .LA0_TrigIn         ( 1'b0                  ),
        .LA0_Clk            ( 1'b0                  ),
        .LA0_TrigOut        (                       ),
        .LA0_Signals        ( 32'h00000000          ),
        .LA0_SampleEn       ( 1'b0                  ),
        
        // UDP Basic Server
        .UDP0_Reset         ( 1'b0                  ),  // <- [Reset interface, active high]
        .UDP0_Service       ( 16'h0112              ),  // <- [15:0]
        .UDP0_ServerPort    ( cfg_port              ),  // <- [15:0]
        .UDP0_Connected     (                       ),  // ->
        .UDP0_OutIsEmpty    (                       ),
        .UDP0_TxData        ( din_TxData32[31:24]   ),
        .UDP0_TxValid       ( UDP0_TxValid          ),
        .UDP0_TxReady       ( UDP0_TxReady          ),
        .UDP0_TxLast        ( UDP0_TxLast           ),
        .UDP0_RxData        ( UDP0_RxData           ),
        .UDP0_RxValid       ( UDP0_RxValid          ),
        .UDP0_RxReady       ( 1'b1                  ),
        .UDP0_RxLast        (                       )
    );*/

    // ----------------------------------------------------
    // TCP Core:
    // NB! module makes use of STARTUPE2 RESOURCE
    // ----------------------------------------------------
    FC1004_RGMII i_FC1004_RGMII(
        .Clk                ( clk                   ),  // 125 MHz
        .Clk_Tx             ( clk                   ),  // 125 MHz RGMII Transmit clock
        .Reset              ( rst                   ),  // Active high
        .UseDHCP            ( f_dhcp_is_enabled     ),  // '1' to use DHCP
        .IP_Addr            ( f_dhcp_is_enabled ? 32'h00000000 : cfg_static_addr ),
        .IP_Ok              ( f_dhcp_ip_ok          ),  // DHCP ready

        // TCP Basic Server
        .TCP0_Service       ( 'd0                   ),  // Service
        .TCP0_ServerPort    ( 'd0                   ),  // TCP local server port
        .TCP0_Connected     (                       ),  //
        .TCP0_AllAcked      (                       ),  //
        .TCP0_nTxFree       (                       ),  //
        .TCP0_nRxData       (                       ),  //
        .TCP0_TxData        ( 'd0                   ),  // Transmit data
        .TCP0_TxValid       ( 'd0                   ),  // Transmit data valid
        .TCP0_TxReady       (                       ),  //
        .TCP0_RxData        (                       ),  //
        .TCP0_RxValid       (                       ),  //
        .TCP0_RxReady       ( 'd0                   ),  // Receive data ready
    
        // MAC/RMII
        .RGMII_TXC          ( RGMII_TXC             ),
        .RGMII_TXD          ( RGMII_TXD             ),
        .RGMII_TX_CTL       ( RGMII_TX_CTL          ),
        .RGMII_RXC          ( RGMII_RXC             ),
        .RGMII_RXD          ( RGMII_RXD             ),
        .RGMII_RX_CTL       ( RGMII_RX_CTL          ),
        .RGMII_MDC          ( RGMII_MDC             ),
        .RGMII_MDIO         ( RGMII_MDIO            ),
        
        // SPI/Boot Control
        .SPI_CSn            (                       ),  // ->
        .SPI_SCK            (                       ),  // ->
        .SPI_MOSI           (                       ),  // ->
        .SPI_MISO           ( 1'b0                  ),  // <-
        
        // Logic Analyzer - not used
        .LA0_TrigIn         ( 1'b0                  ),
        .LA0_Clk            ( 1'b0                  ),
        .LA0_TrigOut        (                       ),
        .LA0_Signals        ( 32'h00000000          ),
        .LA0_SampleEn       ( 1'b0                  ),
        
        // UDP Basic Server
        .UDP0_Reset         ( 1'b0                  ),  // <- [Reset interface, active high]
        .UDP0_Service       ( 16'h0112              ),  // <- [15:0]
        .UDP0_ServerPort    ( cfg_port              ),  // <- [15:0]
        .UDP0_Connected     (                       ),  // ->
        .UDP0_OutIsEmpty    (                       ),
        .UDP0_TxData        ( din_TxData32[31:24]   ),
        .UDP0_TxValid       ( UDP0_TxValid          ),
        .UDP0_TxReady       ( UDP0_TxReady          ),
        .UDP0_TxLast        ( UDP0_TxLast           ),
        .UDP0_RxData        ( UDP0_RxData           ),
        .UDP0_RxValid       ( UDP0_RxValid          ),
        .UDP0_RxReady       ( 1'b1                  ),
        .UDP0_RxLast        (                       )
    );



endmodule
