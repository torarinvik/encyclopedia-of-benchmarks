module bm25_inverted_index

// Build a bounded term-to-document table and rank one query by BM25.
@[export: 'bm25_inverted_index']
pub fn bm25_inverted_index(values &i64, length usize, output &u8, output_capacity usize) i64 {
	unsafe {
		if length < 2 || length > 2114 || values[0] < 0 || values[0] > 32 { return -2 }
		document_count := usize(values[0])
		if values[length - 1] < 1 || values[length - 1] > 255 { return -2 }
		query := values[length - 1]
		mut frequency := [32]i64{}
		mut document_length := [32]i64{}
		mut document_id := [32]i64{}
		mut seen_ids := [256]bool{}
		mut offset := usize(1)
		mut total_terms := i64(0)
		for document := usize(0); document < document_count; document++ {
			if offset + 2 > length - 1 { return -2 }
			id := values[offset]
			term_count_value := values[offset + 1]
			offset += 2
			if id < 0 || id > 255 || term_count_value < 0 || term_count_value > 64 { return -2 }
			id_index := usize(id)
			term_count := usize(term_count_value)
			if seen_ids[id_index] || term_count > length - 1 - offset { return -2 }
			seen_ids[id_index] = true
			document_id[document] = id
			document_length[document] = term_count_value
			total_terms += term_count_value
			for _ in 0 .. term_count {
				term := values[offset]
				offset++
				if term < 1 || term > 255 { return -2 }
				if term == query { frequency[document]++ }
			}
		}
		if offset != length - 1 { return -2 }
		mut result_id := [32]i64{}
		mut result_tf := [32]i64{}
		mut result_denominator := [32]i64{}
		mut result_count := usize(0)
		for document := usize(0); document < document_count; document++ {
			tf := frequency[document]
			if tf == 0 { continue }
			denominator := 8 * total_terms * tf + 3 * total_terms + 9 * i64(document_count) * document_length[document]
			mut position := result_count
			for position > 0 {
				previous := position - 1
				left := tf * result_denominator[previous]
				right := result_tf[previous] * denominator
				if left < right || (left == right && document_id[document] > result_id[previous]) { break }
				result_id[position] = result_id[previous]
				result_tf[position] = result_tf[previous]
				result_denominator[position] = result_denominator[previous]
				position--
			}
			result_id[position] = document_id[document]
			result_tf[position] = tf
			result_denominator[position] = denominator
			result_count++
		}
		if result_count > output_capacity { return -2 }
		for index := usize(0); index < result_count; index++ { output[index] = u8(result_id[index]) }
		return i64(result_count)
	}
}
