package unrolled_linked_list

@(export, link_name="unrolled_linked_list_benchmark")
unrolled_linked_list_benchmark :: proc "c" (values: [^]i64, length: uint) -> i64 {
	if length > 1024 do return -1
	chunks: [512][5]i64
	counts: [512]uint
	next: [512]uint
	for i: uint = 0; i < 512; i += 1 { next[i] = 512 }
	blocks: uint = 0
	for i: uint = 0; i < length; i += 1 {
		value := values[i]
		if value < -1000000 || value > 1000000 do return -1
		if blocks == 0 { blocks = 1; counts[0] = 1; chunks[0][0] = value }
		else if counts[blocks - 1] < 4 { chunks[blocks - 1][counts[blocks - 1]] = value; counts[blocks - 1] += 1 }
		else {
			tail := blocks - 1
			keep := counts[tail] / 2 + 1
			moved := counts[tail] - keep
			for j: uint = 0; j < moved; j += 1 { chunks[blocks][j] = chunks[tail][keep + j] }
			counts[tail] = keep; chunks[blocks][moved] = value; counts[blocks] = moved + 1; next[tail] = blocks; blocks += 1
		}
	}
	checksum: i64 = 0; index: uint = 0
	b: uint = 0
	for b < 512 { for j: uint = 0; j < counts[b]; j += 1 { checksum += i64(index + 1) * (chunks[b][j] + 1000000); index += 1 }; if next[b] == 512 do break; b = next[b] }
	return checksum
}

main :: proc() {}
