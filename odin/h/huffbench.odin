package huffbench

import "core:c"

MIN_PASSES :: i64(1)
MAX_PASSES :: i64(30)
DATA_BYTES :: 4096
OUTPUT_CAPACITY :: 52

heap_adjust :: proc(frequency: [^]uint, heap: [^]uint, active, input_index: int) {
	index := input_index
	value := heap[index-1]
	for index <= active/2 {
		child := index * 2
		if child < active && frequency[heap[child-1]] > frequency[heap[child]] { child += 1 }
		if frequency[value] < frequency[heap[child-1]] do break
		heap[index-1] = heap[child-1]
		index = child
	}
	heap[index-1] = value
}

random4 :: proc(seed: ^i64) -> uint {
	seed^ ^= 123459876
	quotient := seed^ / 127773
	seed^ = 16807 * (seed^ - quotient * 127773) - 2836 * quotient
	if seed^ < 0 { seed^ += 2147483647 }
	result := uint(seed^ % 32)
	seed^ ^= 123459876
	return result
}

compdecomp :: proc(data: [^]u8, compressed_length: ^uint, checksum: ^u32) -> bool {
	frequency: [512]uint
	heap: [256]uint
	link: [512]int
	code: [256]u32
	code_length: [256]u8
	for index in 0..<DATA_BYTES { frequency[data[index]] += 1 }
	active := 0
	for symbol in 0..<256 {
		if frequency[symbol] != 0 { heap[active] = uint(symbol); active += 1 }
	}
	for index := active; index > 0; index -= 1 { heap_adjust(&frequency[0], &heap[0], active, index) }
	for active > 1 {
		active -= 1
		first := heap[0]
		heap[0] = heap[active]
		heap_adjust(&frequency[0], &heap[0], active, 1)
		parent := 256 + active
		frequency[parent] = frequency[heap[0]] + frequency[first]
		link[first] = parent
		link[heap[0]] = -parent
		heap[0] = uint(parent)
		heap_adjust(&frequency[0], &heap[0], active, 1)
	}
	link[256+active] = 0
	for symbol in 0..<256 {
		if frequency[symbol] == 0 { continue }
		depth := 0
		bit: u32 = 1
		value: u32 = 0
		parent := link[symbol]
		for parent != 0 {
			if parent < 0 { value += bit; parent = -parent }
			parent = link[parent]
			bit <<= 1
			depth += 1
		}
		code[symbol] = value
		code_length[symbol] = u8(depth)
	}
	compressed: [DATA_BYTES+1]u8
	compressed_used: uint = 0
	bout: u8 = 0
	bit_index := -1
	for index in 0..<DATA_BYTES {
		mask := u32(1) << (code_length[data[index]]-1)
		for _ in 0..<int(code_length[data[index]]) {
			if bit_index == 7 {
				compressed[compressed_used] = bout
				compressed_used += 1
				bit_index = 0
				bout = 0
			} else { bit_index += 1; bout <<= 1 }
			if (code[data[index]] & mask) != 0 { bout |= 1 }
			mask >>= 1
		}
	}
	bout <<= u8(7-bit_index)
	compressed[compressed_used] = bout
	compressed_used += 1
	children: [512][2]int
	decoded_symbol: [512]int
	for node in 0..<512 { children[node][0] = -1; children[node][1] = -1; decoded_symbol[node] = -1 }
	node_count := 1
	for symbol in 0..<256 {
		if frequency[symbol] == 0 { continue }
		node := 0
		for bit := int(code_length[symbol])-1; bit >= 0; bit -= 1 {
			direction := int((code[symbol] >> u32(bit)) & 1)
			if children[node][direction] < 0 { children[node][direction] = node_count; node_count += 1 }
			node = children[node][direction]
		}
		decoded_symbol[node] = symbol
	}
	decoded: uint = 0
	sum: u64 = 0
	node := 0
	for index in 0..<int(compressed_used) {
		for bit := 7; bit >= 0 && decoded < DATA_BYTES; bit -= 1 {
			direction := int((compressed[index] >> u8(bit)) & 1)
			node = children[node][direction]
			if node < 0 { return false }
			if decoded_symbol[node] >= 0 {
				data[decoded] = u8(decoded_symbol[node])
				sum += u64(data[decoded])
				decoded += 1
				node = 0
			}
		}
	}
	if decoded != DATA_BYTES { return false }
	compressed_length^ = compressed_used
	checksum^ = u32(sum)
	return true
}

append_decimal :: proc(staged: [^]u8, used_input: uint, value_input: u32) -> uint {
	used := used_input
	value := value_input
	reversed: [10]u8
	digits := 0
	for {
		reversed[digits] = u8(48 + value%10)
		digits += 1
		value /= 10
		if value == 0 do break
	}
	for digits > 0 { digits -= 1; staged[used] = reversed[digits]; used += 1 }
	return used
}

format_output :: proc(passes: i64, compressed_length: uint, checksum: u32, staged: [^]u8) -> uint {
	prefix := "Huffbench passes="
	middle := " compressed="
	suffix := " checksum="
	used: uint = 0
	for index := 0; index < len(prefix); index += 1 { staged[used] = prefix[index]; used += 1 }
	used = append_decimal(staged, used, u32(passes))
	for index := 0; index < len(middle); index += 1 { staged[used] = middle[index]; used += 1 }
	used = append_decimal(staged, used, u32(compressed_length))
	for index := 0; index < len(suffix); index += 1 { staged[used] = suffix[index]; used += 1 }
	used = append_decimal(staged, used, checksum)
	staged[used] = 10
	return used + 1
}

@(export, link_name="coyote_huffbench")
coyote_huffbench :: proc "c" (passes: i64, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if passes < MIN_PASSES || passes > MAX_PASSES do return -1
	if output == nil do return -2
	alphabet := "ABCDEFGHIJKLMNOPQRSTUVWXYZ012345"
	data: [DATA_BYTES]u8
	seed: i64 = 1325
	for index in 0..<DATA_BYTES { data[index] = alphabet[random4(&seed)] }
	compressed_length: uint = 0
	checksum: u32 = 0
	for _ in 0..<int(passes) { if !compdecomp(&data[0], &compressed_length, &checksum) do return -1 }
	staged: [OUTPUT_CAPACITY]u8
	used := format_output(passes, compressed_length, checksum, &staged[0])
	if output_capacity < c.size_t(used) do return -2
	for index in 0..<used { output[index] = staged[index] }
	return i64(used)
}
