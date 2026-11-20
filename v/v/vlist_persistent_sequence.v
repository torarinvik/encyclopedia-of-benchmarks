module vlist_persistent_sequence

const max_q = 48
const max_cons = 32
const max_roots = 49
const max_blocks = 6
const max_slots = 63
const max_parseable = 146

struct VListBlock {
	previous_block int
	previous_offset int
	capacity int
	last_used int
	base int
}

fn list_length(blocks &[max_blocks]VListBlock, root_block &[max_roots]int,
	root_offset &[max_roots]int, root int) i64 {
	unsafe {
		mut block_id := root_block[root]
		mut offset := root_offset[root]
		mut total := i64(0)
		for block_id >= 0 {
			if block_id >= max_blocks || offset < 0 || offset > blocks[block_id].last_used { return -1 }
			total += i64(offset + 1)
			previous := blocks[block_id].previous_block
			offset = blocks[block_id].previous_offset
			block_id = previous
		}
		return total
	}
}

fn list_nth(blocks &[max_blocks]VListBlock, data &[max_slots]i64,
	root_block &[max_roots]int, root_offset &[max_roots]int, root int, index int) i64 {
	unsafe {
		mut block_id := root_block[root]
		mut offset := root_offset[root]
		mut remaining := index
		for block_id >= 0 {
			if block_id >= max_blocks || offset < 0 || offset > blocks[block_id].last_used { return -1000001 }
			if remaining <= offset { return data[blocks[block_id].base + offset - remaining] }
			remaining -= offset + 1
			previous := blocks[block_id].previous_block
			offset = blocks[block_id].previous_offset
			block_id = previous
		}
		return -1000001
	}
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for i in 0 .. 8 {
		unsafe { output[offset + i] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'vlist_persistent_sequence']
pub fn vlist_persistent_sequence(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_parseable { return -1 }
		q_word := input[0]
		if q_word < 1 || q_word > max_q || length != usize(1 + 3 * q_word) { return -1 }
		q := int(q_word)
		mut blocks := [max_blocks]VListBlock{}
		mut data := [max_slots]i64{}
		mut root_block := [max_roots]int{}
		mut root_offset := [max_roots]int{}
		mut results := [max_q]i64{}
		for i in 0 .. max_roots { root_block[i] = -1; root_offset[i] = -1 }
		mut block_count := 0
		mut root_count := 1
		mut slot_count := 0
		mut cons_count := 0
		mut query_phase := false
		mut at := 1
		for op in 0 .. q {
			tag := input[at]
			root_word := input[at + 1]
			arg := input[at + 2]
			at += 3
			if tag < 0 || tag > 3 || root_word < 0 || root_word >= i64(root_count) { return -1 }
			root := int(root_word)
			if tag == 0 {
				if query_phase || root != root_count - 1 || cons_count >= max_cons || arg < -1000000 || arg > 1000000 { return -1 }
				mut block_id := root_block[root]
				mut offset := root_offset[root]
				if block_id < 0 {
					if cons_count != 0 || block_count != 0 || slot_count >= max_slots { return -1 }
					blocks[block_count] = VListBlock{-1, -1, 1, 0, slot_count}
					data[slot_count] = arg
					block_id = block_count
					offset = 0
					block_count++
					slot_count++
				} else {
					if block_id >= block_count || offset != blocks[block_id].last_used { return -1 }
					if offset + 1 < blocks[block_id].capacity {
						offset++
						data[blocks[block_id].base + offset] = arg
						blocks[block_id].last_used = offset
					} else {
						next_capacity := blocks[block_id].capacity * 2
						if block_count >= max_blocks || slot_count + next_capacity > max_slots { return -1 }
						blocks[block_count] = VListBlock{block_id, offset, next_capacity, 0, slot_count}
						data[slot_count] = arg
						block_id = block_count
						offset = 0
						block_count++
						slot_count += next_capacity
					}
				}
				if root_count >= max_roots { return -1 }
				root_block[root_count] = block_id
				root_offset[root_count] = offset
				results[op] = i64(root_count)
				root_count++
				cons_count++
			} else {
				query_phase = true
				if tag == 1 {
					if arg != -1 || list_length(&blocks, &root_block, &root_offset, root) <= 0 { return -1 }
					mut block_id := root_block[root]
					mut offset := root_offset[root]
					if offset > 0 { offset-- } else { offset = blocks[block_id].previous_offset; block_id = blocks[block_id].previous_block }
					if root_count >= max_roots { return -1 }
					root_block[root_count] = block_id
					root_offset[root_count] = offset
					results[op] = i64(root_count)
					root_count++
				} else if tag == 2 {
					n := list_length(&blocks, &root_block, &root_offset, root)
					if n < 0 || arg < 0 || arg >= n { return -1 }
					value := list_nth(&blocks, &data, &root_block, &root_offset, root, int(arg))
					if value == -1000001 { return -1 }
					results[op] = value
				} else {
					if arg != -1 { return -1 }
					n := list_length(&blocks, &root_block, &root_offset, root)
					if n < 0 { return -1 }
					results[op] = n
				}
			}
		}
		bytes := q * 8
		if output == nil || capacity < usize(bytes) { return -2 }
		for i in 0 .. q { store_i64_le(mut output, i * 8, results[i]) }
		return i64(bytes)
	}
}
