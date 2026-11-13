package indexed_block_list

import "core:c"

B :: 4
MAX_INITIAL :: 16
MAX_OPS :: 64
MAX_INSERTS :: 32
MAX_ACCESSES :: 32
MAX_NODES :: 16
MAX_ITEMS :: 48
MAX_PARSEABLE :: 179
STRIDE :: 9

ibl_insert :: proc(blocks: ^[MAX_NODES * STRIDE]i64, sizes: ^[MAX_NODES]int,
		next: ^[MAX_NODES]int, node_count: ^int, index: int, value: i64) {
	node, offset := 0, 0
	for next[node] >= 0 && index > offset + sizes[node] { offset += sizes[node]; node = next[node] }
	local := index - offset
	for j := sizes[node]; j > local; j -= 1 { blocks[node*STRIDE+j] = blocks[node*STRIDE+j-1] }
	blocks[node*STRIDE+local] = value
	sizes[node] += 1
	if sizes[node] > 2*B {
		fresh := node_count^
		node_count^ += 1
		first := sizes[node] - B
		for j := 0; j < B; j += 1 { blocks[fresh*STRIDE+j] = blocks[node*STRIDE+first+j] }
		sizes[fresh] = B
		sizes[node] -= B
		next[fresh] = next[node]
		next[node] = fresh
	}
}

ibl_get :: proc(blocks: ^[MAX_NODES * STRIDE]i64, sizes: ^[MAX_NODES]int,
		next: ^[MAX_NODES]int, index: int) -> i64 {
	node, offset := 0, 0
	for index >= offset + sizes[node] { offset += sizes[node]; node = next[node] }
	return blocks[node*STRIDE+index-offset]
}

@(export)
indexed_block_list :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_PARSEABLE || input[0] < 0 || input[0] > MAX_INITIAL do return -1
	initial := int(input[0])
	if int(length) < initial + 2 do return -1
	for i := 0; i < initial; i += 1 { if input[1+i] < -1000000 || input[1+i] > 1000000 do return -1 }
	raw_ops := input[1+initial]
	if raw_ops < 0 || raw_ops > MAX_OPS do return -1
	cursor := initial + 2
	size := initial
	inserts, accesses := 0, 0
	for op := 0; op < int(raw_ops); op += 1 {
		if cursor >= int(length) do return -1
		if input[cursor] == 0 {
			if cursor + 3 > int(length) do return -1
			index, value := input[cursor+1], input[cursor+2]
			if index < 0 || index > i64(size) || value < -1000000 || value > 1000000 do return -1
			inserts += 1
			if inserts > MAX_INSERTS do return -1
			size += 1
			cursor += 3
		} else if input[cursor] == 1 {
			if cursor + 2 > int(length) do return -1
			index := input[cursor+1]
			if index < 0 || index >= i64(size) do return -1
			accesses += 1
			if accesses > MAX_ACCESSES do return -1
			cursor += 2
		} else do return -1
	}
	if cursor != int(length) || size > MAX_ITEMS do return -1
	if accesses == 0 do return 0
	required := accesses * 8
	if output == nil || int(output_capacity) < required do return -2

	blocks: [MAX_NODES*STRIDE]i64
	sizes: [MAX_NODES]int
	next: [MAX_NODES]int
	for i := 0; i < MAX_NODES; i += 1 { next[i] = -1 }
	node_count := 1
	for i := 0; i < initial; i += 1 { ibl_insert(&blocks, &sizes, &next, &node_count, i, input[1+i]) }
	cursor = initial + 2
	operation_count := int(input[1+initial])
	answers: [MAX_ACCESSES]i64
	answer_count := 0
	for op := 0; op < operation_count; op += 1 {
		opcode := input[cursor]
		index := int(input[cursor+1])
		if opcode == 0 { ibl_insert(&blocks, &sizes, &next, &node_count, index, input[cursor+2]); cursor += 3 }
		else { answers[answer_count] = ibl_get(&blocks, &sizes, &next, index); answer_count += 1; cursor += 2 }
	}
	for i := 0; i < answer_count; i += 1 {
		bits := u64(answers[i])
		for b := 0; b < 8; b += 1 { output[i*8+b] = u8((bits >> u64(8*b)) & 255) }
	}
	return i64(required)
}
