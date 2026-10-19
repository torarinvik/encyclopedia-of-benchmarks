module huffbench

const min_passes = i64(1)
const max_passes = i64(30)
const data_bytes = 4096
const output_capacity = 52

fn heap_adjust(frequency []u64, mut heap []u64, active int, one_based int) {
	mut index := one_based
	value := heap[index - 1]
	for index <= active / 2 {
		mut child := index * 2
		if child < active && frequency[heap[child - 1]] > frequency[heap[child]] { child++ }
		if frequency[value] < frequency[heap[child - 1]] { break }
		heap[index - 1] = heap[child - 1]
		index = child
	}
	heap[index - 1] = value
}

fn random4(mut seed i64) int {
	seed ^= 123459876
	quotient := seed / 127773
	seed = 16807 * (seed - quotient * 127773) - 2836 * quotient
	if seed < 0 { seed += 2147483647 }
	result := int(seed % 32)
	seed ^= 123459876
	return result
}

fn compdecomp(mut data []u8) (usize, u32, bool) {
	mut frequency := [512]u64{}
	mut heap := [256]u64{}
	mut link := [512]int{}
	mut code := [256]u32{}
	mut code_length := [256]u8{}
	for value in data { frequency[value]++ }
	mut active := 0
	for symbol in 0 .. 256 {
		if frequency[symbol] != 0 { heap[active] = u64(symbol); active++ }
	}
	for index := active; index > 0; index-- { heap_adjust(frequency[..], mut heap[..], active, index) }
	for active > 1 {
		active--
		first := heap[0]
		heap[0] = heap[active]
		heap_adjust(frequency[..], mut heap[..], active, 1)
		parent := 256 + active
		frequency[parent] = frequency[heap[0]] + frequency[first]
		link[first] = parent
		link[heap[0]] = -parent
		heap[0] = u64(parent)
		heap_adjust(frequency[..], mut heap[..], active, 1)
	}
	link[256 + active] = 0
	for symbol in 0 .. 256 {
		if frequency[symbol] == 0 { continue }
		mut depth := 0
		mut bit := u32(1)
		mut value := u32(0)
		mut parent := link[symbol]
		for parent != 0 {
			if parent < 0 { value += bit; parent = -parent }
			parent = link[parent]
			bit <<= 1
			depth++
		}
		code[symbol] = value
		code_length[symbol] = u8(depth)
	}
	mut compressed := [data_bytes + 1]u8{}
	mut compressed_used := usize(0)
	mut bout := u8(0)
	mut bit_index := -1
	for symbol in data {
		mut mask := u32(1) << (code_length[symbol] - 1)
		for _ in 0 .. int(code_length[symbol]) {
			if bit_index == 7 {
				compressed[compressed_used] = bout
				compressed_used++
				bit_index = 0
				bout = 0
			} else { bit_index++; bout <<= 1 }
			if code[symbol] & mask != 0 { bout |= 1 }
			mask >>= 1
		}
	}
	bout <<= u8(7 - bit_index)
	compressed[compressed_used] = bout
	compressed_used++
	mut children := [512][2]int{}
	mut decoded_symbol := [512]int{}
	for node in 0 .. 512 { children[node][0] = -1; children[node][1] = -1; decoded_symbol[node] = -1 }
	mut node_count := 1
	for symbol in 0 .. 256 {
		if frequency[symbol] == 0 { continue }
		mut node := 0
		for bit := int(code_length[symbol]) - 1; bit >= 0; bit-- {
			direction := int((code[symbol] >> u32(bit)) & 1)
			if children[node][direction] < 0 { children[node][direction] = node_count; node_count++ }
			node = children[node][direction]
		}
		decoded_symbol[node] = symbol
	}
	mut decoded := 0
	mut sum := u64(0)
	mut node := 0
	for index in 0 .. int(compressed_used) {
		for bit := 7; bit >= 0; bit-- {
			if decoded >= data_bytes { break }
			direction := int((compressed[index] >> u8(bit)) & 1)
			node = children[node][direction]
			if node < 0 { return 0, 0, false }
			if decoded_symbol[node] >= 0 {
				data[decoded] = u8(decoded_symbol[node])
				sum += u64(data[decoded])
				decoded++
				node = 0
			}
		}
	}
	if decoded != data_bytes { return 0, 0, false }
	return compressed_used, u32(sum), true
}

fn append_decimal(mut staged []u8, mut used int, mut value u32) int {
	mut reversed := [10]u8{}
	mut digits := 0
	for {
		reversed[digits] = u8(48 + value % 10)
		digits++
		value /= 10
		if value == 0 { break }
	}
	for digits > 0 { digits--; staged[used] = reversed[digits]; used++ }
	return used
}

fn format_output(passes i64, compressed_length usize, checksum u32, mut staged []u8) int {
	mut used := 0
	for byte in 'Huffbench passes='.bytes() { staged[used] = byte; used++ }
	used = append_decimal(mut staged, used, u32(passes))
	for byte in ' compressed='.bytes() { staged[used] = byte; used++ }
	used = append_decimal(mut staged, used, u32(compressed_length))
	for byte in ' checksum='.bytes() { staged[used] = byte; used++ }
	used = append_decimal(mut staged, used, checksum)
	staged[used] = 10
	return used + 1
}

@[export: 'coyote_huffbench']
pub fn coyote_huffbench(passes i64, mut output &u8, output_capacity usize) i64 {
	if passes < min_passes || passes > max_passes { return -1 }
	if unsafe { output == nil } { return -2 }
	alphabet := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ012345'.bytes()
	mut data := [data_bytes]u8{}
	mut seed := i64(1325)
	for index in 0 .. data_bytes { data[index] = alphabet[random4(mut seed)] }
	mut compressed_length := usize(0)
	mut checksum := u32(0)
	for _ in 0 .. int(passes) {
		result := compdecomp(mut data[..])
		if !result[2] { return -1 }
		compressed_length = result[0]
		checksum = result[1]
	}
	mut staged := [output_capacity]u8{}
	used := format_output(passes, compressed_length, checksum, mut staged[..])
	if output_capacity < usize(used) { return -2 }
	unsafe { for index in 0 .. used { output[index] = staged[index] } }
	return i64(used)
}
