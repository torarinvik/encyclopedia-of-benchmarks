module point_set_range_sort_range_composite

const modulus = i64(998244353)
const max_length = usize(210)

struct Record {
	priority i64
	a i64
	b i64
}

@[export: 'point_set_range_sort_range_composite']
pub fn point_set_range_sort_range_composite(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_length { return -1 }
	n_value := unsafe { input[0] }
	q_value := unsafe { input[1] }
	if n_value < 1 || n_value > 16 || q_value < 1 || q_value > 32 { return -1 }
	n := int(n_value)
	q := int(q_value)
	if int(length) < 2 + 3 * n { return -1 }
	mut records := [16]Record{}
	mut seen := [48]i64{}
	mut seen_count := 0
	mut cursor := 2
	for i in 0 .. n {
		p := unsafe { input[cursor] }
		a := unsafe { input[cursor + 1] }
		b := unsafe { input[cursor + 2] }
		cursor += 3
		if p < 0 || p > 1_000_000_000 || a < 1 || a >= modulus || b < 0 || b >= modulus { return -1 }
		for j in 0 .. seen_count { if seen[j] == p { return -1 } }
		seen[seen_count] = p
		seen_count++
		records[i] = Record{priority: p, a: a, b: b}
	}
	mut checksum := i64(0)
	mut query_number := i64(0)
	for _ in 0 .. q {
		if cursor >= int(length) { return -1 }
		opcode := unsafe { input[cursor] }
		cursor++
		if opcode == 0 {
			if int(length) - cursor < 4 { return -1 }
			index := unsafe { input[cursor] }
			p := unsafe { input[cursor + 1] }
			a := unsafe { input[cursor + 2] }
			b := unsafe { input[cursor + 3] }
			cursor += 4
			if index < 0 || index >= n_value || p < 0 || p > 1_000_000_000 || a < 1 || a >= modulus || b < 0 || b >= modulus { return -1 }
			for j in 0 .. seen_count { if seen[j] == p { return -1 } }
			seen[seen_count] = p
			seen_count++
			records[int(index)] = Record{priority: p, a: a, b: b}
		} else if opcode == 1 {
			if int(length) - cursor < 3 { return -1 }
			left := unsafe { input[cursor] }
			right := unsafe { input[cursor + 1] }
			x := unsafe { input[cursor + 2] }
			cursor += 3
			if left < 0 || left >= right || right > n_value || x < 0 || x >= modulus { return -1 }
			mut answer := x
			for i := int(left); i < int(right); i++ { answer = (records[i].a * answer + records[i].b) % modulus }
			query_number++
			checksum = (checksum + query_number * answer) % modulus
		} else if opcode == 2 || opcode == 3 {
			if int(length) - cursor < 2 { return -1 }
			left := unsafe { input[cursor] }
			right := unsafe { input[cursor + 1] }
			cursor += 2
			if left < 0 || left >= right || right > n_value { return -1 }
			for i := int(left) + 1; i < int(right); i++ {
				item := records[i]
				mut j := i
				for j > int(left) && ((opcode == 2 && records[j - 1].priority > item.priority) || (opcode == 3 && records[j - 1].priority < item.priority)) {
					records[j] = records[j - 1]
					j--
				}
				records[j] = item
			}
		} else { return -1 }
	}
	if cursor != int(length) { return -1 }
	return checksum
}
