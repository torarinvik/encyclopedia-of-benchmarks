const max_jobs = 8
const max_time = i64(1000)

@[export: 'johnson_two_machine_flow_shop']
pub fn johnson_two_machine_flow_shop(input &i64, length usize) i64 {
	if length < 1 { return -1 }
	unsafe {
		if input == nil || input[0] < 1 || input[0] > max_jobs { return -1 }
		count := int(input[0])
		if length != usize(1 + 2 * count) { return -1 }
		mut first := [max_jobs]i64{}
		mut second := [max_jobs]i64{}
		mut early := [max_jobs]int{}
		mut late := [max_jobs]int{}
		mut early_count := 0
		mut late_count := 0
		for job in 0 .. count {
			first[job] = input[1 + 2 * job]
			second[job] = input[2 + 2 * job]
			if first[job] < 0 || first[job] > max_time || second[job] < 0 || second[job] > max_time { return -1 }
			is_early := first[job] < second[job]
			mut position := if is_early { early_count } else { late_count }
			for position > 0 {
				previous := if is_early { early[position - 1] } else { late[position - 1] }
				comes_before := if is_early {
					first[job] < first[previous] || (first[job] == first[previous] && job < previous)
				} else {
					second[job] > second[previous] || (second[job] == second[previous] && job < previous)
				}
				if !comes_before { break }
				if is_early { early[position] = previous } else { late[position] = previous }
				position--
			}
			if is_early {
				early[position] = job
				early_count++
			} else {
				late[position] = job
				late_count++
			}
		}
		mut first_finish := i64(0)
		mut second_finish := i64(0)
		for index in 0 .. count {
			job := if index < early_count { early[index] } else { late[index - early_count] }
			first_finish += first[job]
			if second_finish < first_finish { second_finish = first_finish }
			second_finish += second[job]
		}
		return second_finish
	}
}
