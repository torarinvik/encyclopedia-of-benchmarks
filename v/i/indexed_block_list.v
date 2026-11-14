module indexed_block_list

const block_size = 4
const max_initial = 16
const max_ops = 64
const max_inserts = 32
const max_accesses = 32
const max_nodes = 16
const max_items = 48
const max_parseable = 179
const stride = 9

fn ibl_insert(mut blocks []i64, mut sizes []int, mut next []int, mut node_count int, index int, value i64) {
	mut node := 0
	mut offset := 0
	for next[node] >= 0 && index > offset + sizes[node] {
		offset += sizes[node]
		node = next[node]
	}
	local := index - offset
	mut j := sizes[node]
	for j > local { blocks[node * stride + j] = blocks[node * stride + j - 1]; j-- }
	blocks[node * stride + local] = value
	sizes[node]++
	if sizes[node] > 2 * block_size {
		fresh := node_count
		node_count++
		first := sizes[node] - block_size
		for k in 0 .. block_size { blocks[fresh * stride + k] = blocks[node * stride + first + k] }
		sizes[fresh] = block_size
		sizes[node] -= block_size
		next[fresh] = next[node]
		next[node] = fresh
	}
}

fn ibl_get(blocks []i64, sizes []int, next []int, index int) i64 {
	mut node := 0
	mut offset := 0
	for index >= offset + sizes[node] { offset += sizes[node]; node = next[node] }
	return blocks[node * stride + index - offset]
}

@[export: 'indexed_block_list']
pub fn indexed_block_list(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_parseable { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > max_initial { return -1 }
		initial := int(input[0])
		if length < usize(initial + 2) { return -1 }
		for i in 0 .. initial { if input[1 + i] < -1000000 || input[1 + i] > 1000000 { return -1 } }
		raw_ops := input[1 + initial]
		if raw_ops < 0 || raw_ops > max_ops { return -1 }
		mut cursor := initial + 2
		mut size := initial
		mut inserts := 0
		mut accesses := 0
		for _ in 0 .. int(raw_ops) {
			if cursor >= int(length) { return -1 }
			if input[cursor] == 0 {
				if cursor + 3 > int(length) { return -1 }
				index := input[cursor + 1]
				value := input[cursor + 2]
				if index < 0 || index > i64(size) || value < -1000000 || value > 1000000 { return -1 }
				inserts++
				if inserts > max_inserts { return -1 }
				size++
				cursor += 3
			} else if input[cursor] == 1 {
				if cursor + 2 > int(length) { return -1 }
				index := input[cursor + 1]
				if index < 0 || index >= i64(size) { return -1 }
				accesses++
				if accesses > max_accesses { return -1 }
				cursor += 2
			} else { return -1 }
		}
		if cursor != int(length) || size > max_items { return -1 }
		required := accesses * 8
		if required > 0 && (output == nil || output_capacity < usize(required)) { return -2 }
		mut blocks := [max_nodes * stride]i64{}
		mut sizes := [max_nodes]int{}
		mut next := [max_nodes]int{}
		for i in 0 .. max_nodes { next[i] = -1 }
		mut node_count := 1
		for i in 0 .. initial { ibl_insert(mut blocks[..], mut sizes[..], mut next[..], mut node_count, i, input[1 + i]) }
		operation_count := int(raw_ops)
		cursor = initial + 2
		mut answers := [max_accesses]i64{}
		mut answer_count := 0
		for _ in 0 .. operation_count {
			opcode := input[cursor]
			index := int(input[cursor + 1])
			if opcode == 0 {
				ibl_insert(mut blocks[..], mut sizes[..], mut next[..], mut node_count, index, input[cursor + 2])
				cursor += 3
			} else {
				answers[answer_count] = ibl_get(blocks[..], sizes[..], next[..], index)
				answer_count++
				cursor += 2
			}
		}
		for i in 0 .. answer_count {
			bits := u64(answers[i])
			for b in 0 .. 8 { output[i * 8 + b] = u8((bits >> u64(8 * b)) & 255) }
		}
		return i64(required)
	}
}
