module solution42

const max_input_length = 16384

fn is_triangle_score(score i64) bool {
	for n in 1 .. 101 {
		if i64(n * (n + 1) / 2) == score { return true }
	}
	return false
}

fn count_first_line(bytes []u8) i64 {
	mut line_end := bytes.len
	for index, byte in bytes {
		if byte == 13 || byte == 10 { line_end = index; break }
	}
	mut count := i64(0)
	mut token_start := 0
	mut position := 0
	for position <= line_end {
		if position != line_end && bytes[position] != u8(`,`) { position++; continue }
		mut start, mut finish := token_start, position
		for start < finish && bytes[start] == u8(`"`) { start++ }
		for start < finish && bytes[finish - 1] == u8(`"`) { finish-- }
		mut score := i64(0)
		for index in start .. finish { score += i64(bytes[index]) - 64 }
		if is_triangle_score(score) { count++ }
		token_start = position + 1
		position++
	}
	return count
}

@[export: 'solution42']
pub fn solution42(input &i64, length usize) i64 {
	unsafe {
		if length > usize(max_input_length) { return -1 }
		if input == nil { return if length == 0 { 0 } else { -1 } }
		if length == 0 { return 0 }
		mut bytes := []u8{len: int(length)}
		for index in 0 .. int(length) {
			value := input[index]
			if value < 0 || value > 127 { return -1 }
			bytes[index] = u8(value)
		}
		return count_first_line(bytes)
	}
}
