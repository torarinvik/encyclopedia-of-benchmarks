module longest_common_prefix

fn compare_strings(input &i64, start_a int, len_a int, start_b int, len_b int) int {
	limit := if len_a < len_b { len_a } else { len_b }
	for i in 0 .. limit {
		a := unsafe { input[start_a + i] }; b := unsafe { input[start_b + i] }
		if a < b { return -1 }; if a > b { return 1 }
	}
	if len_a < len_b { return -1 }; if len_a > len_b { return 1 }; return 0
}

@[export: 'longest_common_prefix']
pub fn longest_common_prefix(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length == 0 || length > 1041 { return -1 }
	if unsafe { input[0] < 0 || input[0] > 16 } { return -1 }
	count := int(unsafe { input[0] })
	mut starts := [16]int{}
	mut sizes := [16]int{}
	mut position := 1
	for i in 0 .. count {
		if position >= int(length) { return -1 }
		value := unsafe { input[position] }
		if value < 0 || value > 64 { return -1 }
		sizes[i] = int(value); position++
		if sizes[i] > int(length) - position { return -1 }
		starts[i] = position
		for j in 0 .. sizes[i] {
			b := unsafe { input[position + j] }
			if b < 0 || b > 127 { return -1 }
		}
		position += sizes[i]
	}
	if position != int(length) { return -1 }
	if count == 0 { return 0 }
	mut order := [16]int{}
	for i in 0 .. count { order[i] = i }
	for i := 1; i < count; i++ {
		value := order[i]; mut j := i
		for j > 0 && compare_strings(input, starts[order[j - 1]], sizes[order[j - 1]], starts[value], sizes[value]) > 0 {
			order[j] = order[j - 1]; j--
		}
		order[j] = value
	}
	first := order[0]; last := order[count - 1]
	limit := if sizes[first] < sizes[last] { sizes[first] } else { sizes[last] }
	mut prefix := 0
	for prefix < limit && unsafe { input[starts[first] + prefix] == input[starts[last] + prefix] } { prefix++ }
	if capacity < usize(prefix) || (prefix > 0 && unsafe { output == nil }) { return -2 }
	for i in 0 .. prefix { unsafe { output[i] = u8(input[starts[first] + i]) } }
	return i64(prefix)
}
