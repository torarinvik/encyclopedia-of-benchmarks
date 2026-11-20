package muthukrishnan_document_listing

import "core:c"

MAX_N :: 32
MAX_DOCS :: 8
MAX_Q :: 16
MAX_INPUT :: 68
MAX_OUTPUT :: 144

State :: struct {
	da: [MAX_N]i64,
	previous: [MAX_N]i64,
	logs: [MAX_N+1]int,
	table: [6][MAX_N]int,
	found_ranks: [MAX_DOCS]int,
	found_docs: [MAX_DOCS]u8,
	found_count: int,
	staged: [MAX_OUTPUT]u8,
	written: int,
}

range_min :: proc(state: ^State, lo, hi: int) -> int {
	level := state.logs[hi-lo+1]
	width := 1 << level
	left := state.table[level][lo]
	right := state.table[level][hi-width+1]
	if state.previous[left] < state.previous[right] ||
		(state.previous[left] == state.previous[right] && left < right) do return left
	return right
}

report :: proc(state: ^State, lo, hi, query_lo: int, count: ^int) {
	if lo > hi do return
	index := range_min(state, lo, hi)
	if state.previous[index] >= i64(query_lo) do return
	state.found_ranks[state.found_count] = index
	state.found_docs[state.found_count] = u8(state.da[index])
	state.found_count += 1
	count^ += 1
	if index > lo do report(state, lo, index-1, query_lo, count)
	if index < hi do report(state, index+1, hi, query_lo, count)
}

@(export)
muthukrishnan_document_listing :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	n_value, docs_value, q_value := input[0], input[1], input[2]
	if n_value < 1 || n_value > MAX_N || docs_value < 1 || docs_value > MAX_DOCS ||
		q_value < 1 || q_value > MAX_Q do return -1
	n, docs, q := int(n_value), int(docs_value), int(q_value)
	if length != c.size_t(3+n+2*q) do return -1

	state: State
	last: [MAX_DOCS]i64
	for doc := 0; doc < docs; doc += 1 { last[doc] = -1 }
	for i := 0; i < n; i += 1 {
		document := input[3+i]
		if document < 0 || document >= docs_value do return -1
		state.da[i] = document
		state.previous[i] = last[int(document)]
		last[int(document)] = i64(i)
	}
	for query := 0; query < q; query += 1 {
		lo, hi := input[3+n+2*query], input[4+n+2*query]
		if lo < 0 || hi < lo || hi >= n_value do return -1
	}

	for size := 2; size <= n; size += 1 do state.logs[size] = state.logs[size/2]+1
	for i := 0; i < n; i += 1 do state.table[0][i] = i
	level_count := state.logs[n]+1
	for level := 1; level < level_count; level += 1 {
		width := 1 << level
		half := width >> 1
		for start := 0; start+width <= n; start += 1 {
			left := state.table[level-1][start]
			right := state.table[level-1][start+half]
			if state.previous[left] < state.previous[right] ||
				(state.previous[left] == state.previous[right] && left < right) {
				state.table[level][start] = left
			} else {
				state.table[level][start] = right
			}
		}
	}

	for query := 0; query < q; query += 1 {
		lo, hi := int(input[3+n+2*query]), int(input[4+n+2*query])
		count_at := state.written
		state.written += 1
		state.found_count = 0
		count := 0
		report(&state, lo, hi, lo, &count)
		for i := 1; i < state.found_count; i += 1 {
			rank := state.found_ranks[i]
			document := state.found_docs[i]
			j := i
			for j > 0 && state.found_ranks[j-1] > rank {
				state.found_ranks[j] = state.found_ranks[j-1]
				state.found_docs[j] = state.found_docs[j-1]
				j -= 1
			}
			state.found_ranks[j] = rank
			state.found_docs[j] = document
		}
		state.staged[count_at] = u8(count)
		for i := 0; i < state.found_count; i += 1 {
			state.staged[state.written] = state.found_docs[i]
			state.written += 1
		}
	}
	if state.written > MAX_OUTPUT do return -1
	if output == nil || capacity < c.size_t(state.written) do return -2
	for i := 0; i < state.written; i += 1 do output[i] = state.staged[i]
	return i64(state.written)
}
