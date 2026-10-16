module words_to_number

const max_input = 128
const max_tokens = 128

fn words_to_number_matches(input &i64, start int, finish int, word string) bool {
	if finish - start != word.len { return false }
	for offset in 0 .. word.len {
		mut value := unsafe { input[1 + start + offset] }
		if value >= 65 && value <= 90 { value += 32 }
		if value != i64(word[offset]) { return false }
	}
	return true
}
fn words_to_number_word_id(input &i64, start int, finish int) i64 {
	if words_to_number_matches(input,start,finish,'zero') { return 1 }
	if words_to_number_matches(input,start,finish,'one') { return 2 }
	if words_to_number_matches(input,start,finish,'two') { return 3 }
	if words_to_number_matches(input,start,finish,'three') { return 4 }
	if words_to_number_matches(input,start,finish,'four') { return 5 }
	if words_to_number_matches(input,start,finish,'five') { return 6 }
	if words_to_number_matches(input,start,finish,'six') { return 7 }
	if words_to_number_matches(input,start,finish,'seven') { return 8 }
	if words_to_number_matches(input,start,finish,'eight') { return 9 }
	if words_to_number_matches(input,start,finish,'nine') { return 10 }
	if words_to_number_matches(input,start,finish,'ten') { return 11 }
	if words_to_number_matches(input,start,finish,'eleven') { return 12 }
	if words_to_number_matches(input,start,finish,'twelve') { return 13 }
	if words_to_number_matches(input,start,finish,'thirteen') { return 14 }
	if words_to_number_matches(input,start,finish,'fourteen') { return 15 }
	if words_to_number_matches(input,start,finish,'fifteen') { return 16 }
	if words_to_number_matches(input,start,finish,'sixteen') { return 17 }
	if words_to_number_matches(input,start,finish,'seventeen') { return 18 }
	if words_to_number_matches(input,start,finish,'eighteen') { return 19 }
	if words_to_number_matches(input,start,finish,'nineteen') { return 20 }
	if words_to_number_matches(input,start,finish,'twenty') { return 21 }
	if words_to_number_matches(input,start,finish,'thirty') { return 22 }
	if words_to_number_matches(input,start,finish,'forty') { return 23 }
	if words_to_number_matches(input,start,finish,'fifty') { return 24 }
	if words_to_number_matches(input,start,finish,'sixty') { return 25 }
	if words_to_number_matches(input,start,finish,'seventy') { return 26 }
	if words_to_number_matches(input,start,finish,'eighty') { return 27 }
	if words_to_number_matches(input,start,finish,'ninety') { return 28 }
	if words_to_number_matches(input,start,finish,'hundred') { return 29 }
	if words_to_number_matches(input,start,finish,'thousand') { return 30 }
	if words_to_number_matches(input,start,finish,'million') { return 31 }
	if words_to_number_matches(input,start,finish,'billion') { return 32 }
	if words_to_number_matches(input,start,finish,'trillion') { return 33 }
	if words_to_number_matches(input,start,finish,'and') { return 34 }
	if words_to_number_matches(input,start,finish,'point') { return 35 }
	if words_to_number_matches(input,start,finish,'negative') { return 36 }
	return 0
}
fn words_to_number_value(id i64) i64 {
	if id >= 1 && id <= 20 { return id - 1 }
	if id >= 21 && id <= 28 { return (id - 19) * 10 }
	return -1
}
fn words_to_number_digits(value i64) int {
	mut x := value
	mut digits := 1
	for x >= 10 { x /= 10; digits++ }
	return digits
}
fn words_to_number_append_uint(text &u8, mut at int, value i64) {
	mut reversed := [24]u8{}
	mut used := 0
	mut x := value
	for {
		reversed[used] = u8(48 + x % 10)
		used++
		x /= 10
		if x == 0 { break }
	}
	for used > 0 { used--; unsafe { text[at] = reversed[used] }; at++ }
}
fn words_to_number_separator(value i64) bool { return value == 32 || value == 44 || value == 45 }

