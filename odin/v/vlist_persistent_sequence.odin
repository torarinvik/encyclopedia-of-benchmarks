package vlist_persistent_sequence

import "core:c"

MAX_Q :: 48
MAX_CONS :: 32
MAX_ROOTS :: 49
MAX_BLOCKS :: 6
MAX_SLOTS :: 63
MAX_PARSEABLE :: 146

Block :: struct {
	previous_block: int,
	previous_offset: int,
	capacity: int,
	last_used: int,
	base: int,
}

list_length :: proc "contextless" (blocks: [^]Block, block_count: int,
								root_block, root_offset: [^]int, root: int) -> i64 {
	block_id := root_block[root]
	offset := root_offset[root]
	total := i64(0)
	for block_id >= 0 {
		if block_id >= block_count || offset < 0 || offset > blocks[block_id].last_used do return -1
		total += i64(offset + 1)
		previous := blocks[block_id].previous_block
		offset = blocks[block_id].previous_offset
		block_id = previous
	}
	return total
}

list_nth :: proc "contextless" (blocks: [^]Block, data: [^]i64,
								root_block, root_offset: [^]int, root, index: int) -> i64 {
	block_id := root_block[root]
	offset := root_offset[root]
	remaining := index
	for block_id >= 0 {
		if block_id >= MAX_BLOCKS || offset < 0 || offset > blocks[block_id].last_used do return -1000001
		if remaining <= offset do return data[blocks[block_id].base + offset - remaining]
		remaining -= offset + 1
		previous := blocks[block_id].previous_block
		offset = blocks[block_id].previous_offset
		block_id = previous
	}
	return -1000001
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
vlist_persistent_sequence :: proc "c" (input: [^]i64, length: c.size_t,
										output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE) do return -1
	q_word := input[0]
	if q_word < 1 || q_word > MAX_Q || length != c.size_t(1 + 3 * q_word) do return -1
	q := int(q_word)

	var blocks: [MAX_BLOCKS]Block
	var data: [MAX_SLOTS]i64
	var root_block: [MAX_ROOTS]int
	var root_offset: [MAX_ROOTS]int
	var results: [MAX_Q]i64
	for i := 0; i < MAX_ROOTS; i += 1 { root_block[i] = -1; root_offset[i] = -1 }
	block_count, root_count, slot_count, cons_count := 0, 1, 0, 0
	query_phase := false
	at := 1
	for op := 0; op < q; op += 1 {
		tag, root_word, arg := input[at], input[at+1], input[at+2]
		at += 3
		if tag < 0 || tag > 3 || root_word < 0 || root_word >= i64(root_count) do return -1
		root := int(root_word)
		if tag == 0 {
			if query_phase || root != root_count-1 || cons_count >= MAX_CONS || arg < -1000000 || arg > 1000000 do return -1
			block_id, offset := root_block[root], root_offset[root]
			if block_id < 0 {
				if cons_count != 0 || block_count != 0 || slot_count >= MAX_SLOTS do return -1
				blocks[block_count] = Block{-1, -1, 1, 0, slot_count}
				data[slot_count] = arg
				block_id, offset = block_count, 0
				block_count += 1
				slot_count += 1
			} else {
				if block_id >= block_count || offset != blocks[block_id].last_used do return -1
				if offset+1 < blocks[block_id].capacity {
					offset += 1
					data[blocks[block_id].base+offset] = arg
					blocks[block_id].last_used = offset
				} else {
					next_capacity := blocks[block_id].capacity * 2
					if block_count >= MAX_BLOCKS || slot_count+next_capacity > MAX_SLOTS do return -1
					blocks[block_count] = Block{block_id, offset, next_capacity, 0, slot_count}
					data[slot_count] = arg
					block_id, offset = block_count, 0
					block_count += 1
					slot_count += next_capacity
				}
			}
			if root_count >= MAX_ROOTS do return -1
			root_block[root_count], root_offset[root_count] = block_id, offset
			results[op] = i64(root_count)
			root_count += 1
			cons_count += 1
		} else {
			query_phase = true
			if tag == 1 {
				if arg != -1 || list_length(&blocks[0], block_count, &root_block[0], &root_offset[0], root) <= 0 do return -1
				block_id, offset := root_block[root], root_offset[root]
				if offset > 0 { offset -= 1 } else { offset = blocks[block_id].previous_offset; block_id = blocks[block_id].previous_block }
				if root_count >= MAX_ROOTS do return -1
				root_block[root_count], root_offset[root_count] = block_id, offset
				results[op] = i64(root_count)
				root_count += 1
			} else if tag == 2 {
				n := list_length(&blocks[0], block_count, &root_block[0], &root_offset[0], root)
				if n < 0 || arg < 0 || arg >= n do return -1
				value := list_nth(&blocks[0], &data[0], &root_block[0], &root_offset[0], root, int(arg))
				if value == -1000001 do return -1
				results[op] = value
			} else {
				if arg != -1 do return -1
				n := list_length(&blocks[0], block_count, &root_block[0], &root_offset[0], root)
				if n < 0 do return -1
				results[op] = n
			}
		}
	}
	bytes := q * 8
	if output == nil || capacity < c.size_t(bytes) do return -2
	for i := 0; i < q; i += 1 { store_i64_le(output, i*8, results[i]) }
	return i64(bytes)
}
