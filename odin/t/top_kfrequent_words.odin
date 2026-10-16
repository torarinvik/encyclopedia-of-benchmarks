package top_kfrequent_words

import "core:c"

sift :: proc(heap: ^[64]int, counts: ^[64]int, size, root: int) {
	best := root; left := 2 * root + 1; right := left + 1
	if left < size && counts[heap[left]] > counts[heap[best]] do best = left
	if right < size && counts[heap[right]] > counts[heap[best]] do best = right
	if best != root { heap[root], heap[best] = heap[best], heap[root]; sift(heap, counts, size, best) }
}

@(export)
top_kfrequent_words :: proc "c" (v: [^]i64, n: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if v == nil || n < 2 || n > 1090 || v[0] < 0 || v[0] > 64 || v[1] < 0 || v[1] > 64 do return -1
	k, wn := int(v[0]), int(v[1]); pos, distinct := 2, 0
	words: [64][16]u8 = {}; lens: [64]int = {}; counts: [64]int = {}; heap: [64]int = {}
	for _ in 0..<wn {
		if pos >= int(n) || v[pos] < 1 || v[pos] > 16 do return -1
		length := int(v[pos]); pos += 1
		if length > int(n)-pos do return -1
		for j in 0..<length { if v[pos+j] < 97 || v[pos+j] > 122 do return -1 }
		id := 0
		for id < distinct {
			if lens[id] == length {
				j := 0; for j < length && int64(words[id][j]) == v[pos+j] do j += 1
				if j == length do break
			}
			id += 1
		}
		if id == distinct { lens[id] = length; for j in 0..<length do words[id][j] = u8(v[pos+j]); distinct += 1 }
		counts[id] += 1; pos += length
	}
	if pos != int(n) do return -1
	for id in 0..<distinct {
		rank := 0
		for other in 0..<distinct {
			common := min(lens[id], lens[other]); j := 0
			for j < common && words[other][j] == words[id][j] do j += 1
			if (j < common && words[other][j] < words[id][j]) || (j == common && lens[other] < lens[id]) do rank += 1
		}
		counts[id] = counts[id] * 65 + distinct - rank
	}
	for i in 0..<distinct do heap[i] = i
	for i := distinct/2-1; i >= 0; i -= 1 { sift(&heap, &counts, distinct, i) }
	limit := min(k, distinct); temp: [1089]u8 = {}; at := 0
	for _ in 0..<limit {
		id := heap[0]; for j in 0..<lens[id] do temp[at+j] = words[id][j]
		at += lens[id]; temp[at] = '\n'; at += 1
		distinct -= 1; heap[0] = heap[distinct]; if distinct > 0 do sift(&heap, &counts, distinct, 0)
	}
	temp[at] = 0; at += 1
	if output == nil || int(capacity) < at do return -2
	for i in 0..<at do output[i] = temp[i]
	return i64(at)
}
