package inverted_list_bitvector_intersection

import "core:c"

MAX_DOMAIN :: 1024
MAX_LISTS :: 16
MAX_WORDS :: 16

write_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8((bits >> (byte * 8)) & 255)
	}
}

@(export)
inverted_list_bitvector_intersection :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 258 do return -1
	domain_value, list_count_value := input[0], input[1]
	if domain_value < 1 || domain_value > MAX_DOMAIN || list_count_value < 1 || list_count_value > MAX_LISTS do return -1

	domain, list_count := int(domain_value), int(list_count_value)
	words_per_list := (domain + 63) / 64
	if length != c.size_t(2 + list_count * words_per_list) do return -1

	remainder := domain % 64
	if remainder != 0 {
		valid_mask := (u64(1) << remainder) - 1
		for list := 0; list < list_count; list += 1 {
			final_index := 2 + list * words_per_list + words_per_list - 1
			final_word := transmute(u64)input[final_index]
			if (final_word & ~valid_mask) != 0 do return -1
		}
	}

	intersection: [MAX_WORDS]u64 = {}
	for word := 0; word < words_per_list; word += 1 {
		combined := ~u64(0)
		for list := 0; list < list_count; list += 1 {
			input_index := 2 + list * words_per_list + word
			combined &= transmute(u64)input[input_index]
		}
		intersection[word] = combined
	}

	results: [MAX_DOMAIN]i64 = {}
	result_count := 0
	for document_id := 0; document_id < domain; document_id += 1 {
		bit := u64(1) << (document_id % 64)
		if (intersection[document_id/64] & bit) != 0 {
			results[result_count] = i64(document_id)
			result_count += 1
		}
	}

	output_bytes := (result_count + 1) * 8
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2
	write_i64_le(output, 0, i64(result_count))
	for index := 0; index < result_count; index += 1 {
		write_i64_le(output, (index+1)*8, results[index])
	}
	return i64(output_bytes)
}
