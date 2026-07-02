proc custom_report {num_paths delay_type} {
    
    # 1. Clean inputs to avoid hidden carriage returns (e.g., Windows \r)
    set n_paths [string trim $num_paths]
    set d_type [string trim $delay_type]
    
    # 2. Get the collection of timing paths based on user inputs
    set paths [get_timing_paths -delay_type $d_type -max_paths $n_paths -nworst $n_paths]
    
    # Safety check: if no paths are found with -nworst, fallback to standard extraction
    if {[sizeof_collection $paths] == 0} {
        set paths [get_timing_paths -delay_type $d_type -max_paths $n_paths]
    }
    
    # Extreme fallback: if design is too small for N paths, extract the worst overall
    if {[sizeof_collection $paths] == 0} {
        set paths [get_timing_paths -delay_type $d_type]
    }
    
    if {[sizeof_collection $paths] == 0} {
        puts "Warning: No timing paths found in the current design."
        return
    }
    
    # Arrays to store the total occurrences and the reference names of each cell
    array set cell_counts {}
    array set cell_refs {}
    
    # 3. Iterate over each extracted path
    foreach_in_collection path $paths {
        set points [get_attribute $path points]
        
        # Temporary array to ensure a cell is counted only once per path
        catch {unset path_cells}
        array set path_cells {}
        
        # 4. Iterate over each point (pin) in the timing path
        foreach_in_collection point $points {
            set pin [get_attribute $point object]
            
            # Extract the cell connected to the pin, filtering only combinational logic
            set cell [get_cells -of_objects $pin -filter "is_combinational == true" -quiet]
            
            if {[sizeof_collection $cell] > 0} {
                set c_name [get_attribute $cell full_name]
                set r_name [get_attribute $cell ref_name]
                set path_cells($c_name) $r_name
            }
        }
        
        # 5. Update the global counters using the unique cells found in the current path
        foreach c_name [array names path_cells] {
            if {[info exists cell_counts($c_name)]} {
                incr cell_counts($c_name)
            } else {
                set cell_counts($c_name) 1
                set cell_refs($c_name) $path_cells($c_name)
            }
        }
    }
    
    # 6. Format the results into a list for sorting
    set results_list {}
    foreach c_name [array names cell_counts] {
        lappend results_list [list $c_name $cell_refs($c_name) $cell_counts($c_name)]
    }
    
    # 7. Sort the list in descending order based on occurrences (index 2 of the sublist)
    set sorted_results [lsort -integer -decreasing -index 2 $results_list]
    
    # 8. Print the formatted custom report
    puts "\n========================================================"
    puts " CUSTOM TIMING REPORT"
    puts " Top $n_paths paths | Delay type: $d_type"
    puts "========================================================"
    puts "CELL_FULL_NAME                     CELL_REF_NAME  OCCURRENCES"
    puts "--------------------------------------------------------"
    foreach item $sorted_results {
        set c_name [lindex $item 0]
        set r_name [lindex $item 1]
        set count [lindex $item 2]
        puts [format "%-34s %-14s %d" $c_name $r_name $count]
    }
    puts "========================================================\n"
}