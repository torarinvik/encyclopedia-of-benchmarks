package mmpfh_bucketing

import "core:c"

Max_N :: 32
Max_Q :: 32
Bucket :: 3
Max_B :: 11
Max_Words :: 100

lcp :: proc(a, b: i64) -> i64 {
	count: i64 = 0
	for count < 16 && ((a >> (15-count)) & 1) == ((b >> (15-count)) & 1) { count += 1 }
	return count
}

put_i64 :: proc(out: [^]u8, pos: int, value: i64) {
	bits := u64(value)
	for b in 0..<8 { out[pos+b] = u8((bits >> (8*b)) & 255) }
}

@(export)
mmpfh_bucketing :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 66 do return -1
	n0 := input[0]; q0 := input[1]
	if n0 < 1 || n0 > Max_N || q0 < 1 || q0 > Max_Q || length != c.size_t(2+n0+q0) do return -1
	n := int(n0); q := int(q0)
	keys: [Max_N]i64
	queries: [Max_Q]i64
	for i in 0..<n {
		x := input[2+i]
		if x < 0 || x > 65535 || (i > 0 && keys[i-1] >= x) do return -1
		keys[i] = x
	}
	for i in 0..<q {
		x := input[2+n+i]
		if x < 0 || x > 65535 do return -1
		queries[i] = x
		found := false
		for j in 0..<n { if keys[j] == x { found = true } }
		if !found do return -1
	}
	buckets := (n+Bucket-1)/Bucket
	d0: [Max_N]i64
	lens: [Max_B]i64
	prefixes: [Max_B]i64
	ranks: [Max_Q]i64
	for b in 0..<buckets {
		start := b*Bucket
		end := start+Bucket
		if end > n { end = n }
		plen: i64 = 16
		if end-start > 1 { plen = lcp(keys[start], keys[end-1]) }
		prefix: i64 = 0
		if plen > 0 { prefix = keys[start] >> (16-plen) }
		lens[b] = plen; prefixes[b] = prefix
		for i in start..<end { d0[i] = plen }
	}
	for i in 0..<q {
		pos := 0
		for keys[pos] != queries[i] { pos += 1 }
		plen := d0[pos]
		prefix: i64 = 0
		if plen > 0 { prefix = queries[i] >> (16-plen) }
		b := 0
		for b < buckets && (lens[b] != plen || prefixes[b] != prefix) { b += 1 }
		if b == buckets do return -1
		ranks[i] = i64(b*Bucket + pos - b*Bucket)
	}
	words := 3+n+3*buckets+q
	if output == nil || capacity < c.size_t(words*8) do return -2
	staged: [Max_Words]i64
	k := 0
	staged[k] = i64(n); k += 1; staged[k] = i64(buckets); k += 1; staged[k] = i64(q); k += 1
	for i in 0..<n { staged[k] = d0[i]; k += 1 }
	for b in 0..<buckets { staged[k] = lens[b]; k += 1; staged[k] = prefixes[b]; k += 1; staged[k] = i64(b); k += 1 }
	for i in 0..<q { staged[k] = ranks[i]; k += 1 }
	for i in 0..<words { put_i64(output, i*8, staged[i]) }
	return i64(words*8)
}
