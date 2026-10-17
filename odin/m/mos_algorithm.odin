package mos_algorithm

import "core:c"

MAX_N :: 256
MAX_Q :: 256
MAX_INPUT_LENGTH :: 1029
FNV_OFFSET :: u64(0xcbf29ce484222325)
FNV_PRIME :: u64(0x100000001b3)

hash_byte :: proc(hash: u64, byte: u8) -> u64 { return (hash ^ u64(byte)) * FNV_PRIME }

query_before :: proc(a, b: int, lefts, rights: [^]i32, block_size: int) -> bool {
	block_a, block_b := lefts[a] / i32(block_size), lefts[b] / i32(block_size)
	if block_a != block_b do return block_a < block_b
	if (block_a & 1) != 0 do return rights[a] < rights[b]
	return rights[a] > rights[b]
}

hash_results :: proc(operation: u8, count: int, results: [^]i32) -> i64 {
	hash := FNV_OFFSET
	hash = hash_byte(hash, operation)
	hash = hash_byte(hash, u8(count))
	hash = hash_byte(hash, u8(count >> 8))
	for index := 0; index < count; index += 1 {
		bits := transmute(u32(results[index]))
		for shift := 0; shift < 32; shift += 8 { hash = hash_byte(hash, u8(bits >> u32(shift))) }
	}
	return i64(hash & 0x7fffffffffffffff)
}

mos_algorithm :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT_LENGTH do return -1
	operation, n64, q64, target64 := input[0], input[1], input[2], input[3]
	if (operation != 0 && operation != 1) || n64 < 1 || n64 > MAX_N || q64 < 0 || q64 > MAX_Q || target64 < -1_000_000 || target64 > 1_000_000
		|| length != c.size_t(4 + n64 + 3 * q64) do return -1
	n, q := int(n64), int(q64)
	target := i32(target64)
	var values: [MAX_N]i32
	for index := 0; index < n; index += 1 {
		value := input[4+index]
		if value < -1_000_000 || value > 1_000_000 do return -1
		values[index] = i32(value)
	}
	var lefts: [MAX_Q]i32
	var rights: [MAX_Q]i32
	var indices: [MAX_Q]i32
	var order: [MAX_Q]int
	var seen: [MAX_Q]bool
	offset := 4 + n
	for query := 0; query < q; query += 1 {
		left, right, index := input[offset+3*query], input[offset+3*query+1], input[offset+3*query+2]
		if left < 0 || right < left || right >= n64 || index < 0 || index >= q64 do return -1
		if seen[int(index)] do return -1
		lefts[query], rights[query], indices[query] = i32(left), i32(right), i32(index)
		seen[int(index)] = true
		order[query] = query
	}
	block_size := 1
	for (block_size + 1) * (block_size + 1) <= n { block_size += 1 }
	for query := 1; query < q; query += 1 {
		current := order[query]
		position := query
		for position > 0 && query_before(current, order[position-1], &lefts[0], &rights[0], block_size) {
			order[position] = order[position-1]
			position -= 1
		}
		order[position] = current
	}
	var results: [MAX_Q]i32
	current_left, current_right, aggregate := 0, -1, 0
	for sorted := 0; sorted < q; sorted += 1 {
		query := order[sorted]
		left, right := lefts[query], rights[query]
		if operation == 0 {
			for current_right < right { current_right += 1; aggregate += values[current_right] }
			for current_right > right { aggregate -= values[current_right]; current_right -= 1 }
			for current_left < left { aggregate -= values[current_left]; current_left += 1 }
			for current_left > left { current_left -= 1; aggregate += values[current_left] }
		} else {
			for current_right < right { current_right += 1; if values[current_right] == target { aggregate += 1 } }
			for current_right > right { if values[current_right] == target { aggregate -= 1 }; current_right -= 1 }
			for current_left < left { if values[current_left] == target { aggregate -= 1 }; current_left += 1 }
			for current_left > left { current_left -= 1; if values[current_left] == target { aggregate += 1 } }
		}
		results[int(indices[query])] = i32(aggregate)
	}
	return hash_results(u8(operation), q, &results[0])
}
