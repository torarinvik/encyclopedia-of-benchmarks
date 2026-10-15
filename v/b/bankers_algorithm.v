// Check whether the process/resource state has a safe completion order.
@[export: 'bankers_algorithm']
pub fn bankers_algorithm(values &i64, length usize) i64 {
	if length < 5 || length > 266 { return -1 }
	process_value := unsafe { values[0] }
	resource_value := unsafe { values[1] }
	if process_value < 1 || process_value > 16 || resource_value < 1 || resource_value > 8 { return -1 }
	processes := int(process_value)
	resources := int(resource_value)
	maximum_offset := 2 + resources
	allocation_offset := maximum_offset + processes * resources
	if length != usize(allocation_offset + processes * resources) { return -1 }
	mut work := []i64{len: resources, init: 0}
	for resource := 0; resource < resources; resource++ {
		available := unsafe { values[2 + resource] }
		if available < 0 || available > 100 { return -1 }
		work[resource] = available
	}
	for process := 0; process < processes; process++ {
		for resource := 0; resource < resources; resource++ {
			index := process * resources + resource
			maximum := unsafe { values[maximum_offset + index] }
			allocation := unsafe { values[allocation_offset + index] }
			if maximum < 0 || maximum > 100 || allocation < 0 || allocation > maximum { return -1 }
		}
	}
	mut finished := []bool{len: processes, init: false}
	mut completed := 0
	for completed < processes {
		mut progress := false
		for process := 0; process < processes; process++ {
			if finished[process] { continue }
			mut feasible := true
			for resource := 0; resource < resources; resource++ {
				index := process * resources + resource
				need := unsafe { values[maximum_offset + index] - values[allocation_offset + index] }
				if need > work[resource] { feasible = false; break }
			}
			if feasible {
				for resource := 0; resource < resources; resource++ {
					work[resource] += unsafe { values[allocation_offset + process * resources + resource] }
				}
				finished[process] = true
				completed++
				progress = true
			}
		}
		if !progress { return 0 }
	}
	return 1
}
