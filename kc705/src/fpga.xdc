#
# CLK 50MHz BELOW 
#
set_property -dict {LOC AD12 IOSTANDARD LVDS} [get_ports sysclk_p]
create_clock -period 5.000 -waveform {0.000 2.500} [get_ports sysclk_p]

#
# LED BELOW
#
set_property -dict {LOC AB8   IOSTANDARD LVCMOS15} [get_ports led00]
set_property -dict {LOC AA8   IOSTANDARD LVCMOS15} [get_ports led01]
set_property -dict {LOC AC9   IOSTANDARD LVCMOS15} [get_ports led10]
set_property -dict {LOC AB9   IOSTANDARD LVCMOS15} [get_ports led11]
set_property -dict {LOC AE26  IOSTANDARD LVCMOS25} [get_ports led20]
set_property -dict {LOC G19   IOSTANDARD LVCMOS25} [get_ports led21]

#
# RMII ETH BELOW
#
    #MAC/MII
    set_property -dict {LOC  J21 IOSTANDARD LVCMOS25}  [get_ports MII_MDIO]              
    set_property -dict {LOC  R23 IOSTANDARD LVCMOS25}  [get_ports MII_MDC] 
    set_property -dict {LOC  L20 IOSTANDARD LVCMOS25}  [get_ports MII_RST_N]
    set_property -dict {LOC  R30 IOSTANDARD LVCMOS25}  [get_ports MII_CRS] 
    set_property -dict {LOC  W19 IOSTANDARD LVCMOS25}  [get_ports MII_COL]                
    set_property -dict {LOC  U27 IOSTANDARD LVCMOS25}  [get_ports MII_RX_CLK] 
    set_property -dict {LOC  V26 IOSTANDARD LVCMOS25}  [get_ports MII_RXERR]
    set_property -dict {LOC  R28 IOSTANDARD LVCMOS25}  [get_ports MII_CRS_DV]   
    set_property -dict {LOC  U30 IOSTANDARD LVCMOS25}  [get_ports MII_RXD[0]]  
    set_property -dict {LOC  U25 IOSTANDARD LVCMOS25}  [get_ports MII_RXD[1]] 
    set_property -dict {LOC  T25 IOSTANDARD LVCMOS25}  [get_ports MII_RXD[2]]     
    set_property -dict {LOC  U28 IOSTANDARD LVCMOS25}  [get_ports MII_RXD[3]] 

    set_property -dict {LOC  M28 IOSTANDARD LVCMOS25}  [get_ports MII_TX_CLK] 
    set_property -dict {LOC  M27 IOSTANDARD LVCMOS25}  [get_ports MII_TXEN]    
    set_property -dict {LOC  N27 IOSTANDARD LVCMOS25}  [get_ports MII_TXD[0]] 
    set_property -dict {LOC  N25 IOSTANDARD LVCMOS25}  [get_ports MII_TXD[1]] 
    set_property -dict {LOC  M29 IOSTANDARD LVCMOS25}  [get_ports MII_TXD[2]] 
    set_property -dict {LOC  L28 IOSTANDARD LVCMOS25}  [get_ports MII_TXD[3]] 

    set_property -dict {LOC  F16 IOSTANDARD LVCMOS25}  [get_ports MII_REF_CLK_25M]

set_false_path -from [get_pins {i_pcileech_fifo/_pcie_core_config_reg[*]/C}]
set_false_path -from [get_pins i_pcileech_pcie_a7/i_pcie_7x_0/inst/inst/user_lnk_up_int_reg/C] -to [get_pins {i_pcileech_fifo/_cmd_tx_din_reg[16]/D}]
set_false_path -from [get_pins i_pcileech_pcie_a7/i_pcie_7x_0/inst/inst/user_reset_out_reg/C]

#PCIe signals
set_property PACKAGE_PIN G25 [get_ports pcie_perst_n]
set_property PACKAGE_PIN F23 [get_ports pcie_wake_n]
set_property IOSTANDARD LVCMOS33 [get_ports pcie_perst_n]
set_property IOSTANDARD LVCMOS33 [get_ports pcie_wake_n]

# NB! one of the LOC GTPE2 lines will generate a crical warning and be ignored.
set_property LOC GTXE2_CHANNEL_X0Y7 [get_cells {i_pcileech_pcie_a7/i_pcie_7x_0/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/gtp_channel.gtpe2_channel_i}]
set_property PACKAGE_PIN M6  [get_ports {pcie_rx_p[0]}]
set_property PACKAGE_PIN M5  [get_ports {pcie_rx_n[0]}]
set_property PACKAGE_PIN L4  [get_ports {pcie_tx_p[0]}]
set_property PACKAGE_PIN L3  [get_ports {pcie_tx_n[0]}]
set_property PACKAGE_PIN U8  [get_ports pcie_clk_p]
set_property PACKAGE_PIN U7  [get_ports pcie_clk_n]


create_clock -name pcie_refclk_p -period 10.0 [get_nets pcie_clk_p]

#
# BITSTREAM CONFIG BELOW
#
#set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 66 [current_design]
