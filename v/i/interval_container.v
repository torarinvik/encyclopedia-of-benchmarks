module interval_container

const max_operations = 24
const record_width = 3
const max_input_values = 73
const max_intervals = 25
const domain_end = i64(32)

struct Interval {
mut:
	left i64
	right i64
}

fn add_interval(mut items [max_intervals]Interval, mut count int, left_in i64, right_in i64) {
	if left_in == right_in {
		return
	}
	mut left := left_in
	mut right := right_in
	mut next := [max_intervals]Interval{}
	mut out := 0
	mut inserted := false
	for i in 0 .. count {
		current := items[i]
		if current.right < left {
			next[out] = current
			out++
		} else if right < current.left {
			if !inserted {
				next[out] = Interval{left: left, right: right}
				out++
				inserted = true
			}
			next[out] = current
			out++
		} else {
			if current.left < left { left = current.left }
			if current.right > right { right = current.right }
		}
	}
	if !inserted {
		next[out] = Interval{left: left, right: right}
		out++
	}
	for i in 0 .. out { items[i] = next[i] }
	count = out
}

fn remove_interval(mut items [max_intervals]Interval, mut count int, left i64, right i64) {
	if left == right {
		return
	}
	mut next := [max_intervals + 1]Interval{}
	mut out := 0
	for i in 0 .. count {
		current := items[i]
		if current.right <= left || current.left >= right {
			next[out] = current
			out++
		} else {
			if current.left < left {
				next[out] = Interval{left: current.left, right: left}
				out++
			}
			if current.right > right {
				next[out] = Interval{left: right, right: current.right}
				out++
			}
		}
	}
	for i in 0 .. out { items[i] = next[i] }
	count = out
}

fn covered_length(items [max_intervals]Interval, count int) i64 {
	mut total := i64(0)
	for i in 0 .. count { total += items[i].right - items[i].left }
	return total
}

fn valid_input(input &i64, length usize) int {
	unsafe {
		if input == nil || length < 1 || length > max_input_values { return -1 }
		if input[0] < 0 || input[0] > max_operations { return -1 }
		operation_count := int(input[0])
		if length != usize(1 + operation_count * record_width) { return -1 }
		for i in 0 .. operation_count {
			offset := 1 + i * record_width
			opcode, left, right := input[offset], input[offset + 1], input[offset + 2]
			if opcode < 0 || opcode > 1 || left < 0 || right < left || right > domain_end {
				return -1
			}
		}
		return operation_count
	}
}

@[export: 'interval_container']
pub fn interval_container(input &i64, length usize) i64 {
	operation_count := valid_input(input, length)
	if operation_count < 0 { return -1 }
	mut items := [max_intervals]Interval{}
	mut count := 0
	mut checksum := i64(0)
	unsafe {
		for i in 0 .. operation_count {
			offset := 1 + i * record_width
			opcode, left, right := input[offset], input[offset + 1], input[offset + 2]
			if opcode == 0 { add_interval(mut items, mut count, left, right) }
			else { remove_interval(mut items, mut count, left, right) }
			checksum += i64(i + 1) * covered_length(items, count)
		}
	}
	return checksum
}
