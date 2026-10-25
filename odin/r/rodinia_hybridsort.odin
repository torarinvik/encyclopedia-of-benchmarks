package rodinia_hybridsort

import "core:c"

bucket :: proc(value, minimum, span: f32) -> int {
	index := int((value-minimum)/span*1024.0)
	if index < 0 do index = 0
	if index >= 1024 do index = 1023
	return index
}

merge_sort :: proc(items, scratch: [^]i64, count: int) {
	width := 1
	for width < count {
		left := 0
		for left < count {
			middle := min(left+width, count); right := min(left+2*width, count)
			a := left; b := middle; out := left
			for a < middle && b < right {
				if items[a] <= items[b] { scratch[out] = items[a]; a += 1 }
				else { scratch[out] = items[b]; b += 1 }
				out += 1
			}
		for a < middle { scratch[out] = items[a]; a += 1; out += 1 }
		for b < right { scratch[out] = items[b]; b += 1; out += 1 }
		left += 2*width
		}
		for i in 0 ..< count do items[i] = scratch[i]
		width *= 2
	}
}

put_i64 :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for b in 0 ..< 8 do output[offset+b] = u8(bits >> (8*b))
}

@(export)
rodinia_hybridsort :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 65 do return -1
	if input[0] < 2 || input[0] > 64 do return -1
	count := int(input[0]); if length != c.size_t(count+1) do return -1
	items: [64]i64; scratch: [64]i64
	min_raw := i64(1<<62); max_raw := i64(-1)
	for i in 0 ..< count {
		x := input[1+i]
		if x < 0 || x > 1_000_000 || x % 1000 != 0 do return -1
		items[i] = x; min_raw = min(min_raw, x); max_raw = max(max_raw, x)
	}
	if min_raw == max_raw do return -1
	bytes := count*8
	if output == nil || capacity < c.size_t(bytes) do return -2
	minimum := f32(min_raw)/1_000_000.0; maximum := f32(max_raw)/1_000_000.0; span := maximum-minimum
	histogram: [1024]int; offsets: [1025]int; next: [1024]int; scattered: [64]i64
	for b in 0 ..< 1024 {
		histogram[b] = 0
		offsets[b] = 0
		next[b] = 0
	}
	offsets[1024] = 0
	for i in 0 ..< count { histogram[bucket(f32(items[i])/1_000_000.0, minimum, span)] += 1 }
	for b in 0 ..< 1024 { offsets[b+1] = offsets[b]+histogram[b]; next[b] = offsets[b] }
	for i in 0 ..< count { b := bucket(f32(items[i])/1_000_000.0, minimum, span); scattered[next[b]] = items[i]; next[b] += 1 }
	for b in 0 ..< 1024 { start := offsets[b]; end := offsets[b+1]; if end > start do merge_sort(&scattered[start], &scratch[0], end-start) }
	for i in 0 ..< count do put_i64(output, i*8, scattered[i])
	return i64(bytes)
}
