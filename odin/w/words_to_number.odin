package words_to_number

MAX_INPUT :: 128
MAX_TOKENS :: 128

words_to_number_match :: proc "contextless" (input: [^]i64, start, finish: int, word: string) -> bool {
	if finish - start != len(word) do return false
	for offset in 0 .. len(word) {
		value := input[1 + start + offset]
		if value >= 65 && value <= 90 do value += 32
		if value != i64(word[offset]) do return false
	}
	return true
}
words_to_number_word_id :: proc "contextless" (input: [^]i64, start, finish: int) -> i64 {
	if words_to_number_match(input,start,finish,"zero") do return 1
	if words_to_number_match(input,start,finish,"one") do return 2
	if words_to_number_match(input,start,finish,"two") do return 3
	if words_to_number_match(input,start,finish,"three") do return 4
	if words_to_number_match(input,start,finish,"four") do return 5
	if words_to_number_match(input,start,finish,"five") do return 6
	if words_to_number_match(input,start,finish,"six") do return 7
	if words_to_number_match(input,start,finish,"seven") do return 8
	if words_to_number_match(input,start,finish,"eight") do return 9
	if words_to_number_match(input,start,finish,"nine") do return 10
	if words_to_number_match(input,start,finish,"ten") do return 11
	if words_to_number_match(input,start,finish,"eleven") do return 12
	if words_to_number_match(input,start,finish,"twelve") do return 13
	if words_to_number_match(input,start,finish,"thirteen") do return 14
	if words_to_number_match(input,start,finish,"fourteen") do return 15
	if words_to_number_match(input,start,finish,"fifteen") do return 16
	if words_to_number_match(input,start,finish,"sixteen") do return 17
	if words_to_number_match(input,start,finish,"seventeen") do return 18
	if words_to_number_match(input,start,finish,"eighteen") do return 19
	if words_to_number_match(input,start,finish,"nineteen") do return 20
	if words_to_number_match(input,start,finish,"twenty") do return 21
	if words_to_number_match(input,start,finish,"thirty") do return 22
	if words_to_number_match(input,start,finish,"forty") do return 23
	if words_to_number_match(input,start,finish,"fifty") do return 24
	if words_to_number_match(input,start,finish,"sixty") do return 25
	if words_to_number_match(input,start,finish,"seventy") do return 26
	if words_to_number_match(input,start,finish,"eighty") do return 27
	if words_to_number_match(input,start,finish,"ninety") do return 28
	if words_to_number_match(input,start,finish,"hundred") do return 29
	if words_to_number_match(input,start,finish,"thousand") do return 30
	if words_to_number_match(input,start,finish,"million") do return 31
	if words_to_number_match(input,start,finish,"billion") do return 32
	if words_to_number_match(input,start,finish,"trillion") do return 33
	if words_to_number_match(input,start,finish,"and") do return 34
	if words_to_number_match(input,start,finish,"point") do return 35
	if words_to_number_match(input,start,finish,"negative") do return 36
	return 0
}
words_to_number_value :: proc "contextless" (id: i64) -> i64 {
	if id >= 1 && id <= 20 do return id - 1
	if id >= 21 && id <= 28 do return (id - 19) * 10
	return -1
}
words_to_number_digits :: proc "contextless" (value: i64) -> int {
	x := value
	digits := 1
	for x >= 10 { x /= 10; digits += 1 }
	return digits
}
words_to_number_append_uint :: proc "contextless" (text: [^]u8, at: ^int, value: i64) {
	reversed: [24]u8
	used := 0
	x := value
	for {
		reversed[used] = u8(48 + x % 10)
		used += 1
		x /= 10
		if x == 0 do break
	}
	for used > 0 { used -= 1; text[at^] = reversed[used]; at^ += 1 }
}
words_to_number_is_separator :: proc "contextless" (value: i64) -> bool { return value == 32 || value == 44 || value == 45 }

