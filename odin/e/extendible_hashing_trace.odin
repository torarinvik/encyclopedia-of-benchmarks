package extendible_hashing_trace

import "core:c"

N :: 256
OPS :: 40
WORDS :: 82

Table :: struct {
	directory: [N]u8,
	keys: [N][2]u8,
	counts, depths: [N]u8,
	active: [N]bool,
	gd, high, buckets, live: int,
}

init_table :: proc "contextless" () -> Table {
	t: Table
	t.gd, t.high, t.buckets = 1, 1, 2
	t.directory[0], t.directory[1] = 0, 1
	t.active[0], t.active[1] = true, true
	t.depths[0], t.depths[1] = 1, 1
	return t
}

bucket_for :: proc "contextless" (t: ^Table, key: int) -> int {
	return int(t.directory[key & ((1 << t.gd) - 1)])
}

find_slot :: proc "contextless" (t: ^Table, b, key: int) -> int {
	for s := 0; s < int(t.counts[b]); s += 1 { if int(t.keys[b][s]) == key { return s } }
	return -1
}

split :: proc "contextless" (t: ^Table, b: int) -> bool {
	d := int(t.depths[b])
	if d >= 8 { return false }
	if d == t.gd {
		old_size := 1 << t.gd
		for i := 0; i < old_size; i += 1 { t.directory[i + old_size] = t.directory[i] }
		t.gd += 1
		if t.gd > t.high { t.high = t.gd }
	}
	fresh := 0
	for fresh < N && t.active[fresh] { fresh += 1 }
	if fresh == N { return false }
	t.active[fresh] = true
	t.depths[b], t.depths[fresh] = u8(d + 1), u8(d + 1)
	old_count := int(t.counts[b]); old_keys := t.keys[b]
	t.counts[b], t.counts[fresh] = 0, 0
	t.keys[b], t.keys[fresh] = [2]u8{}, [2]u8{}
	bit, size := 1 << d, 1 << t.gd
	for i := 0; i < size; i += 1 { if int(t.directory[i]) == b && (i & bit) != 0 { t.directory[i] = u8(fresh) } }
	for i := 0; i < old_count; i += 1 {
		key := int(old_keys[i]); target := b
		if (key & bit) != 0 { target = fresh }
		t.keys[target][int(t.counts[target])] = old_keys[i]
		t.counts[target] += 1
	}
	t.buckets += 1
	return true
}

coalesce :: proc "contextless" (t: ^Table, start: int) {
	b := start
	for int(t.depths[b]) > 1 {
		d, size := int(t.depths[b]), 1 << t.gd
		rep := -1
		for i := 0; i < size; i += 1 { if int(t.directory[i]) == b { rep = i; break } }
		if rep < 0 { break }
		prefix := rep & ((1 << d) - 1); buddy_prefix := prefix ^ (1 << (d - 1)); buddy := int(t.directory[buddy_prefix])
		if buddy == b || !t.active[buddy] || int(t.depths[buddy]) != d || int(t.counts[b])+int(t.counts[buddy]) > 2 { break }
		keep, drop := b, buddy
		if buddy_prefix < prefix { keep, drop = buddy, b }
		keep_count, drop_count := int(t.counts[keep]), int(t.counts[drop])
		for j := 0; j < drop_count; j += 1 { t.keys[keep][keep_count+j] = t.keys[drop][j] }
		t.counts[keep] += t.counts[drop]; t.counts[drop] = 0; t.keys[drop] = [2]u8{}
		t.depths[keep] = u8(d - 1); t.active[drop] = false
		for i := 0; i < size; i += 1 { if int(t.directory[i]) == drop { t.directory[i] = u8(keep) } }
		t.buckets -= 1; b = keep
	}
	for t.gd > 1 {
		half := 1 << (t.gd - 1); mirror := true
		for i := 0; i < half; i += 1 { if t.directory[i] != t.directory[i+half] { mirror = false; break } }
		if !mirror { break }
		t.gd -= 1
	}
}

@(export)
extendible_hashing_trace :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > WORDS { return -1 }
	qv := input[0]
	if qv < 0 || qv > OPS || length != c.size_t(1 + 2*qv) { return -1 }
	q := int(qv)
	for i := 0; i < q; i += 1 { if input[1+2*i] < 0 || input[1+2*i] > 2 || input[2+2*i] < 0 || input[2+2*i] > 255 { return -1 } }
	t := init_table(); successes: u64 = 0
	for i := 0; i < q; i += 1 {
		op, key := int(input[1+2*i]), int(input[2+2*i]); b := bucket_for(&t, key); slot := find_slot(&t, b, key); success: u64 = 0
		if op == 0 && slot < 0 {
			for int(t.counts[b]) == 2 { if !split(&t, b) { break }; b = bucket_for(&t, key) }
			if int(t.counts[b]) < 2 { t.keys[b][int(t.counts[b])] = u8(key); t.counts[b] += 1; t.live += 1; success = 1 }
		} else if op == 1 && slot >= 0 {
			t.counts[b] -= 1; t.keys[b][slot] = t.keys[b][int(t.counts[b])]; t.keys[b][int(t.counts[b])] = 0
			t.live -= 1; success = 1; coalesce(&t, b)
		} else if op == 2 && slot >= 0 { success = 1 }
		successes = (successes << 1) | success
	}
	return i64(successes | (u64(t.buckets) << 40) | (u64(t.gd) << 49) | (u64(t.high) << 53) | (u64(t.live) << 57))
}
