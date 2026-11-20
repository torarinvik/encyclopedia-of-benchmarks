module all_distances_bottom_k_interval_updates

const abki_max_n = 32
const abki_max_k = 4
const abki_max_input = 99
const abki_max_words = 97
const abki_distance_limit = i64(1000000)
const abki_end = i64(1000001)

struct Interval {
	item_id i64
	rank i64
	first i64
	past i64
}

fn abki_put_i64(mut output &u8, word int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[word * 8 + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'all_distances_bottom_k_interval_updates']
pub fn all_distances_bottom_k_interval_updates(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > abki_max_input { return -1 }
	n0 := unsafe { input[0] }
	k0 := unsafe { input[1] }
	if n0 < 2 || n0 > abki_max_n || k0 < 2 || k0 > abki_max_k || k0 > n0 { return -1 }
	n, k := int(n0), int(k0)
	if length != usize(2 + 3 * n) { return -1 }

	mut records := [abki_max_n]Interval{}
	mut seen_id := [abki_max_n]bool{}
	mut seen_rank := [abki_max_n]bool{}
	for i in 0 .. n {
		id := unsafe { input[2 + 3*i] }
		distance := unsafe { input[3 + 3*i] }
		rank := unsafe { input[4 + 3*i] }
		if id < 0 || id >= n0 || seen_id[int(id)] || rank < 0 || rank >= n0
			|| seen_rank[int(rank)] || distance < 0 || distance > abki_distance_limit { return -1 }
		seen_id[int(id)] = true
		seen_rank[int(rank)] = true
		for j in 0 .. i { if records[j].first == distance { return -1 } }
		records[i] = Interval{item_id: id, rank: rank, first: distance, past: 0}
	}
	for i in 1 .. k { if records[i-1].first >= records[i].first { return -1 } }
	for i in k .. n { if records[i].first <= records[k-1].first { return -1 } }

	mut intervals := [abki_max_n]Interval{}
	mut count := k
	for i in 0 .. k {
		intervals[i] = Interval{item_id: records[i].item_id, rank: records[i].rank,
			first: records[i].first, past: abki_end}
	}
	for i in k .. n {
		mut worst, mut active := abki_max_n, 0
		for j in 0 .. count {
			if intervals[j].first <= records[i].first && records[i].first < intervals[j].past {
				active++
				if worst == abki_max_n || intervals[j].rank > intervals[worst].rank { worst = j }
			}
		}
		if active != k || worst == abki_max_n { return -1 }
		if records[i].rank >= intervals[worst].rank { continue }
		mut cursor := intervals[worst].past
		intervals[worst].past = records[i].first
		for cursor < abki_end {
			mut next_worst := abki_max_n
			for j in 0 .. count {
				if intervals[j].first <= cursor && cursor < intervals[j].past
					&& (next_worst == abki_max_n || intervals[j].rank > intervals[next_worst].rank) {
					next_worst = j
				}
			}
			if next_worst == abki_max_n || intervals[next_worst].rank <= records[i].rank { break }
			next_cursor := intervals[next_worst].past
			intervals[next_worst].past = cursor
			cursor = next_cursor
		}
		intervals[count] = Interval{item_id: records[i].item_id, rank: records[i].rank,
			first: records[i].first, past: cursor}
		count++
	}

	mut order := [abki_max_n]int{}
	mut out_count := 0
	for i in 0 .. count { if intervals[i].first < intervals[i].past { order[out_count] = i; out_count++ } }
	for i in 1 .. out_count {
		key := order[i]
		mut j := i
		for j > 0 && (intervals[order[j-1]].first > intervals[key].first
			|| (intervals[order[j-1]].first == intervals[key].first
				&& intervals[order[j-1]].item_id > intervals[key].item_id)) {
			order[j] = order[j-1]
			j--
		}
		order[j] = key
	}
	mut staged := [abki_max_words]i64{}
	staged[0] = i64(out_count)
	for i in 0 .. out_count {
		x := intervals[order[i]]
		staged[1+3*i], staged[2+3*i], staged[3+3*i] = x.item_id, x.first, x.past
	}
	bytes := usize(8 * (1 + 3 * out_count))
	if unsafe { output == nil } || capacity < bytes { return -2 }
	for word in 0 .. (1 + 3 * out_count) { abki_put_i64(mut &output[0], word, staged[word]) }
	return i64(bytes)
}
