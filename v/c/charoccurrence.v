module main

const max_input = 128
const max_output = 1024

fn append_decimal(mut buffer &u8, mut offset int, value int) int {
	mut digits := [3]u8{}
	mut count := 0
	mut remaining := value
	for {
		digits[count] = u8(48 + remaining % 10)
		count++
		remaining /= 10
		if remaining == 0 { break }
	}
	for count > 0 {
		count--
		unsafe { buffer[offset] = digits[count] }
		offset++
	}
	return offset
}

@[export: 'charoccurrence']
pub fn charoccurrence(values &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if length > max_input { return -1 }
		if length > 0 && values == nil { return -1 }
		mut counts := [128]int{}
		for index in 0 .. int(length) {
			value := values[index]
			if value < 0 || value > 127 { return -1 }
			counts[int(value)]++
		}
		mut encoded := [max_output]u8{}
		mut used := 0
		for codepoint in 0 .. 128 {
			count := counts[codepoint]
			if count == 0 { continue }
			if used > 0 {
				encoded[used] = u8(',')
				used++
			}
			used = append_decimal(mut encoded[0], used, codepoint)
			encoded[used] = u8('=')
			used++
			used = append_decimal(mut encoded[0], used, count)
		}
		if used > capacity { return -2 }
		if used > 0 && output == nil { return -2 }
		for index in 0 .. used { output[index] = encoded[index] }
		return i64(used)
	}
}
