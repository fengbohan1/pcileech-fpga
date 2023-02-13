# open_hw_manager
# connect_hw_server -allow_non_jtag
current_hw_device [get_hw_devices xc7k325t_0]
refresh_hw_device -update_hw_probes false [lindex [get_hw_devices xc7k325t_0] 0]

set_property PROBES.FILE {} [get_hw_devices xc7k325t_0]
set_property FULL_PROBES.FILE {} [get_hw_devices xc7k325t_0]
set_property PROGRAM.FILE {C:/Users/fengbh/work/pcileech-fpga/kc705/pcileech_kc705/pcileech_kc705.runs/impl_1/pcileech_kc705_top.bit} [get_hw_devices xc7k325t_0]

program_hw_devices [get_hw_devices xc7k325t_0]
refresh_hw_device [lindex [get_hw_devices xc7k325t_0] 0]