module bpe_tokenizer

// Apply bounded byte-pair merges with first-seen tie-breaking.
@[export: 'bpe_tokenizer']
pub fn bpe_tokenizer(values &i64, length usize, output &u8, output_capacity usize) i64 {
	unsafe {
		if length < 2 || length > 515 { return -2 }
		merge_count_value := values[0]
		byte_count_value := values[1]
		if merge_count_value < 0 || merge_count_value > 32 || byte_count_value < 0 || byte_count_value > 512 { return -2 }
		byte_count := usize(byte_count_value)
		if length != byte_count + 2 { return -2 }
		mut tokens := [512]i64{}
		mut next_tokens := [512]i64{}
		for index := usize(0); index < byte_count; index++ {
			if values[index + 2] < 0 || values[index + 2] > 255 { return -2 }
			tokens[index] = values[index + 2]
		}
		mut token_count := byte_count
		for step := usize(0); step < usize(merge_count_value) && token_count > 1; step++ {
			mut pair_left := [511]i64{}
			mut pair_right := [511]i64{}
			mut pair_frequency := [511]i64{}
			mut unique_pairs := usize(0)
			for index := usize(0); index + 1 < token_count; index++ {
				mut pair_index := usize(0)
				for pair_index < unique_pairs && (pair_left[pair_index] != tokens[index] || pair_right[pair_index] != tokens[index + 1]) {
					pair_index++
				}
				if pair_index == unique_pairs {
					pair_left[pair_index] = tokens[index]
					pair_right[pair_index] = tokens[index + 1]
					pair_frequency[pair_index] = 1
					unique_pairs++
				} else {
					pair_frequency[pair_index]++
				}
			}
			if unique_pairs == 0 { break }
			mut best := usize(0)
			for index := usize(1); index < unique_pairs; index++ {
				if pair_frequency[index] > pair_frequency[best] { best = index }
			}
			if pair_frequency[best] == 1 { break }
			mut next_count := usize(0)
			mut index := usize(0)
			for index < token_count {
				if index + 1 < token_count && tokens[index] == pair_left[best] && tokens[index + 1] == pair_right[best] {
					next_tokens[next_count] = 256 + i64(step)
					next_count++
					index += 2
				} else {
					next_tokens[next_count] = tokens[index]
					next_count++
					index++
				}
			}
			for item := usize(0); item < next_count; item++ { tokens[item] = next_tokens[item] }
			token_count = next_count
		}
		if token_count * 2 > output_capacity { return -2 }
		if token_count != 0 && isnil(output) { return -2 }
		for index := usize(0); index < token_count; index++ {
			token := u16(tokens[index])
			output[index * 2] = u8(token & 0xff)
			output[index * 2 + 1] = u8(token >> 8)
		}
		return i64(token_count)
	}
}
