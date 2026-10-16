module map_reduce

const max_input = 256
const max_words = 128
const table_size = 512

fn is_space_byte(value i64) bool {
	return value == 9 || value == 10 || value == 11 || value == 12 || value == 13 || value == 32
}

fn token_hash(input &i64, start int, length int) int {
	mut hash := 0
	for offset in 0 .. length {
		hash = (hash * 31 + int(unsafe { input[start + offset] })) % 1_000_003
	}
	return hash
}

fn token_equal(input &i64, start int, length int, other_start int, other_length int) bool {
	if length != other_length { return false }
	for offset in 0 .. length {
		if unsafe { input[start + offset] != input[other_start + offset] } { return false }
	}
	return true
}

fn write_count(mut output &u8, mut position &int, count int) {
	mut digits := [3]u8{}
	mut digit_count := 0
	mut remaining := count
	for {
		digits[digit_count] = u8(48 + remaining % 10)
		digit_count++
		remaining /= 10
		if remaining == 0 { break }
	}
	for digit_count > 0 {
		digit_count--
		unsafe { output[position] = digits[digit_count] }
		position++
	}
}

@[export: 'map_reduce']
pub fn map_reduce(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length > max_input || (length > 0 && unsafe { input == nil }) { return -1 }
	unsafe {
		for index in 0 .. int(length) {
			value := input[index]
			if !is_space_byte(value) && (value < 32 || value > 126) { return -1 }
		}
		mut starts := [max_words]usize{}
		mut lengths := [max_words]usize{}
		mut counts := [max_words]usize{}
		mut table := [table_size]usize{}
		mut unique_count := 0
		mut begin := 0
		mut ending := int(length)
		for begin < ending && input[begin] <= 32 { begin++ }
		for ending > begin && input[ending - 1] <= 32 { ending-- }

		if begin == ending {
			starts[0] = 0; lengths[0] = 0; counts[0] = 1; unique_count = 1
			table[0] = 1
		} else {
			mut cursor := begin
			for cursor < ending {
				for cursor < ending && is_space_byte(input[cursor]) { cursor++ }
				if cursor == ending { break }
				start := cursor
				for cursor < ending && !is_space_byte(input[cursor]) { cursor++ }
				token_length := cursor - start
				mut slot := token_hash(input, start, token_length) % table_size
				for table[slot] != 0 {
					item := int(table[slot] - 1)
					if token_equal(input, start, token_length, int(starts[item]), int(lengths[item])) {
						counts[item]++
						break
					}
					slot = (slot + 1) % table_size
				}
				if table[slot] == 0 {
					starts[unique_count] = usize(start); lengths[unique_count] = usize(token_length)
					counts[unique_count] = 1; table[slot] = usize(unique_count + 1); unique_count++
				}
			}
		}

		mut required := 0
		for item in 0 .. unique_count {
			mut digits := 1
			mut value := counts[item]
			for value >= 10 { value /= 10; digits++ }
			required += int(lengths[item]) + 2 + digits
			if item != 0 { required++ }
		}
		if output == nil || output_capacity < usize(required) { return -2 }

		mut written := 0
		for item in 0 .. unique_count {
			if item != 0 { output[written] = `,`; written++ }
			for offset in 0 .. int(lengths[item]) {
				output[written] = u8(input[int(starts[item]) + offset]); written++
			}
			output[written] = `:`; written++
			output[written] = ` `; written++
			write_count(mut output, mut written, int(counts[item]))
		}
		return i64(written)
	}
}
