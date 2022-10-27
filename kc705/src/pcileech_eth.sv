//
// PCILeech FPGA RMII ETHERNET.
//
//
// (c) Ulf Frisk, 2019-2020
// Author: Ulf Frisk, pcileech@frizk.net
//

`timescale 1ns / 1ps
`include "FC1003_MII.vh"

module pcileech_eth (
    // SYS
    input               clk,                // 100MHz CLK
    input               rst,
    
    //MAC/MII
    output MII_REF_CLK_25M,        // MII continous 25 MHz reference clock
    output MII_RST_N,              // Phy reset, active low
    input  MII_COL,                // Collision detect
    input  MII_CRS,                // Carrier sense
    input  MII_RX_CLK,             // Receive clock
    input  MII_CRS_DV,             // Receive data valid
    input  [3:0] MII_RXD,          // Receive data
    input  MII_RXERR,              // Receive error
    input  MII_TX_CLK,             // Transmit clock
    output MII_TXEN,               // Transmit enable
    output [3:0] MII_TXD,          // Transmit data
    output MII_MDC,                // Management clock
    inout  MII_MDIO,               // Management data
    
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
    
    reg f_dhcp_is_enabled = 1'b1;
    wire f_dhcp_ip_ok;
    wire led_dimmer = tickcount64[9] & tickcount64[10]; 
    
    always @ ( posedge clk )
        if ( cfg_static_force | ((tickcount64 == 10 * 100000000) && !f_dhcp_ip_ok) )  // 10s timeout for DHCP
            f_dhcp_is_enabled <= 1'b0;  
    
    OBUF led_ld1_obuf(.O( led_state_red ),   .I( led_dimmer & ((!f_dhcp_is_enabled & tickcount64[25]) | rst) ));
    OBUF led_ld2_obuf(.O( led_state_green ), .I( f_dhcp_is_enabled & tickcount64[25] ));
    
    // ----------------------------------------------------
    // Data Transfer ETH -> FIFO
    // ----------------------------------------------------
    
    wire [7:0]  UDP0_RxData;
    wire        UDP0_RxValid;
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
    
    wire        UDP0_TxReady;
    reg [3:0]   din_TxValid4 = 4'b0000;
    reg [31:0]  din_TxData32;
    wire        din_TxValid4_empty = (din_TxValid4 == 4'b0000) ? 1 : 0;
    
    
    reg [8:0]   UDP0_TxPacketCountDWORD = 0;
    
    wire UDP0_TxValid = din_TxValid4[3] & UDP0_TxReady;
    wire UDP0_TxLast = (din_TxValid4 == 4'b1000) & UDP0_TxReady & ( din_empty | (UDP0_TxPacketCountDWORD == 9'h100) );
    
    
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
    FC1003_MII i_FC1003_MII(
        .Clk                ( clk                   ),
        .Reset              ( rst                   ),
        .UseDHCP            ( f_dhcp_is_enabled     ),
        .IP_Addr            ( f_dhcp_is_enabled ? 32'h00000000 : cfg_static_addr ),
        .IP_Ok              ( f_dhcp_ip_ok          ),
    
        // MAC/RMII
        .MII_REF_CLK_25M    ( MII_REF_CLK_25M       ),        // MII continous 25 MHz reference clock
        .MII_RST_N          ( MII_RST_N             ),        // Phy reset, active low
        .MII_COL            ( MII_COL               ),        // Collision detect
        .MII_CRS            ( MII_CRS               ),        // Carrier sense
        .MII_RX_CLK         ( MII_RX_CLK            ),        // Receive clock
        .MII_CRS_DV         ( MII_CRS_DV            ),        // Receive data valid
        .MII_RXD            ( MII_RXD               ),        // Receive data
        .MII_RXERR          ( MII_RXERR             ),        // Receive error
        .MII_TX_CLK         ( MII_TX_CLK            ),        // Transmit clock
        .MII_TXEN           ( MII_TXEN              ),        // Transmit enable
        .MII_TXD            ( MII_TXD               ),        // Transmit data
        .MII_MDC            ( MII_MDC               ),        // Management clock
        .MII_MDIO           ( MII_MDIO              ),        // Management data
        
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