fn words_to_number_parse(input &i64, byte_count int, text &u8) i64 {
	mut tokens := [max_tokens]i64{}
	mut count := 0
	mut start := max_input + 1
	for i in 0 .. byte_count {
		value := unsafe { input[i + 1] }
		if value < 32 || value > 126 { return -1 }
		if words_to_number_separator(value) {
			if start != max_input + 1 {
				if count >= max_tokens { return -1 }
				tokens[count] = words_to_number_word_id(input,start,i)
				count++
				start = max_input + 1
			}
		} else if start == max_input + 1 { start = i }
	}
	if start != max_input + 1 {
		if count >= max_tokens { return -1 }
		tokens[count] = words_to_number_word_id(input,start,byte_count)
		count++
	}
	if count == 0 { return -3 }
	negative := tokens[0] == 36
	mut pos := 0
	if negative { pos = 1 }
	mut chunks := [max_tokens]i64{}
	mut chunk_count := 0
	mut current := i64(0)
	mut prev_hundred := false
	mut prev_scale := false
	mut fraction := [16]u8{}
	mut fraction_len := 0
	mut has_point := false
	for i in pos .. count {
		id := tokens[i]
		if id == 34 {
			if i + 1 >= count { return -10 }
			value := words_to_number_value(tokens[i + 1])
			after := if i + 2 < count { tokens[i + 2] } else { i64(-1) }
			if (!prev_hundred && !prev_scale) || value < 0 || !(value >= 10 || after == -1 || after == 35) { return -10 }
			continue
		}
		if id == 29 {
			if current >= 10 || prev_scale { return -5 }
			if current == 0 { current = 1 }
			current *= 100
			prev_hundred = true
			continue
		}
		prev_hundred = false
		if id >= 30 && id <= 33 {
			if current == 0 || prev_scale { return -5 }
			mut scale := i64(1000)
			if id == 31 { scale = 1000000 } else if id == 32 { scale = 1000000000 } else if id == 33 { scale = 1000000000000 }
			next := current * scale
			if chunk_count > 0 && words_to_number_digits(chunks[chunk_count - 1]) <= words_to_number_digits(next) { return -5 }
			chunks[chunk_count] = next
			chunk_count++
			current = 0
			prev_scale = true
			continue
		}
		prev_scale = false
		value := words_to_number_value(id)
		if value >= 0 {
			if value == 0 && !(current == 0 && chunk_count == 0) { return -5 }
			if current != 0 && words_to_number_digits(current) <= words_to_number_digits(value) { return -5 }
			current += value
			continue
		}
		if id == 35 {
			if current != 0 { chunks[chunk_count] = current; chunk_count++ }
			current = 0
			has_point = true
			mut word_count := 0
			for j in i + 1 .. count {
				digit := words_to_number_value(tokens[j])
				if digit < 0 { return -6 }
				word_count++
				if word_count > 3 { return -1 }
				mut at := fraction_len
				words_to_number_append_uint(&fraction[0], mut at, digit)
				fraction_len = at
			}
			if word_count == 0 { return -7 }
			break
		}
		if id == 36 { if negative { return -8 } else { return -9 } }
		return -4
	}
	if current != 0 { chunks[chunk_count] = current; chunk_count++ }
	mut total := i64(0)
	for i in 0 .. chunk_count { total += chunks[i] }
	mut fraction_nonzero := false
	for i in 0 .. fraction_len { if fraction[i] != 48 { fraction_nonzero = true } }
	mut out := 0
	if negative && (total != 0 || fraction_nonzero) { unsafe { text[out] = 45 }; out++ }
	words_to_number_append_uint(text, mut out, total)
	if has_point {
		unsafe { text[out] = 46 }
		out++
		for i in 0 .. fraction_len { unsafe { text[out] = fraction[i] }; out++ }
	}
	return i64(out)
}

@[export: 'words_to_number']
pub fn words_to_number(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input + 1 { return -1 }
	n := unsafe { input[0] }
	if n < 0 || n > max_input || length != usize(n + 1) { return -1 }
	mut text := [64]u8{}
	text_len := words_to_number_parse(input, int(n), &text[0])
	if text_len < 0 { return text_len }
	if unsafe { output == nil } || capacity < usize(text_len) { return -2 }
	for i in 0 .. int(text_len) { unsafe { output[i] = text[i] } }
	return text_len
}
