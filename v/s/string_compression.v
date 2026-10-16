module string_compression

@[export: 'string_compression']
pub fn string_compression(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length > 64 || (length > 0 && unsafe { input == nil }) { return -1 }
	for index := usize(0); index < length; index++ {
		value := unsafe { input[index] }
		if value < 0 || value > 127 { return -1 }
	}

	mut encoded_length := usize(0)
	mut index := usize(0)
	for index < length {
		mut ending := index + 1
		for ending < length && unsafe { input[ending] == input[index] } { ending++ }
		count := ending - index
		encoded_length++
		if count > 1 {
			if count >= 10 { encoded_length += 2 } else { encoded_length++ }
		}
		index = ending
	}
	if output_capacity < encoded_length || (encoded_length > 0 && unsafe { output == nil }) { return -2 }

	mut write_index := usize(0)
	index = 0
	for index < length {
		mut ending := index + 1
		for ending < length && unsafe { input[ending] == input[index] } { ending++ }
		count := ending - index
		unsafe { output[write_index] = u8(input[index]) }
		write_index++
		if count > 1 {
			if count >= 10 {
				unsafe { output[write_index] = u8(48 + count / 10) }
				write_index++
			}
			unsafe { output[write_index] = u8(48 + count % 10) }
			write_index++
		}
		index = ending
	}
	return i64(write_index)
}
