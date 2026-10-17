module reverse_k_group

const max_n = 256

@[export: 'reverse_k_group']
pub fn reverse_k_group(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 2 || length > max_n + 2 { return -1 }
	n_value := unsafe { input[0] }
	k_value := unsafe { input[1] }
	if n_value < 0 || n_value > max_n || k_value < 1 || k_value > max_n { return -1 }
	n := int(n_value)
	k := int(k_value)
	if length != usize(n + 2) { return -1 }
	output_bytes := 8 * n
	if output == nil || capacity < usize(output_bytes) { return -2 }

	mut nodes := [max_n]i64{}
	mut next := [max_n + 1]int{}
	mut head := -1
	for i in 0 .. n {
		unsafe { nodes[i] = input[i + 2] }
		next[i] = -1
		if head < 0 { head = i }
		else {
			mut tail := head
			for next[tail] >= 0 { tail = next[tail] }
			next[tail] = i
		}
	}
	mut remaining := 0
	mut node := head
	for node >= 0 {
		remaining++
		node = next[node]
	}
	dummy := max_n
	next[dummy] = head
	mut previous := dummy
	for remaining >= k {
		current := next[previous]
		mut moved := next[current]
		for step := 1; step < k; step++ {
			next[current] = next[moved]
			next[moved] = next[previous]
			next[previous] = moved
			moved = next[current]
		}
		previous = current
		remaining -= k
	}

	mut result := [max_n]i64{}
	mut index := 0
	node = next[dummy]
	for node >= 0 {
		result[index] = nodes[node]
		index++
		node = next[node]
	}
	for i in 0 .. n {
		bits := u64(result[i])
		for byte in 0 .. 8 {
			unsafe { output[i*8+byte] = u8((bits >> (8*byte)) & 255) }
		}
	}
	return i64(output_bytes)
}
