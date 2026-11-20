module inverted_list_bitvector_intersection

const max_domain = 1024
const max_lists = 16
const max_words = 16

@[export: 'inverted_list_bitvector_intersection']
pub fn inverted_list_bitvector_intersection(input &i64, length usize,
	mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 258 { return -1 }
		domain_value := input[0]
		list_count_value := input[1]
		if domain_value < 1 || domain_value > max_domain || list_count_value < 1 || list_count_value > max_lists {
			return -1
		}

		domain := int(domain_value)
		list_count := int(list_count_value)
		words_per_list := (domain + 63) / 64
		if length != usize(2 + list_count * words_per_list) { return -1 }

		remainder := domain % 64
		if remainder != 0 {
			valid_mask := (u64(1) << remainder) - 1
			for list in 0 .. list_count {
				final_index := 2 + list * words_per_list + words_per_list - 1
				final_word := u64(input[final_index])
				if (final_word & ~valid_mask) != 0 { return -1 }
			}
		}

		mut intersection := [max_words]u64{}
		for word in 0 .. words_per_list {
			mut combined := ~u64(0)
			for list in 0 .. list_count {
				input_index := 2 + list * words_per_list + word
				combined &= u64(input[input_index])
			}
			intersection[word] = combined
		}

		mut results := [max_domain]i64{}
		mut result_count := 0
		for document_id in 0 .. domain {
			bit := u64(1) << (document_id % 64)
			if (intersection[document_id / 64] & bit) != 0 {
				results[result_count] = i64(document_id)
				result_count++
			}
		}

		output_bytes := (result_count + 1) * 8
		if output == nil || output_capacity < usize(output_bytes) { return -2 }
		bits := u64(i64(result_count))
		for byte in 0 .. 8 { output[byte] = u8((bits >> (byte * 8)) & 255) }
		for index in 0 .. result_count {
			bits = u64(results[index])
			for byte in 0 .. 8 {
				output[(index + 1) * 8 + byte] = u8((bits >> (byte * 8)) & 255)
			}
		}
		return i64(output_bytes)
	}
}