words_to_number_parse :: proc "contextless" (input: [^]i64, byte_count: int, text: [^]u8, text_len: ^int) -> i64 {
	tokens: [MAX_TOKENS]i64
	count := 0
	start := MAX_INPUT + 1
	for i in 0 .. byte_count {
		value := input[i + 1]
		if value < 32 || value > 126 do return -1
		if words_to_number_is_separator(value) {
			if start != MAX_INPUT + 1 {
				if count >= MAX_TOKENS do return -1
				tokens[count] = words_to_number_word_id(input,start,i)
				count += 1
				start = MAX_INPUT + 1
			}
		} else if start == MAX_INPUT + 1 { start = i }
	}
	if start != MAX_INPUT + 1 {
		if count >= MAX_TOKENS do return -1
		tokens[count] = words_to_number_word_id(input,start,byte_count)
		count += 1
	}
	if count == 0 do return -3
	negative := tokens[0] == 36
	pos := 0
	if negative do pos = 1
	chunks: [MAX_TOKENS]i64
	chunk_count := 0
	current: i64 = 0
	prev_hundred := false
	prev_scale := false
	fraction: [16]u8
	fraction_len := 0
	has_point := false
	for i in pos .. count {
		id := tokens[i]
		if id == 34 {
			if i + 1 >= count do return -10
			value := words_to_number_value(tokens[i + 1])
			after: i64 = -1
			if i + 2 < count do after = tokens[i + 2]
			if (!prev_hundred && !prev_scale) || value < 0 || !(value >= 10 || after == -1 || after == 35) do return -10
			continue
		}
		if id == 29 {
			if current >= 10 || prev_scale do return -5
			if current == 0 do current = 1
			current *= 100
			prev_hundred = true
			continue
		}
		prev_hundred = false
		if id >= 30 && id <= 33 {
			if current == 0 || prev_scale do return -5
			scale: i64 = 1000
			if id == 31 do scale = 1000000
			else if id == 32 do scale = 1000000000
			else if id == 33 do scale = 1000000000000
			next := current * scale
			if chunk_count > 0 && words_to_number_digits(chunks[chunk_count - 1]) <= words_to_number_digits(next) do return -5
			chunks[chunk_count] = next
			chunk_count += 1
			current = 0
			prev_scale = true
			continue
		}
		prev_scale = false
		value := words_to_number_value(id)
		if value >= 0 {
			if value == 0 && !(current == 0 && chunk_count == 0) do return -5
			if current != 0 && words_to_number_digits(current) <= words_to_number_digits(value) do return -5
			current += value
			continue
		}
		if id == 35 {
			if current != 0 { chunks[chunk_count] = current; chunk_count += 1 }
			current = 0
			has_point = true
			word_count := 0
			for j in i + 1 .. count {
				digit := words_to_number_value(tokens[j])
				if digit < 0 do return -6
				word_count += 1
				if word_count > 3 do return -1
				words_to_number_append_uint(&fraction[0], &fraction_len, digit)
			}
			if word_count == 0 do return -7
			break
		}
		if id == 36 { if negative do return -8; return -9 }
		return -4
	}
	if current != 0 { chunks[chunk_count] = current; chunk_count += 1 }
	total: i64 = 0
	for i in 0 .. chunk_count { total += chunks[i] }
	fraction_nonzero := false
	for i in 0 .. fraction_len { if fraction[i] != 48 do fraction_nonzero = true }
	out := 0
	if negative && (total != 0 || fraction_nonzero) { text[out] = 45; out += 1 }
	words_to_number_append_uint(text, &out, total)
	if has_point { text[out] = 46; out += 1; for i in 0 .. fraction_len { text[out] = fraction[i]; out += 1 } }
	text_len^ = out
	return 0
}

@(export, link_name="words_to_number")
words_to_number :: proc "c" (input: [^]i64, length: uint, output: [^]u8, capacity: uint) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT + 1 do return -1
	n := input[0]
	if n < 0 || n > MAX_INPUT || length != uint(n + 1) do return -1
	text: [64]u8
	text_len := 0
	status := words_to_number_parse(input,int(n),&text[0],&text_len)
	if status != 0 do return status
	if output == nil || capacity < uint(text_len) do return -2
	for i in 0 .. text_len { output[i] = text[i] }
	return i64(text_len)
}
main :: proc() {}
