package string_heap_sort

import "core:c"

MAX_KEYS :: 64
WIDTH :: 4

sift_down :: proc "contextless" (a: ^[MAX_KEYS]u32, root_value, ending: int) {
	root := root_value
	for root < ending / 2 {
		child := 2 * root + 1
		if child + 1 < ending && a[child] < a[child + 1] do child += 1
		if a[root] >= a[child] do break
		t := a[root]; a[root] = a[child]; a[child] = t
		root = child
	}
}

@(export)
string_heap_sort :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || length > 257 do return -1
	raw_count := values[0]
	if raw_count < 0 || raw_count > MAX_KEYS do return -1
	count := int(raw_count)
	if length != c.size_t(1 + WIDTH * count) do return -1
	keys: [MAX_KEYS]u32
	for i := 0; i < count; i += 1 {
		key: u32 = 0
		for b := 0; b < WIDTH; b += 1 {
			x := values[1 + WIDTH*i + b]
			if x < 0 || x > 127 do return -1
			key = (key << 8) | u32(x)
		}
		keys[i] = key
	}
	for start := count / 2; start > 0; {
		start -= 1; sift_down(&keys, start, count)
	}
	for ending := count; ending > 1; {
		ending -= 1
		t := keys[0]; keys[0] = keys[ending]; keys[ending] = t
		sift_down(&keys, 0, ending)
	}
	byte_count := count * WIDTH
	if output == nil || capacity < c.size_t(byte_count) do return -2
	for i := 0; i < count; i += 1 {
		for b := 0; b < WIDTH; b += 1 { output[i*WIDTH+b] = u8((keys[i] >> u32(24-8*b)) & 255) }
	}
	return i64(byte_count)
}
