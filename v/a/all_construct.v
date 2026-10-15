module all_construct

const max_target = 6
const max_words = 4
const max_ways = 4096

@[export: 'all_construct']
pub fn all_construct(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 2 || unsafe { input == nil } { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > max_target { return -1 }
		n := int(input[0])
		for i in 0 .. n { if input[i + 1] < 97 || input[i + 1] > 122 { return -1 } }
		wc_slot := n + 1
		if usize(wc_slot) >= length || input[wc_slot] < 0 || input[wc_slot] > max_words { return -1 }
		words := int(input[wc_slot])
		mut starts := [max_words]int{}
		mut word_lengths := [max_words]int{}
		mut cursor := wc_slot + 1
		for w in 0 .. words {
			if usize(cursor) >= length || input[cursor] < 1 || input[cursor] > max_target { return -1 }
			wl := int(input[cursor]); cursor++
			if usize(cursor + wl) > length { return -1 }
			starts[w] = cursor; word_lengths[w] = wl
			for j in 0 .. wl { if input[cursor + j] < 97 || input[cursor + j] > 122 { return -1 } }
			cursor += wl
		}
		if usize(cursor) != length { return -1 }
		mut paths := [(max_target + 1) * max_ways * max_target]u8{}
		mut path_lengths := [(max_target + 1) * max_ways]u8{}
		mut counts := [max_target + 1]int{}
		counts[0] = 1
		for pos in 0 .. n {
			for w in 0 .. words {
				wl := word_lengths[w]
				if wl > n - pos { continue }
				mut matched := true
				for j in 0 .. wl { if input[pos + 1 + j] != input[starts[w] + j] { matched = false } }
				if !matched { continue }
				ending := pos + wl
				for row in 0 .. counts[pos] {
					dest := counts[ending]
					if dest >= max_ways { return -1 }
					counts[ending]++
					src_base := (pos * max_ways + row) * max_target
					dst_base := (ending * max_ways + dest) * max_target
					plen := int(path_lengths[pos * max_ways + row])
					for k in 0 .. plen { paths[dst_base + k] = paths[src_base + k] }
					paths[dst_base + plen] = u8(w)
					path_lengths[ending * max_ways + dest] = u8(plen + 1)
				}
			}
		}
		mut required := 0
		for row in 0 .. counts[n] {
			plen := int(path_lengths[n * max_ways + row]); required++
			for k in 0 .. plen { w := int(paths[(n * max_ways + row) * max_target + k]); required += 1 + word_lengths[w] }
		}
		if usize(required) > output_capacity || (required > 0 && output == nil) { return -2 }
		if counts[n] == 0 { return 0 }
		mut written := 0
		for row in 0 .. counts[n] {
			path_base := (n * max_ways + row) * max_target
			plen := int(path_lengths[n * max_ways + row])
			output[written] = u8(plen); written++
			for k in 0 .. plen {
				w := int(paths[path_base + k]); wl := word_lengths[w]
				output[written] = u8(wl); written++
				for j in 0 .. wl { output[written] = u8(input[starts[w] + j]); written++ }
			}
		}
		return i64(counts[n])
	}
}
