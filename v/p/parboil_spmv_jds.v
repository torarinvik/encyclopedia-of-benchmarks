module parboil_spmv_jds

import math

fn decode(v i64) f32 { return f32(v) / f32(1_000_000) }
fn put32(mut out []u8, p int, x u32) {
	for b in 0 .. 4 { out[p+b] = u8(x >> (8*b)) }
}

@[export: 'parboil_spmv_jds']
pub fn parboil_spmv_jds(input &i64, input_length usize, output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || input_length < 3 || input_length > 164 { return -1 }
	mut a := [164]i64{}
	unsafe { for i in 0 .. int(input_length) { a[i] = input[i] } }
	if a[0] < 1 || a[0] > 8 || a[1] < 1 || a[1] > 8 || a[2] < 1 || a[2] > 64 { return -1 }
	n, d, z := int(a[0]), int(a[1]), int(a[2])
	if input_length != usize(4 + 3*n + d + 2*z) { return -1 }
	mut row := [8]i64{}
	mut perm := [8]i64{}
	mut ptrs := [9]i64{}
	mut col := [64]i64{}
	mut dat := [64]i64{}
	mut vec := [8]i64{}
	mut p := 3
	for i in 0 .. n { if a[p] < 0 || a[p] > d { return -1 }; row[i] = a[p]; p++ }
	if row[0] != d { return -1 }
	for i in 1 .. n { if row[i] > row[i-1] { return -1 } }
	for i in 0 .. n { perm[i] = a[p]; p++ }
	for i in 0 .. n {
		if perm[i] < 0 || perm[i] >= n { return -1 }
		for j in 0 .. i { if perm[i] == perm[j] { return -1 } }
	}
	for k in 0 .. d+1 { ptrs[k] = a[p]; p++ }
	for j in 0 .. z { col[j] = a[p]; p++ }
	for j in 0 .. z { dat[j] = a[p]; p++ }
	for i in 0 .. n { vec[i] = a[p]; p++ }
	if ptrs[0] != 0 { return -1 }
	mut off := 0
	for k in 0 .. d {
		mut count := 0
		for i in 0 .. n { if row[i] > k { count++ } }
		off += count
		if ptrs[k+1] != off { return -1 }
	}
	if off != z { return -1 }
	for j in 0 .. z { if col[j] < 0 || col[j] >= n || dat[j] < -1_000_000 || dat[j] > 1_000_000 { return -1 } }
	for i in 0 .. n { if vec[i] < -1_000_000 || vec[i] > 1_000_000 { return -1 } }
	if unsafe { output == nil } || output_capacity < usize(4+4*n) { return -2 }
	mut y := [8]f32{}
	mut staged := [36]u8{}
	for i in 0 .. n {
		mut acc := f32(0)
		for k in 0 .. int(row[i]) {
			j := int(ptrs[k]) + i
			product := decode(dat[j]) * decode(vec[int(col[j])])
			acc = acc + product
		}
		y[int(perm[i])] = acc
	}
	put32(mut staged[..], 0, u32(n))
	for i in 0 .. n { put32(mut staged[..], 4+4*i, math.f32_bits(y[i])) }
	unsafe { for i in 0 .. 4+4*n { output[i] = staged[i] } }
	return i64(4+4*n)
}
