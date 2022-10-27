module FC1003_MII (
    //Sys/Common
    input  Clk,                    // 100 MHz
    input  Reset,                  // Active high
    input  UseDHCP,                // '1' to use DHCP
    input  [31:0] IP_Addr,         // IP address if not using DHCP
    output IP_Ok,                  // DHCP ready

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

    //SPI/Boot Control
    output SPI_CSn,                // Chip select
    output SPI_SCK,                // Serial clock
    output SPI_MOSI,               // Master out slave in
    input  SPI_MISO,               // Master in slave out

    //Logic Analyzer
    input  LA0_TrigIn,             // Trigger input
    input  LA0_Clk,                // Clock
    output LA0_TrigOut,            // Trigger out
    input  [31:0] LA0_Signals,     // Signals
    input  LA0_SampleEn,           // Sample enable

    //UDP Basic Server
    input  UDP0_Reset,             // Reset interface, active high
    input  [15:0] UDP0_Service,    // Service
    input  [15:0] UDP0_ServerPort, // UDP local server port
    output UDP0_Connected,         // Client connected
    output UDP0_OutIsEmpty,        // All outgoing data acked
    input  [7:0] UDP0_TxData,      // Transmit data
    input  UDP0_TxValid,           // Transmit data valid
    output UDP0_TxReady,           // Transmit data ready
    input  UDP0_TxLast,            // Transmit data last
    output [7:0] UDP0_RxData,      // Receive data
    output UDP0_RxValid,           // Receive data valid
    input  UDP0_RxReady,           // Receive data ready
    output UDP0_RxLast             // Transmit data last
);

endmodule
