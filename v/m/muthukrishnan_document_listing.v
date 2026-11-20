module muthukrishnan_document_listing

const mdl_max_n = 32
const mdl_max_docs = 8
const mdl_max_q = 16
const mdl_max_input = 68
const mdl_max_output = 144

struct MdlState {
	da [mdl_max_n]i64
	previous [mdl_max_n]i64
	logs [mdl_max_n + 1]int
	table [6][mdl_max_n]int
	found_ranks [mdl_max_docs]int
	found_docs [mdl_max_docs]u8
	found_count int
	staged [mdl_max_output]u8
	written int
}

fn mdl_range_min(state &MdlState, lo int, hi int) int {
	level := state.logs[hi - lo + 1]
	width := 1 << level
	left := state.table[level][lo]
	right := state.table[level][hi - width + 1]
	if state.previous[left] < state.previous[right]
		|| (state.previous[left] == state.previous[right] && left < right) {
		return left
	}
	return right
}

fn mdl_report(mut state MdlState, lo int, hi int, query_lo int, mut count int) {
	if lo > hi { return }
	index := mdl_range_min(state, lo, hi)
	if state.previous[index] >= i64(query_lo) { return }
	state.found_ranks[state.found_count] = index
	state.found_docs[state.found_count] = u8(state.da[index])
	state.found_count++
	count++
	if index > lo { mdl_report(mut state, lo, index - 1, query_lo, mut count) }
	if index < hi { mdl_report(mut state, index + 1, hi, query_lo, mut count) }
}

@[export: 'muthukrishnan_document_listing']
pub fn muthukrishnan_document_listing(values &i64, length usize, mut output &u8,
	output_capacity usize) i64 {
	if unsafe { values == nil } || length < 3 || length > mdl_max_input { return -1 }
	n_value := unsafe { values[0] }
	docs_value := unsafe { values[1] }
	q_value := unsafe { values[2] }
	if n_value < 1 || n_value > mdl_max_n || docs_value < 1 || docs_value > mdl_max_docs
		|| q_value < 1 || q_value > mdl_max_q { return -1 }
	n := int(n_value)
	docs := int(docs_value)
	q := int(q_value)
	if length != usize(3 + n + 2 * q) { return -1 }

	mut state := MdlState{}
	mut last := [mdl_max_docs]i64{}
	for doc in 0 .. docs { last[doc] = -1 }
	for index in 0 .. n {
		document := unsafe { values[3 + index] }
		if document < 0 || document >= docs_value { return -1 }
		state.da[index] = document
		state.previous[index] = last[int(document)]
		last[int(document)] = i64(index)
	}
	for query in 0 .. q {
		lo := unsafe { values[3 + n + 2 * query] }
		hi := unsafe { values[4 + n + 2 * query] }
		if lo < 0 || hi < lo || hi >= n_value { return -1 }
	}

	for size in 2 .. n + 1 { state.logs[size] = state.logs[size / 2] + 1 }
	for index in 0 .. n { state.table[0][index] = index }
	level_count := state.logs[n] + 1
	for level in 1 .. level_count {
		width := 1 << level
		half := width / 2
		for start in 0 .. n - width + 1 {
			left := state.table[level - 1][start]
			right := state.table[level - 1][start + half]
			if state.previous[left] < state.previous[right]
				|| (state.previous[left] == state.previous[right] && left < right) {
				state.table[level][start] = left
			} else {
				state.table[level][start] = right
			}
		}
	}

	for query in 0 .. q {
		lo := int(unsafe { values[3 + n + 2 * query] })
		hi := int(unsafe { values[4 + n + 2 * query] })
		count_at := state.written
		state.written++
		state.found_count = 0
		mut count := 0
		mdl_report(mut state, lo, hi, lo, mut count)
		for i in 1 .. state.found_count {
			rank := state.found_ranks[i]
			document := state.found_docs[i]
			mut j := i
			for j > 0 && state.found_ranks[j - 1] > rank {
				state.found_ranks[j] = state.found_ranks[j - 1]
				state.found_docs[j] = state.found_docs[j - 1]
				j--
			}
			state.found_ranks[j] = rank
			state.found_docs[j] = document
		}
		state.staged[count_at] = u8(count)
		for i in 0 .. state.found_count {
			state.staged[state.written] = state.found_docs[i]
			state.written++
		}
	}
	if state.written > mdl_max_output { return -1 }
	if unsafe { output == nil } || output_capacity < usize(state.written) { return -2 }
	for index in 0 .. state.written {
		unsafe { output[index] = state.staged[index] }
	}
	return i64(state.written)
}
