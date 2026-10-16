package bm25_inverted_index

import "core:c"

// Build a bounded term-to-document table and rank one query by BM25.
@(export)
bm25_inverted_index :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 2 || length > 2114 || values[0] < 0 || values[0] > 32 do return -2
	document_count := c.size_t(values[0])
	if values[length - 1] < 1 || values[length - 1] > 255 do return -2
	query := values[length - 1]
	frequency: [32]i64
	document_length: [32]i64
	document_id: [32]i64
	seen_ids: [256]bool
	offset := c.size_t(1)
	total_terms := i64(0)
	for document: c.size_t = 0; document < document_count; document += 1 {
		if offset + 2 > length - 1 do return -2
		id := values[offset]
		term_count := values[offset + 1]
		offset += 2
		if id < 0 || id > 255 || term_count < 0 || term_count > 64 do return -2
		id_index := c.size_t(id)
		term_count_size := c.size_t(term_count)
		if seen_ids[id_index] || term_count_size > length - 1 - offset do return -2
		seen_ids[id_index] = true
		document_id[document] = id
		document_length[document] = term_count
		total_terms += term_count
		for item: c.size_t = 0; item < term_count_size; item += 1 {
			term := values[offset]
			offset += 1
			if term < 1 || term > 255 do return -2
			if term == query do frequency[document] += 1
		}
	}
	if offset != length - 1 do return -2
	result_id: [32]i64
	result_tf: [32]i64
	result_denominator: [32]i64
	result_count := c.size_t(0)
	for document: c.size_t = 0; document < document_count; document += 1 {
		tf := frequency[document]
		if tf == 0 do continue
		denominator := 8 * total_terms * tf + 3 * total_terms + 9 * i64(document_count) * document_length[document]
		position := result_count
		for position > 0 {
			previous := position - 1
			left := tf * result_denominator[previous]
			right := result_tf[previous] * denominator
			if left < right || (left == right && document_id[document] > result_id[previous]) do break
			result_id[position] = result_id[previous]
			result_tf[position] = result_tf[previous]
			result_denominator[position] = result_denominator[previous]
			position -= 1
		}
		result_id[position] = document_id[document]
		result_tf[position] = tf
		result_denominator[position] = denominator
		result_count += 1
	}
	if result_count > output_capacity || (result_count != 0 && output == nil) do return -2
	for index: c.size_t = 0; index < result_count; index += 1 {
		output[index] = u8(result_id[index])
	}
	return i64(result_count)
}
