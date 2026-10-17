package solution42

import "core:c"

MAX_INPUT_LENGTH :: 16_384

is_triangle_score :: proc "contextless" (score: i64) -> bool {
	for n in 1..=100 { if i64(n*(n+1)/2) == score do return true }
	return false
}

count_first_line :: proc "contextless" (bytes: [^]u8, length: int) -> i64 {
	line_end := length
	for index in 0..<length {
		if bytes[index] == 13 || bytes[index] == 10 { line_end = index; break }
	}
	count := i64(0)
	token_start := 0
	position := 0
	for position <= line_end {
		if position != line_end && bytes[position] != u8(',') { position += 1; continue }
		start, finish := token_start, position
		for start < finish && bytes[start] == u8('"') { start += 1 }
		for start < finish && bytes[finish-1] == u8('"') { finish -= 1 }
		score := i64(0)
		for index in start..<finish { score += i64(bytes[index])-64 }
		if is_triangle_score(score) { count += 1 }
		token_start = position+1
		position += 1
	}
	return count
}

solution42 :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if length > MAX_INPUT_LENGTH do return -1
	if input == nil {
		if length == 0 do return 0
		return -1
	}
	if length == 0 do return 0
	var bytes: [MAX_INPUT_LENGTH]u8
	for index in 0..<int(length) {
		value := input[index]
		if value < 0 || value > 127 do return -1
		bytes[index] = u8(value)
	}
	return count_first_line(&bytes[0], int(length))
}
