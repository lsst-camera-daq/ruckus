
# Project Batch-Mode Run Script

# Get variables
set VIVADO_PROJECT   $::env(VIVADO_PROJECT)
set VIVADO_BUILD_DIR $::env(VIVADO_BUILD_DIR)
set VIVADO_DIR       $::env(VIVADO_DIR)

# Load Custom Procedures
source ${VIVADO_BUILD_DIR}/vivado_proc_v1.tcl

# Open the project
open_project -quiet ${VIVADO_PROJECT}
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Clean up runs
reset_run synth_1
reset_run impl_1

# Generate all IP cores' output files
generate_target all [get_ips]
if { [get_ips] != " " } {
   foreach corePntr [get_ips] {
      create_ip_run [get_ips ${corePntr}]
      if { [get_property PROGRESS [get_runs ${corePntr}_synth_1]]!="100\%" } {
         launch_runs [get_runs ${corePntr}_synth_1]
         wait_on_run ${corePntr}_synth_1
      }
   }
}

# Synthesize
launch_run  synth_1
wait_on_run synth_1

# Target post synthesis script
source ${VIVADO_BUILD_DIR}/vivado_post_synthesis_v1.tcl

# Check that the Synthesize is completed
if { [get_property PROGRESS [get_runs synth_1]]!="100\%" || \
     [get_property STATUS [get_runs synth_1]]!="synth_design Complete!" } {
   close_project
   exit -1
}

# Implement
launch_run -to_step write_bitstream impl_1
wait_on_run impl_1

# Target post route script
source ${VIVADO_BUILD_DIR}/vivado_post_route_v1.tcl

# Check that the Implement is completed
if { [get_property PROGRESS [get_runs impl_1]]!="100\%" || \
     [get_property STATUS [get_runs impl_1]]!="write_bitstream Complete!" } {
   close_project
   exit -1
}

# Check if there were timing or routing errors during implement
if { [CheckTiming]==false } {
   close_project
   exit -1
}

# Close the project
close_project
exit 0
