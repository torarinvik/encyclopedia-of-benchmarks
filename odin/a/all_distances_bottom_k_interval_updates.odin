package all_distances_bottom_k_interval_updates

import "core:c"

MAX_N :: 32
MAX_K :: 4
MAX_INPUT :: 99
MAX_WORDS :: 97
DISTANCE_LIMIT :: i64(1000000)
END_SENTINEL :: i64(1000001)

Interval :: struct { item_id, rank, first, past: i64 }

put_i64_le :: proc "contextless" (output: [^]u8, word: int, value: i64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 { output[word * 8 + byte] = u8((bits >> (8 * byte)) & 255) }
}

@(export)
all_distances_bottom_k_interval_updates :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	n0, k0 := input[0], input[1]
	if n0 < 2 || n0 > MAX_N || k0 < 2 || k0 > MAX_K || k0 > n0 do return -1
	n, k := int(n0), int(k0)
	if length != c.size_t(2 + 3 * n) do return -1

	var records: [MAX_N]Interval
	var seen_id, seen_rank: [MAX_N]bool
	for i := 0; i < n; i += 1 {
		id, distance, rank := input[2 + 3*i], input[3 + 3*i], input[4 + 3*i]
		if id < 0 || id >= n0 || seen_id[int(id)] || rank < 0 || rank >= n0
			|| seen_rank[int(rank)] || distance < 0 || distance > DISTANCE_LIMIT do return -1
		seen_id[int(id)] = true
		seen_rank[int(rank)] = true
		for j := 0; j < i; j += 1 { if records[j].first == distance do return -1 }
		records[i] = {id, rank, distance, 0}
	}
	for i := 1; i < k; i += 1 { if records[i-1].first >= records[i].first do return -1 }
	for i := k; i < n; i += 1 { if records[i].first <= records[k-1].first do return -1 }

	var intervals: [MAX_N]Interval
	count := k
	for i := 0; i < k; i += 1 {
		intervals[i] = {records[i].item_id, records[i].rank, records[i].first, END_SENTINEL}
	}
	for i := k; i < n; i += 1 {
		worst, active := MAX_N, 0
		for j := 0; j < count; j += 1 {
			if intervals[j].first <= records[i].first && records[i].first < intervals[j].past {
				active += 1
				if worst == MAX_N || intervals[j].rank > intervals[worst].rank do worst = j
			}
		}
		if active != k || worst == MAX_N do return -1
		if records[i].rank >= intervals[worst].rank do continue
		cursor := intervals[worst].past
		intervals[worst].past = records[i].first
		for cursor < END_SENTINEL {
			next_worst := MAX_N
			for j := 0; j < count; j += 1 {
				if intervals[j].first <= cursor && cursor < intervals[j].past
					&& (next_worst == MAX_N || intervals[j].rank > intervals[next_worst].rank) do next_worst = j
			}
			if next_worst == MAX_N || intervals[next_worst].rank <= records[i].rank do break
			next_cursor := intervals[next_worst].past
			intervals[next_worst].past = cursor
			cursor = next_cursor
		}
		intervals[count] = {records[i].item_id, records[i].rank, records[i].first, cursor}
		count += 1
	}

	var order: [MAX_N]int
	out_count := 0
	for i := 0; i < count; i += 1 {
		if intervals[i].first < intervals[i].past { order[out_count] = i; out_count += 1 }
	}
	for i := 1; i < out_count; i += 1 {
		key, j := order[i], i
		for j > 0 && (intervals[order[j-1]].first > intervals[key].first
			|| (intervals[order[j-1]].first == intervals[key].first
				&& intervals[order[j-1]].item_id > intervals[key].item_id)) {
			order[j] = order[j-1]
			j -= 1
		}
		order[j] = key
	}
	var staged: [MAX_WORDS]i64
	staged[0] = i64(out_count)
	for i := 0; i < out_count; i += 1 {
		x := intervals[order[i]]
		staged[1+3*i], staged[2+3*i], staged[3+3*i] = x.item_id, x.first, x.past
	}
	bytes := c.size_t(8 * (1 + 3 * out_count))
	if output == nil || capacity < bytes do return -2
	for word := 0; word < 1 + 3 * out_count; word += 1 { put_i64_le(output, word, staged[word]) }
	return i64(bytes)
}
