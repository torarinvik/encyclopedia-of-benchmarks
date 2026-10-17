const max_n = 256
const max_q = 256
const max_input_length = 1029
const fnv_offset = u64(14695981039346656037)
const fnv_prime = u64(1099511628211)

fn hash_byte(hash u64, byte u8) u64 {
	return (hash ^ u64(byte)) * fnv_prime
}

fn query_before(a int, b int, lefts &i32, rights &i32, block_size int) bool {
	unsafe {
		block_a := lefts[a] / i32(block_size)
		block_b := lefts[b] / i32(block_size)
		if block_a != block_b { return block_a < block_b }
		if (block_a & 1) != 0 { return rights[a] < rights[b] }
		return rights[a] > rights[b]
	}
}

fn hash_results(operation u8, count int, results &i32) i64 {
	mut hash := hash_byte(fnv_offset, operation)
	hash = hash_byte(hash, u8(count))
	hash = hash_byte(hash, u8(count >> 8))
	unsafe {
		for index in 0 .. count {
			bits := u32(results[index])
			for byte in 0 .. 4 { hash = hash_byte(hash, u8(bits >> (byte * 8))) }
		}
	}
	return i64(hash & u64(0x7fffffffffffffff))
}

@[export: 'mos_algorithm']
pub fn mos_algorithm(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > usize(max_input_length) { return -1 }
		operation, n64, q64, target64 := input[0], input[1], input[2], input[3]
		if (operation != 0 && operation != 1) || n64 < 1 || n64 > i64(max_n) || q64 < 0 || q64 > i64(max_q)
			|| target64 < -1_000_000 || target64 > 1_000_000 || int(length) != 4 + int(n64) + 3 * int(q64) { return -1 }
		n, q := int(n64), int(q64)
		target := i32(target64)
		mut values := [max_n]i32{}
		for index in 0 .. n {
			value := input[4 + index]
			if value < -1_000_000 || value > 1_000_000 { return -1 }
			values[index] = i32(value)
		}
		mut lefts := [max_q]i32{}
		mut rights := [max_q]i32{}
		mut indices := [max_q]i32{}
		mut order := [max_q]int{}
		mut seen := [max_q]bool{}
		offset := 4 + n
		for query in 0 .. q {
			left, right, index := input[offset+3*query], input[offset+3*query+1], input[offset+3*query+2]
			if left < 0 || right < left || right >= n64 || index < 0 || index >= q64 { return -1 }
			if seen[int(index)] { return -1 }
			lefts[query], rights[query], indices[query] = i32(left), i32(right), i32(index)
			seen[int(index)] = true
			order[query] = query
		}
		mut block_size := 1
		for (block_size + 1) * (block_size + 1) <= n { block_size++ }
		for query in 1 .. q {
			current := order[query]
			mut position := query
			for position > 0 && query_before(current, order[position - 1], mut lefts[0], mut rights[0], block_size) {
				order[position] = order[position - 1]
				position--
			}
			order[position] = current
		}
		mut results := [max_q]i32{}
		mut current_left, current_right, aggregate := 0, -1, 0
		for sorted in 0 .. q {
			query := order[sorted]
			left, right := lefts[query], rights[query]
			if operation == 0 {
				for current_right < right { current_right++; aggregate += values[current_right] }
				for current_right > right { aggregate -= values[current_right]; current_right-- }
				for current_left < left { aggregate -= values[current_left]; current_left++ }
				for current_left > left { current_left--; aggregate += values[current_left] }
			} else {
				for current_right < right { current_right++; if values[current_right] == target { aggregate++ } }
				for current_right > right { if values[current_right] == target { aggregate-- }; current_right-- }
				for current_left < left { if values[current_left] == target { aggregate-- }; current_left++ }
				for current_left > left { current_left--; if values[current_left] == target { aggregate++ } }
			}
			results[int(indices[query])] = i32(aggregate)
		}
		return hash_results(u8(operation), q, mut results[0])
	}
}
