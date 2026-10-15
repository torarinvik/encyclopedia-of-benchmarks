package aho_corasick

import "core:c"

MAX_PATTERNS :: 16
MAX_PATTERN_LENGTH :: 32
MAX_TEXT_LENGTH :: 256
MAX_NODES :: 1 + MAX_PATTERNS * MAX_PATTERN_LENGTH
ALPHABET :: 128

@(export)
aho_corasick :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || input[0] < 1 || input[0] > MAX_PATTERNS || input[1] < 0 || input[1] > MAX_TEXT_LENGTH do return -1
	pattern_count := int(input[0])
	if int(length) < 2 + pattern_count do return -1
	starts: [MAX_PATTERNS]int
	text_start := 2 + pattern_count
	for p := 0; p < pattern_count; p += 1 {
		if input[2+p] < 1 || input[2+p] > MAX_PATTERN_LENGTH do return -1
		size := int(input[2+p])
		if text_start + size > int(length) do return -1
		starts[p] = text_start
		for i := 0; i < size; i += 1 { if input[starts[p]+i] < 1 || input[starts[p]+i] > 127 do return -1 }
		for q := 0; q < p; q += 1 {
			if int(input[2+q]) != size do continue
			i := 0
			for i < size && input[starts[q]+i] == input[starts[p]+i] { i += 1 }
			if i == size do return -1
		}
		text_start += size
	}
	text_length := int(input[1])
	if text_start + text_length != int(length) do return -1
	for i := 0; i < text_length; i += 1 { if input[text_start+i] < 1 || input[text_start+i] > 127 do return -1 }
	output_size := pattern_count * 8
	if int(output_capacity) < output_size || output == nil do return -2

	next: [MAX_NODES][ALPHABET]i32
	failure: [MAX_NODES]int
	terminal: [MAX_NODES]int
	queue: [MAX_NODES]int
	for n := 0; n < MAX_NODES; n += 1 {
		terminal[n] = -1
		for ch := 0; ch < ALPHABET; ch += 1 { next[n][ch] = -1 }
	}
	nodes := 1
	for p := 0; p < pattern_count; p += 1 {
		state := 0
		for i := 0; i < int(input[2+p]); i += 1 {
			ch := int(input[starts[p]+i])
			if next[state][ch] == -1 { next[state][ch] = i32(nodes); nodes += 1 }
			state = int(next[state][ch])
		}
		terminal[state] = p
	}
	head, tail := 0, 0
	for ch := 1; ch < ALPHABET; ch += 1 { if next[0][ch] != -1 { queue[tail] = int(next[0][ch]); tail += 1 } }
	for head < tail {
		state := queue[head]; head += 1
		for ch := 1; ch < ALPHABET; ch += 1 {
			child := int(next[state][ch])
			if child == -1 do continue
			suffix := failure[state]
			for suffix != 0 && next[suffix][ch] == -1 { suffix = failure[suffix] }
			if next[suffix][ch] != -1 { suffix = int(next[suffix][ch]) }
			failure[child] = suffix; queue[tail] = child; tail += 1
		}
	}
	counts: [MAX_PATTERNS]i64
	state := 0
	for i := 0; i < text_length; i += 1 {
		ch := int(input[text_start+i])
		for state != 0 && next[state][ch] == -1 { state = failure[state] }
		if next[state][ch] != -1 { state = int(next[state][ch]) }
		matched := state
		for matched != 0 {
			if terminal[matched] >= 0 { counts[terminal[matched]] += 1 }
			matched = failure[matched]
		}
	}
	for p := 0; p < pattern_count; p += 1 {
		value := u64(counts[p])
		for b := 0; b < 8; b += 1 { output[p*8+b] = u8((value >> u64(8*b)) & 255) }
	}
	return i64(output_size)
}
