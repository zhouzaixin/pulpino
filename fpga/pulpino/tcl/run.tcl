# set default core to RI5CY
if { ! [info exists ::env(PULP_CORE)] } {
  set core "RI5CY"
} else {
  set core $::env(PULP_CORE)
}
puts "Set PULP core to $core"

# create project
create_project pulpino . -part $::env(XILINX_PART)
set_property board $::env(XILINX_BOARD) [current_project]

if { $core == "RI5CY" } {
  set_property include_dirs { \
    ../../ips/riscv/include \
    ../../rtl/include \
  } [current_fileset]
}

if { $core == "OR10N" } {
  set_property include_dirs { \
    ../../ips/or10n/include \
    ../../rtl/include \
  } [current_fileset]
}

# set up meaningful errors
source ../common/messages.tcl

source tcl/src_files.tcl

# add memory cuts
add_files -norecurse $FPGA_IPS/xilinx_mem_32768x32_dp/ip/xilinx_mem_32768x32_dp.dcp
add_files -norecurse $FPGA_IPS/xilinx_mem_32768x32/ip/xilinx_mem_32768x32.dcp

# add axi_mem_if_DP
add_files -norecurse -scan_for_includes $SRC_AXI_MEM_IF_DP

# add axi_spi_slave
add_files -norecurse -scan_for_includes $SRC_AXI_SLAVE

# add apb_spim
add_files -norecurse -scan_for_includes $SRC_APB_SPIM

# add apb_gpio
add_files -norecurse -scan_for_includes $SRC_APB_GPIO

# add apb_uart
add_files -norecurse -scan_for_includes $SRC_APB_UART

# add axi2apb
add_files -norecurse -scan_for_includes $SRC_AXI2APB

# add axi_slice
add_files -norecurse -scan_for_includes $SRC_AXI_SLICE

# add axi_slice_dc
add_files -norecurse -scan_for_includes $SRC_AXI_SLICE_DC

# add axi_node
add_files -norecurse -scan_for_includes $SRC_AXI_NODE

if { $core == "OR10N" } {
  # add or10n
  add_files -norecurse -scan_for_includes $SRC_OR10N
}

if { $core == "RI5CY" } {
  # add RI5CY
  add_files -norecurse -scan_for_includes $SRC_RI5CY
}

# add adv_dbg_if
add_files -norecurse -scan_for_includes $SRC_ADV_DEBUG_IF

# add common cells
add_files -norecurse $SRC_COMMONCELLS

# add pulpino
add_files -norecurse $SRC_PULPINO

# set pulpino_top as top
set_property top pulpino [current_fileset]

# needed only if used in batch mode
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# run synthesis
if { $core == "OR10N" } {
  # first try will fail
  catch {synth_design -rtl -name rtl_1 -verilog_define PULP_FPGA_EMUL=1}
  update_compile_order -fileset sources_1

  synth_design -rtl -name rtl_1 -verilog_define PULP_FPGA_EMUL=1
}

if { $core == "RI5CY" } {
  # first try will fail
  catch {synth_design -rtl -name rtl_1 -verilog_define PULP_FPGA_EMUL=1 -verilog_define RISCV}
  update_compile_order -fileset sources_1

  synth_design -rtl -name rtl_1 -verilog_define PULP_FPGA_EMUL=1 -verilog_define RISCV
}


create_clock -period  4.000 -name clk   -waveform {0.000 2.000} [get_nets {clk}]
create_clock -period 10.000 -name clk   -waveform {0.000 5.000} [get_nets {spi_clk_i}]
create_clock -period 10.000 -name tck_i -waveform {0.000 5.000} [get_nets {tck_i}]
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY none [get_runs synth_1]
#set_property STEPS.SYNTH_DESIGN.ARGS.KEEP_EQUIVALENT_REGISTERS true [get_runs synth_1]
#set_property STEPS.SYNTH_DESIGN.ARGS.RESOURCE_SHARING off [get_runs synth_1]
#set_property STEPS.SYNTH_DESIGN.ARGS.NO_LC true [get_runs synth_1]
launch_runs synth_1
wait_on_run synth_1

# save EDIF netlist
open_run synth_1
write_edif -force pulpino.edf
write_verilog -force -mode synth_stub pulpino_stub.v
write_verilog -force -mode funcsim pulpino_funcsim.v
