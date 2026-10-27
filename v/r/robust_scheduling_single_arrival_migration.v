module robust_scheduling_single_arrival_migration

const max_machines = 3
const max_old_jobs = 8
const max_input = 20
const max_output = 88

fn put64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

fn exact_optimum(machines int, sizes [9]i64, jobs int) i64 {
	mut assignments := 1
	for _ in 0 .. jobs { assignments *= machines }
	mut best := i64(0)
	for i in 0 .. jobs { best += sizes[i] }
	for code in 0 .. assignments {
		mut loads := [max_machines]i64{}
		mut remaining := code
		for j in 0 .. jobs {
			target := remaining % machines
			remaining /= machines
			loads[target] += sizes[j]
		}
		mut makespan := loads[0]
		for machine in 1 .. machines { if loads[machine] > makespan { makespan = loads[machine] } }
		if makespan < best { best = makespan }
	}
	return best
}

@[export: 'robust_scheduling_single_arrival_migration']
pub fn robust_scheduling_single_arrival_migration(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 6 || length > max_input { return -1 }
		m64, n64, claimed, new_size := input[0], input[1], input[2], input[3]
		if m64 < 2 || m64 > i64(max_machines) || n64 < 1 || n64 > i64(max_old_jobs) || claimed < 1 || new_size < 1 || new_size > 20 || length != usize(4 + 2*n64) { return -1 }
		machines, n := int(m64), int(n64)
		mut sizes := [9]i64{}
		mut assignment := [9]int{}
		mut loads := [max_machines]i64{}
		for i in 0 .. n {
			size, machine := input[4+2*i], input[5+2*i]
			if size < 1 || size > 20 || machine < 0 || machine >= m64 { return -1 }
			sizes[i], assignment[i] = size, int(machine)
			loads[int(machine)] += size
		}
		sizes[n] = new_size
		optimum := exact_optimum(machines, sizes, n+1)
		if claimed != optimum { return -1 }
		mut moved := i64(0)
		if 2*new_size <= optimum {
			mut target := 0
			for machine in 1 .. machines { if loads[machine] < loads[target] { target = machine } }
			assignment[n] = target
			loads[target] += new_size
		} else {
			mut source := -1
			for machine in 0 .. machines {
				mut eligible := true
				mut volume := i64(0)
				for i in 0 .. n { if assignment[i] == machine { if 2*sizes[i] > optimum { eligible = false }; volume += sizes[i] } }
				if eligible && volume >= new_size { source = machine; break }
			}
			if source < 0 { return -1 }
			mut removed := [max_old_jobs]bool{}
			mut volume := i64(0)
			for i in 0 .. n {
				if assignment[i] == source {
					removed[i] = true
					volume += sizes[i]
					loads[source] -= sizes[i]
					if volume >= new_size { break }
				}
			}
			if volume < new_size { return -1 }
			assignment[n] = source
			loads[source] += new_size
			for i in 0 .. n {
				if removed[i] {
					mut target := 0
					for machine in 1 .. machines { if loads[machine] < loads[target] { target = machine } }
					assignment[i] = target
					loads[target] += sizes[i]
					if target != source { moved += sizes[i] }
				}
			}
		}
		bytes := 8*(n+3)
		if output == nil || capacity < usize(bytes) { return -2 }
		mut staged := [max_output]u8{}
		put64(mut staged, 0, optimum)
		put64(mut staged, 8, moved)
		for i in 0 .. n+1 { put64(mut staged, 8*(i+2), i64(assignment[i])) }
		for i in 0 .. bytes { output[i] = staged[i] }
		return i64(bytes)
	}
}
