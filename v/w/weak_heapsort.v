module weak_heapsort

const max_values = 256
const max_input_length = 258

fn reverse_offset(flag bool) int {
	return if flag { 1 } else { 0 }
}

fn distinguished_ancestor(mut node int, mut reverse [max_values]bool) int {
	for node > 0 {
		parent := node / 2
		if (node % 2 == 0 && !reverse[parent]) || (node % 2 == 1 && reverse[parent]) {
			node = parent
		} else {
			break
		}
	}
	return node / 2
}

fn join(mut values [max_values]i64, mut reverse [max_values]bool, ancestor int, node int) {
	if values[ancestor] < values[node] {
		values[ancestor], values[node] = values[node], values[ancestor]
		reverse[node] = !reverse[node]
	}
}

fn sift_down(mut values [max_values]i64, mut reverse [max_values]bool, active_size int) {
	mut node := if reverse[0] { 0 } else { 1 }
	if node >= active_size { return }
	for 2 * node + reverse_offset(reverse[node]) < active_size {
		node = 2 * node + reverse_offset(reverse[node])
	}
	for node != 0 {
		join(mut values, mut reverse, 0, node)
		node /= 2
	}
}

@[export: 'weak_heapsort']
pub fn weak_heapsort(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_input_length { return -1 }
		count64 := input[0]
		if count64 < 0 || count64 > max_values || int(length) != int(count64) + 1 { return -1 }
		count := int(count64)
		mut values := [max_values]i64{}
		mut reverse := [max_values]bool{}
		for index in 0 .. count {
			value := input[index + 1]
			if value < -1000 || value > 1000 { return -1 }
			values[index] = value
		}
		mut node := count - 1
		for node > 0 {
			ancestor := distinguished_ancestor(mut node, mut reverse)
			join(mut values, mut reverse, ancestor, node)
			node--
		}
		mut active_size := count
		for active_size > 1 {
			values[0], values[active_size - 1] = values[active_size - 1], values[0]
			active_size--
			sift_down(mut values, mut reverse, active_size)
		}
		mut checksum := i64(0)
		for index in 0 .. count {
			checksum += i64(index + 1) * (values[index] + 1001)
		}
		return checksum
	}
}
