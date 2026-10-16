const max_docs = 256
const max_words_per_doc = 256
const max_total_words = 4096
const max_query_terms = 16
const max_input = 4627
const fnv_offset = u64(14695981039346656037)
const fnv_prime = u64(1099511628211)

fn hash_i64(mut hash u64, value i64) u64 {
	bits := u64(value)
	for shift in 0 .. 8 { hash = (hash ^ u64(u8(bits >> (shift * 8)))) * fnv_prime }
	return hash
}

@[export: 'inverted_index']
pub fn inverted_index(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 3 || length > max_input { return -1 }
	doc_count64 := unsafe { input[0] }
	if doc_count64 < 0 || doc_count64 > max_docs { return -1 }
	doc_count := int(doc_count64)
	mut seen_docs := [max_docs]bool{}
	mut posting_heads := [65536]int{}
	mut posting_next := [max_total_words]int{}
	mut posting_doc := [max_total_words]u8{}
	for word in 0 .. 65536 { posting_heads[word] = -1 }
	mut posting_count := 0
	mut total_words := 0
	mut cursor := 1

	for _ in 0 .. doc_count {
		if cursor > length || length - cursor < 2 { return -1 }
		doc_id64 := unsafe { input[cursor] }
		word_count64 := unsafe { input[cursor + 1] }
		cursor += 2
		if doc_id64 < 0 || doc_id64 >= max_docs || word_count64 < 1 || word_count64 > max_words_per_doc { return -1 }
		doc_id := int(doc_id64)
		word_count := int(word_count64)
		if seen_docs[doc_id] || word_count > length - cursor || total_words > max_total_words - word_count { return -1 }
		seen_docs[doc_id] = true
		total_words += word_count
		for _ in 0 .. word_count {
			word64 := unsafe { input[cursor] }
			cursor++
			if word64 < 0 || word64 > 65535 { return -1 }
			word_id := int(word64)
			mut duplicate := false
			mut edge := posting_heads[word_id]
			for edge >= 0 {
				if int(posting_doc[edge]) == doc_id { duplicate = true; break }
				edge = posting_next[edge]
			}
			if !duplicate {
				if posting_count >= max_total_words { return -1 }
				posting_doc[posting_count] = u8(doc_id)
				posting_next[posting_count] = posting_heads[word_id]
				posting_heads[word_id] = posting_count
				posting_count++
			}
		}
	}
	if cursor > length || length - cursor < 2 { return -1 }
	operation := unsafe { input[cursor] }
	term_count64 := unsafe { input[cursor + 1] }
	cursor += 2
	if (operation != 0 && operation != 1) || term_count64 < 1 || term_count64 > max_query_terms || int(term_count64) != length - cursor { return -1 }
	term_count := int(term_count64)
	mut terms := [max_query_terms]int{}
	for i in 0 .. term_count {
		term64 := unsafe { input[cursor + i] }
		if term64 < 0 || term64 > 65535 { return -1 }
		terms[i] = int(term64)
	}

	mut result_flags := [max_docs]bool{}
	mut term_flags := [max_docs]bool{}
	for doc_id in 0 .. max_docs { result_flags[doc_id] = operation == 0 && seen_docs[doc_id] }
	for t in 0 .. term_count {
		for doc_id in 0 .. max_docs { term_flags[doc_id] = false }
		mut edge := posting_heads[terms[t]]
		for edge >= 0 {
			term_flags[int(posting_doc[edge])] = true
			edge = posting_next[edge]
		}
		for doc_id in 0 .. max_docs {
			if operation == 0 { result_flags[doc_id] = result_flags[doc_id] && term_flags[doc_id] }
			else { result_flags[doc_id] = result_flags[doc_id] || term_flags[doc_id] }
		}
	}
	mut result_ids := [max_docs]i64{}
	mut result_count := 0
	for doc_id in 0 .. max_docs {
		if result_flags[doc_id] { result_ids[result_count] = i64(doc_id); result_count++ }
	}
	mut hash := hash_i64(fnv_offset, i64(result_count))
	for i in 0 .. result_count { hash = hash_i64(hash, result_ids[i]) }
	return i64(hash & u64(0x7fffffffffffffff))
}
