const max_words = 64
const max_word_length = 16

fn sift(mut heap []int, counts []int, size int, root int) {
	mut best := root
	left := 2 * root + 1
	right := left + 1
	if left < size && counts[heap[left]] > counts[heap[best]] { best = left }
	if right < size && counts[heap[right]] > counts[heap[best]] { best = right }
	if best != root { heap[root], heap[best] = heap[best], heap[root]; sift(mut heap, counts, size, best) }
}

@[export: 'top_k_frequent_words']
pub fn top_k_frequent_words(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { values == nil } || length < 2 || length > 1090 { return -1 }
	if unsafe { values[0] < 0 || values[0] > 64 || values[1] < 0 || values[1] > 64 } { return -1 }
	k := int(unsafe { values[0] }); word_count := int(unsafe { values[1] })
	mut words := [max_words][max_word_length]u8{}
	mut lens := [max_words]int{}
	mut counts := [max_words]int{}
	mut heap := [max_words]int{}
	mut distinct := 0
	mut pos := 2
	for _ in 0 .. word_count {
		if pos >= int(length) || unsafe { values[pos] < 1 || values[pos] > 16 } { return -1 }
		word_len := int(unsafe { values[pos] }); pos++
		if word_len > int(length) - pos { return -1 }
		for j in 0 .. word_len { if unsafe { values[pos+j] < 97 || values[pos+j] > 122 } { return -1 } }
		mut id := 0
		for id < distinct {
			if lens[id] == word_len {
				mut j := 0
				for j < word_len && i64(words[id][j]) == unsafe { values[pos+j] } { j++ }
				if j == word_len { break }
			}
			id++
		}
		if id == distinct { lens[id] = word_len; for j in 0 .. word_len { words[id][j] = u8(unsafe { values[pos+j] }) }; distinct++ }
		counts[id]++; pos += word_len
	}
	if pos != int(length) { return -1 }
	for i in 0 .. distinct { heap[i] = i }
	mut i := distinct / 2
	for i > 0 { i--; sift(mut heap[..], counts[..], distinct, i) }
	limit := if k < distinct { k } else { distinct }
	mut temp := [max_words * (max_word_length + 1) + 1]u8{}
	mut at := 0
	for _ in 0 .. limit {
		id := heap[0]
		for j in 0 .. lens[id] { temp[at+j] = words[id][j] }
		at += lens[id]; temp[at] = 10; at++
		distinct--; heap[0] = heap[distinct]
		if distinct > 0 { sift(mut heap[..], counts[..], distinct, 0) }
	}
	temp[at] = 0; at++
	if unsafe { output == nil } || output_capacity < at { return -2 }
	for j in 0 .. at { unsafe { output[j] = temp[j] } }
	return i64(at)
}
