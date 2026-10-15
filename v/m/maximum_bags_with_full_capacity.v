module maximum_bags_with_full_capacity

fn sift_down(mut values &i64, root usize, finish usize) {
	mut current := root
	for current < finish / 2 {
		mut child := current * 2 + 1
		if child + 1 < finish && unsafe { values[child] < values[child + 1] } {
			child++
		}
		if unsafe { values[current] >= values[child] } { break }
		temporary := unsafe { values[current] }
		unsafe {
			values[current] = values[child]
			values[child] = temporary
		}
		current = child
	}
}

@[export: 'maximum_bags_with_full_capacity']
pub fn maximum_bags_with_full_capacity(input &i64, length usize) i64 {
	if length < 2 || length > 16_384 { return -1 }
	unsafe {
		mut remaining := input[0]
		if remaining < 0 || remaining > 1_000_000_000 { return -1 }
		if input[1] < 0 || input[1] > 8_191 { return -1 }
		count := int(input[1])
		if int(length) != 2 + 2 * count { return -1 }
		mut deficits := [8_191]i64{}
		for index in 0 .. count {
			capacity := input[2 + index]
			rocks := input[2 + count + index]
			if capacity < 1 || capacity > 100_000 || rocks < 0 || rocks > capacity { return -1 }
			deficits[index] = capacity - rocks
		}
		mut start := count / 2
		for start > 0 {
			start--
			sift_down(mut deficits[0], usize(start), usize(count))
		}
		mut finish := count
		for finish > 1 {
			finish--
			temporary := deficits[0]
			deficits[0] = deficits[finish]
			deficits[finish] = temporary
			sift_down(mut deficits[0], 0, usize(finish))
		}
		mut full_bags := i64(0)
		for index in 0 .. count {
			if deficits[index] > remaining { break }
			remaining -= deficits[index]
			full_bags++
		}
		return full_bags
	}
}
