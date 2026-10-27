package robust_scheduling_single_arrival_migration

import "core:c"

MAX_MACHINES :: 3
MAX_OLD_JOBS :: 8
MAX_INPUT :: 20
MAX_OUTPUT :: 88

exact_optimum :: proc(machines: int, sizes: [9]i64, jobs: int) -> i64 {
	assignments := 1
	for _ := 0; _ < jobs; _ += 1 { assignments *= machines }
	best: i64 = 0
	for i := 0; i < jobs; i += 1 { best += sizes[i] }
	for code := 0; code < assignments; code += 1 {
		loads: [MAX_MACHINES]i64
		remaining := code
		for j := 0; j < jobs; j += 1 {
			target := remaining % machines
			remaining /= machines
			loads[target] += sizes[j]
		}
		makespan := loads[0]
		for machine := 1; machine < machines; machine += 1 { if loads[machine] > makespan { makespan = loads[machine] } }
		if makespan < best { best = makespan }
	}
	return best
}

put64 :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
robust_scheduling_single_arrival_migration :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 6 || length > MAX_INPUT do return -1
	m64, n64, claimed, new_size := input[0], input[1], input[2], input[3]
	if m64 < 2 || m64 > MAX_MACHINES || n64 < 1 || n64 > MAX_OLD_JOBS || claimed < 1 || new_size < 1 || new_size > 20 || length != c.size_t(4+2*n64) do return -1
	m, n := int(m64), int(n64)
	sizes: [9]i64
	assignment: [9]int
	loads: [MAX_MACHINES]i64
	for i := 0; i < n; i += 1 {
		size, machine := input[4+2*i], input[5+2*i]
		if size < 1 || size > 20 || machine < 0 || machine >= m64 do return -1
		sizes[i], assignment[i] = size, int(machine)
		loads[int(machine)] += size
	}
	sizes[n] = new_size
	optimum := exact_optimum(m, sizes, n+1)
	if claimed != optimum do return -1
	moved: i64 = 0
	if 2*new_size <= optimum {
		target := 0
		for machine := 1; machine < m; machine += 1 { if loads[machine] < loads[target] { target = machine } }
		assignment[n] = target
		loads[target] += new_size
	} else {
		source := -1
		for machine := 0; machine < m; machine += 1 {
			eligible := true
			volume: i64 = 0
			for i := 0; i < n; i += 1 {
				if assignment[i] == machine { if 2*sizes[i] > optimum { eligible = false }; volume += sizes[i] }
			}
			if eligible && volume >= new_size { source = machine; break }
		}
		if source < 0 do return -1
		removed: [MAX_OLD_JOBS]bool
		volume: i64 = 0
		for i := 0; i < n; i += 1 {
			if assignment[i] == source {
				removed[i] = true
				volume += sizes[i]
				loads[source] -= sizes[i]
				if volume >= new_size { break }
			}
		}
		if volume < new_size do return -1
		assignment[n] = source
		loads[source] += new_size
		for i := 0; i < n; i += 1 {
			if removed[i] {
				target := 0
				for machine := 1; machine < m; machine += 1 { if loads[machine] < loads[target] { target = machine } }
				assignment[i] = target
				loads[target] += sizes[i]
				if target != source { moved += sizes[i] }
			}
		}
	}
	bytes := 8*(n+3)
	if output == nil || capacity < c.size_t(bytes) do return -2
	staged: [MAX_OUTPUT]u8
	put64(&staged[0], 0, optimum)
	put64(&staged[0], 8, moved)
	for i := 0; i < n+1; i += 1 { put64(&staged[0], 8*(i+2), i64(assignment[i])) }
	for i := 0; i < bytes; i += 1 { output[i] = staged[i] }
	return i64(bytes)
}
