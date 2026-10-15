package bankers_algorithm

import "core:c"

MAX_PROCESSES :: 16
MAX_RESOURCES :: 8

// Check whether the process/resource state has a safe completion order.
@(export)
bankers_algorithm :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 5 || length > 266 do return -1
	process_value := values[0]
	resource_value := values[1]
	if process_value < 1 || process_value > MAX_PROCESSES || resource_value < 1 || resource_value > MAX_RESOURCES do return -1
	processes := int(process_value)
	resources := int(resource_value)
	maximum_offset := 2 + resources
	allocation_offset := maximum_offset + processes * resources
	if length != c.size_t(allocation_offset + processes * resources) do return -1
	work: [MAX_RESOURCES]i64
	for resource := 0; resource < resources; resource += 1 {
		available := values[2 + resource]
		if available < 0 || available > 100 do return -1
		work[resource] = available
	}
	for process := 0; process < processes; process += 1 {
		for resource := 0; resource < resources; resource += 1 {
			index := process * resources + resource
			maximum := values[maximum_offset + index]
			allocation := values[allocation_offset + index]
			if maximum < 0 || maximum > 100 || allocation < 0 || allocation > maximum do return -1
		}
	}
	finished: [MAX_PROCESSES]bool
	completed := 0
	for completed < processes {
		progress := false
		for process := 0; process < processes; process += 1 {
			if finished[process] do continue
			feasible := true
			for resource := 0; resource < resources; resource += 1 {
				index := process * resources + resource
				need := values[maximum_offset + index] - values[allocation_offset + index]
				if need > work[resource] { feasible = false; break }
			}
			if feasible {
				for resource := 0; resource < resources; resource += 1 {
					work[resource] += values[allocation_offset + process * resources + resource]
				}
				finished[process] = true
				completed += 1
				progress = true
			}
		}
		if !progress do return 0
	}
	return 1
}
