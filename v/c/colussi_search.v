module colussi_search

const max_text_length = 4096
const max_pattern_length = 128
const max_input_length = 4227

fn preprocess(pattern [max_pattern_length + 1]u8, pattern_length int,
	mut h [max_pattern_length + 1]int, mut next_table [max_pattern_length + 1]int,
	mut shift [max_pattern_length + 1]int) int {
	mut hmax := [max_pattern_length + 2]int{}
	mut kmin := [max_pattern_length + 1]int{}
	mut rmin := [max_pattern_length + 1]int{}
	mut nhd0 := [max_pattern_length + 1]int{}
	mut i, mut k := 1, 1
	for {
		for pattern[i] == pattern[i - k] { i++ }
		hmax[k] = i
		mut q := k + 1
		for hmax[q - k] + k < i {
			hmax[q] = hmax[q - k] + k
			q++
		}
		k = q
		if k == i + 1 { i = k }
		if k > pattern_length { break }
	}
	mut position := pattern_length
	for position >= 1 {
		if hmax[position] < pattern_length { kmin[hmax[position]] = position }
		position--
	}
	mut r := pattern_length
	position = pattern_length - 1
	for position >= 0 {
		if hmax[position + 1] == pattern_length { r = position + 1 }
		if kmin[position] == 0 { rmin[position] = r } else { rmin[position] = 0 }
		position--
	}
	mut nohole_last := -1
	mut hole_at := pattern_length
	for position in 0 .. pattern_length {
		if kmin[position] == 0 {
			hole_at--
			h[hole_at] = position
		} else {
			nohole_last++
			h[nohole_last] = position
		}
	}
	nd := nohole_last
	position = 0
	for position <= nd {
		shift[position] = kmin[h[position]]
		position++
	}
	position = nd + 1
	for position < pattern_length {
		shift[position] = rmin[h[position]]
		position++
	}
	shift[pattern_length] = rmin[0]
	mut nohole_count := 0
	for position in 0 .. pattern_length {
		nhd0[position] = nohole_count
		if kmin[position] > 0 { nohole_count++ }
	}
	position = 0
	for position <= nd {
		next_table[position] = nhd0[h[position] - kmin[h[position]]]
		position++
	}
	position = nd + 1
	for position < pattern_length {
		next_table[position] = nhd0[pattern_length - rmin[h[position]]]
		position++
	}
	next_table[pattern_length] = nhd0[pattern_length - rmin[h[pattern_length - 1]]]
	return nd
}

@[export: 'colussi_search']
pub fn colussi_search(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input_length { return -1 }
		text_length64, pattern_length64 := input[0], input[1]
		if text_length64 < 0 || text_length64 > max_text_length || pattern_length64 < 1 || pattern_length64 > max_pattern_length { return -1 }
		text_length, pattern_length := int(text_length64), int(pattern_length64)
		if int(length) != 2 + text_length + pattern_length { return -1 }
		mut text := [max_text_length]u8{}
		mut pattern := [max_pattern_length + 1]u8{}
		for i in 0 .. text_length {
			symbol := input[2 + i]
			if symbol < 0 || symbol > 3 { return -1 }
			text[i] = u8(symbol)
		}
		pattern_offset := 2 + text_length
		for i in 0 .. pattern_length {
			symbol := input[pattern_offset + i]
			if symbol < 0 || symbol > 3 { return -1 }
			pattern[i] = u8(symbol)
		}
		pattern[pattern_length] = 4
		if text_length < pattern_length { return 0 }
		mut h := [max_pattern_length + 1]int{}
		mut next_table := [max_pattern_length + 1]int{}
		mut shift := [max_pattern_length + 1]int{}
		nd := preprocess(pattern, pattern_length, mut h, mut next_table, mut shift)
		mut i, mut j, mut last := 0, 0, -1
		mut match_count, mut offset_sum, mut offset_xor := i64(0), i64(0), i64(0)
		for j <= text_length - pattern_length {
			for i < pattern_length && last < j + h[i] && pattern[h[i]] == text[j + h[i]] { i++ }
			if i >= pattern_length || last >= j + h[i] {
				match_count++
				offset_sum += i64(j)
				offset_xor ^= i64(j)
				i = pattern_length
			}
			if i > nd { last = j + pattern_length - 1 }
			j += shift[i]
			i = next_table[i]
		}
		return (match_count << 36) | (offset_sum << 12) | offset_xor
	}
}
