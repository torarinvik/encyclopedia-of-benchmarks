module word_count_julia

struct WordEntry {
	start int
	length int
	count int
}

fn lower_byte(input &i64, index int) u8 {
	byte := u8(unsafe { input[index] })
	return if byte >= 65 && byte <= 90 { byte + 32 } else { byte }
}

fn is_word_byte(byte u8) bool {
	return (byte >= 97 && byte <= 122) || (byte >= 48 && byte <= 57) || byte == 95
}

fn compare_word(input &i64, start int, length int, entry WordEntry) int {
	shared := if length < entry.length { length } else { entry.length }
	for offset in 0 .. shared {
		left := lower_byte(input, start + offset)
		right := lower_byte(input, entry.start + offset)
		if left < right { return -1 }
		if left > right { return 1 }
	}
	if length < entry.length { return -1 }
	if length > entry.length { return 1 }
	return 0
}

fn write_count(mut output &u8, mut position &int, count int) {
	mut digits := [4]u8{}
	mut digit_count := 0
	mut remaining := count
	for {
		digits[digit_count] = u8(48 + remaining % 10)
		digit_count++
		remaining /= 10
		if remaining == 0 { break }
	}
	unsafe { output[position] = 61 }
	position++
	for digit_count > 0 {
		digit_count--
		unsafe { output[position] = digits[digit_count] }
		position++
	}
	unsafe { output[position] = 10 }
	position++
}

@[export: 'word_count_julia']
pub fn word_count_julia(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length > 1000 || (length > 0 && unsafe { input == nil }) { return -1 }
	unsafe {
		n := int(length)
		for index in 0 .. n {
			if input[index] < 0 || input[index] > 127 { return -1 }
		}
		mut entries := [1000]WordEntry{}
		mut unique_count := 0
		mut index := 0
		for index < n {
			if !is_word_byte(lower_byte(input, index)) { index++; continue }
			start := index
			for index < n && is_word_byte(lower_byte(input, index)) { index++ }
			mut token_length := index - start
			if index + 1 < n && input[index] == 39 && is_word_byte(lower_byte(input, index + 1)) {
				token_length += 2
				index += 2
			}
			mut position := 0
			for position < unique_count && compare_word(input, start, token_length, entries[position]) > 0 { position++ }
			if position < unique_count && compare_word(input, start, token_length, entries[position]) == 0 {
				entries[position].count++
			} else {
				mut move := unique_count
				for move > position { entries[move] = entries[move - 1]; move-- }
				entries[position] = WordEntry{start: start, length: token_length, count: 1}
				unique_count++
			}
		}
		mut required := 0
		for item in 0 .. unique_count {
			mut digits := 1
			mut value := entries[item].count
			for value >= 10 { value /= 10; digits++ }
			required += entries[item].length + digits + 2
		}
		if output_capacity < usize(required) || (required > 0 && output == nil) { return -2 }
		mut written := 0
		for item in 0 .. unique_count {
			for offset in 0 .. entries[item].length {
				output[written] = lower_byte(input, entries[item].start + offset)
				written++
			}
			write_count(mut output, mut written, entries[item].count)
		}
		return i64(written)
	}
}
