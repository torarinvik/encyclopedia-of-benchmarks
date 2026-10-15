module assignment_using_bitmask

// Count task assignments with one distinct eligible task per person.
@[export: 'assignment_using_bitmask']
pub fn assignment_using_bitmask(input &i64, length usize) i64 {
	if length < 2 { return -1 }
	people := unsafe { input[0] }
	tasks := unsafe { input[1] }
		if people < 0 || people > 10 || tasks < 0 || tasks > 10 || length != usize(2 + people) { return -1 }
	valid_tasks := (i64(1) << int(tasks)) - 1
	for person in 0 .. int(people) {
		mask := unsafe { input[person + 2] }
		if mask < 0 || mask > valid_tasks { return -1 }
	}

	states := 1 << int(people)
	mut ways := [4096]i64{init: 0}
	mut next := [4096]i64{init: 0}
	ways[0] = 1
	for task in 0 .. int(tasks) {
		for mask in 0 .. states { next[mask] = 0 }
		for mask in 0 .. states {
			count := ways[mask]
			if count == 0 { continue }
			next[mask] += count
			for person in 0 .. int(people) {
				bit := 1 << person
				allowed := unsafe { input[person + 2] }
				if (mask & bit) == 0 && (allowed & (i64(1) << task)) != 0 {
					next[mask | bit] += count
				}
			}
		}
		for mask in 0 .. states { ways[mask] = next[mask] }
	}
	return ways[states - 1]
}
