package inverted_index

import "core:c"

FNV_OFFSET :: u64(0xcbf29ce484222325)
FNV_PRIME :: u64(0x100000001b3)

hash_i64 :: proc(hash: u64, value: i64) -> u64 {
	result := hash
	bits := transmute(u64(value))
	for shift := 0; shift < 64; shift += 8 { result = (result ^ u64(u8(bits >> u64(shift)))) * FNV_PRIME }
	return result
}

@(export)
inverted_index :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 4627 do return -1
	doc_count64 := input[0]
	if doc_count64 < 0 || doc_count64 > 256 do return -1
	doc_count := int(doc_count64)
	var seen_docs: [256]bool
	var posting_heads: [65536]i32
	var posting_next: [4096]i32
	var posting_doc: [4096]u8
	for word := 0; word < 65536; word += 1 { posting_heads[word] = -1 }
	posting_count := 0
	total_words, cursor := 0, 1

	for _ := 0; _ < doc_count; _ += 1 {
		if cursor > int(length) || int(length)-cursor < 2 do return -1
		doc_id64, word_count64 := input[cursor], input[cursor+1]
		cursor += 2
		if doc_id64 < 0 || doc_id64 >= 256 || word_count64 < 1 || word_count64 > 256 do return -1
		doc_id, word_count := int(doc_id64), int(word_count64)
		if seen_docs[doc_id] || word_count > int(length)-cursor || total_words > 4096-word_count do return -1
		seen_docs[doc_id] = true
		total_words += word_count
		for _ := 0; _ < word_count; _ += 1 {
			word64 := input[cursor]
			cursor += 1
			if word64 < 0 || word64 > 65535 do return -1
			word_id := int(word64)
			duplicate := false
			edge := posting_heads[word_id]
			for edge >= 0 {
				edge_index := int(edge)
				if int(posting_doc[edge_index]) == doc_id { duplicate = true; break }
				edge = posting_next[edge_index]
			}
			if !duplicate {
				if posting_count >= 4096 do return -1
				posting_doc[posting_count] = u8(doc_id)
				posting_next[posting_count] = posting_heads[word_id]
				posting_heads[word_id] = i32(posting_count)
				posting_count += 1
			}
		}
	}
	if cursor > int(length) || int(length)-cursor < 2 do return -1
	operation, term_count64 := input[cursor], input[cursor+1]
	cursor += 2
	if (operation != 0 && operation != 1) || term_count64 < 1 || term_count64 > 16 || int(term_count64) != int(length)-cursor do return -1
	term_count := int(term_count64)
	var terms: [16]int
	for i := 0; i < term_count; i += 1 {
		term64 := input[cursor+i]
		if term64 < 0 || term64 > 65535 do return -1
		terms[i] = int(term64)
	}
	var result_flags: [256]bool
	var term_flags: [256]bool
	for doc_id := 0; doc_id < 256; doc_id += 1 { result_flags[doc_id] = operation == 0 && seen_docs[doc_id] }
	for t := 0; t < term_count; t += 1 {
		for doc_id := 0; doc_id < 256; doc_id += 1 { term_flags[doc_id] = false }
		edge := posting_heads[terms[t]]
		for edge >= 0 {
			edge_index := int(edge)
			term_flags[int(posting_doc[edge_index])] = true
			edge = posting_next[edge_index]
		}
		for doc_id := 0; doc_id < 256; doc_id += 1 {
			if operation == 0 { result_flags[doc_id] = result_flags[doc_id] && term_flags[doc_id] }
			else { result_flags[doc_id] = result_flags[doc_id] || term_flags[doc_id] }
		}
	}
	var result_ids: [256]i64
	result_count := 0
	for doc_id := 0; doc_id < 256; doc_id += 1 {
		if result_flags[doc_id] { result_ids[result_count] = i64(doc_id); result_count += 1 }
	}
	hash := hash_i64(FNV_OFFSET, i64(result_count))
	for i := 0; i < result_count; i += 1 { hash = hash_i64(hash, result_ids[i]) }
	return i64(hash & 0x7fffffffffffffff)
}
