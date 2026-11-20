const max_n = 64
const max_k = 4
const max_input = 67
const max_output = 320
const levels = 7

fn pair_less(a int, b int, width int, rank []int, n int) bool {
	if rank[a] != rank[b] { return rank[a] < rank[b] }
	ra := if a + width < n { rank[a + width] } else { -1 }
	rb := if b + width < n { rank[b + width] } else { -1 }
	return ra < rb
}

fn lce(a int, b int, n int, inverse []int, sparse []int, logs []int) int {
	if a >= n || b >= n { return 0 }
	if a == b { return n - a }
	mut left, mut right := inverse[a], inverse[b]
	if left > right { left, right = right, left }
	left++
	count := right - left + 1
	level := logs[count]
	span := 1 << level
	return min(sparse[level * max_n + left], sparse[level * max_n + right - span + 1])
}

@[export: 'k_mismatch_longest_extension_table']
pub fn k_mismatch_longest_extension_table(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		nv, kv := input[0], input[1]
		if nv < 1 || nv > max_n || kv < 0 || kv > max_k { return -1 }
		n, budget := int(nv), int(kv)
		if length != usize(n + 2) { return -1 }

		mut text := []int{len: max_n}
		mut suffixes := []int{len: max_n}
		mut rank := []int{len: max_n}
		mut inverse := []int{len: max_n}
		mut lcp := []int{len: max_n}
		mut sparse := []int{len: levels * max_n}
		mut logs := []int{len: max_n + 1}
		mut staged := []u8{len: max_output}
		for i in 0 .. n {
			if input[i + 2] < 0 || input[i + 2] > 25 { return -1 }
			text[i] = int(input[i + 2])
			suffixes[i] = i
			rank[i] = text[i]
		}

		mut width := 1
		for width < n {
			for i := 1; i < n; i++ {
				key := suffixes[i]
				mut j := i
				for j > 0 && pair_less(key, suffixes[j - 1], width, rank, n) {
					suffixes[j] = suffixes[j - 1]
					j--
				}
				suffixes[j] = key
			}
			mut next_rank := []int{len: max_n}
			mut classes := 0
			next_rank[suffixes[0]] = 0
			for i := 1; i < n; i++ {
				a, b := suffixes[i - 1], suffixes[i]
				a2, b2 := -1, -1
				if a + width < n { a2 = rank[a + width] }
				if b + width < n { b2 = rank[b + width] }
				if rank[a] != rank[b] || a2 != b2 { classes++ }
				next_rank[b] = classes
			}
			rank = next_rank
			if classes == n - 1 || width > n / 2 { break }
			width *= 2
		}
		for i in 0 .. n { inverse[suffixes[i]] = i }
		mut matched := 0
		for start in 0 .. n {
			order := inverse[start]
			if order == 0 { matched = 0; continue }
			other := suffixes[order - 1]
			for start + matched < n && other + matched < n && text[start + matched] == text[other + matched] { matched++ }
			lcp[order] = matched
			if matched > 0 { matched-- }
		}
		for i in 0 .. n { sparse[i] = lcp[i] }
		for level := 1; level < levels; level++ {
			span := 1 << level
			half := span / 2
			for i := 0; i + span <= n; i++ {
				a, b := sparse[(level - 1) * max_n + i], sparse[(level - 1) * max_n + i + half]
				sparse[level * max_n + i] = min(a, b)
			}
		}
		for count := 2; count <= n; count++ { logs[count] = logs[count / 2] + 1 }

		mut written := 0
		for p in 0 .. n {
			limit := n - p
			mut extension := min(limit, lce(0, p, n, inverse, sparse, logs))
			staged[written] = u8(extension)
			written++
			for k := 1; k <= budget; k++ {
				if extension < limit {
					extension = min(limit, extension + 1 + lce(extension + 1, p + extension + 1, n, inverse, sparse, logs))
				}
				staged[written] = u8(extension)
				written++
			}
		}
		if written > max_output { return -1 }
		if output == nil || capacity < usize(written) { return -2 }
		for i in 0 .. written { output[i] = staged[i] }
		return i64(written)
	}
}
