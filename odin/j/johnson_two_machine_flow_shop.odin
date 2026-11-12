package johnson_two_machine_flow_shop

import "core:c"

MAX_JOBS :: 8
MAX_TIME :: 1000

@(export)
johnson_two_machine_flow_shop :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 do return -1
	if input[0] < 1 || input[0] > MAX_JOBS do return -1
	count := int(input[0])
	if length != c.size_t(1 + 2 * count) do return -1
	first, second: [MAX_JOBS]i64
	early, late: [MAX_JOBS]int
	early_count, late_count := 0, 0
	for job := 0; job < count; job += 1 {
		first[job] = input[1 + 2 * job]
		second[job] = input[2 + 2 * job]
		if first[job] < 0 || first[job] > MAX_TIME || second[job] < 0 || second[job] > MAX_TIME do return -1
		is_early := first[job] < second[job]
		position := early_count
		if !is_early do position = late_count
		for position > 0 {
			previous := early[position - 1]
			if !is_early do previous = late[position - 1]
			comes_before := first[job] < first[previous] || (first[job] == first[previous] && job < previous)
			if !is_early do comes_before = second[job] > second[previous] || (second[job] == second[previous] && job < previous)
			if !comes_before do break
			if is_early do early[position] = previous else late[position] = previous
			position -= 1
		}
		if is_early {
			early[position] = job
			early_count += 1
		} else {
			late[position] = job
			late_count += 1
		}
	}
	first_finish, second_finish := i64(0), i64(0)
	for index := 0; index < count; index += 1 {
		job := 0
		if index < early_count do job = early[index] else do job = late[index - early_count]
		first_finish += first[job]
		if second_finish < first_finish do second_finish = first_finish
		second_finish += second[job]
	}
	return second_finish
}
