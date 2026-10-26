/*
 * Copyright (c) 1999 Takehiro TOMINAGA
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */
module cbench_consumer_lame_window_subband

import math

const sample_count = 511
const window_count = 256
const input_count = 767
const max_input_length = 768
const output_bytes = 256
const pi = 3.14159265358979323846264338327950288
const s_offsets = [15]int{334,398,462,14,78,142,206,16,80,144,208,272,336,400,464}
const t_offsets = [15]int{176,112,48,496,432,368,304,494,430,366,302,238,174,110,46}

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}
fn round_q1000(value f64) i64 {
	scaled := value * 1000.0
	magnitude := if scaled < 0.0 { -scaled } else { scaled }
	rounded := i64(magnitude + 0.5)
	return if scaled < 0.0 { -rounded } else { rounded }
}
fn valid(input &i64, length usize) bool {
	if input == nil || length == 0 || length > max_input_length || length != input_count { return false }
	unsafe {
		for i in 0 .. sample_count { if input[i] < -32768 || input[i] > 32767 { return false } }
		for i in 0 .. window_count { if input[sample_count+i] < -4500000 || input[sample_count+i] > 36000000 { return false } }
		for i in 0 .. window_count { if (i == 0 || (i >= 8 && (i-8)%16 == 0)) && input[sample_count+i] <= 25000000 { return false } }
	}
	return true
}
fn filterbank(input &i64, mut window [256]f64) [32]f64 {
	maximum := window[248]
	mut mmax := [31]f64{}
	mut mm := [16][31]f64{}
	mut wp := 0
	mut wr := 0
	mut w := window[wp]; wp++
	mmax[15] = w / maximum
	for _ in 0 .. 7 { window[wr] = window[wp] / w; wr++; wp++ }
	for i in 0 .. 15 {
		row := 14 - i
		w = window[wp]; wp++
		mmax[row] = w / maximum; mmax[30-row] = w / maximum
		for _ in 0 .. 15 { window[wr] = window[wp] / w; wr++; wp++ }
	}
	wp++
	for _ in 0 .. 7 { window[wr] = window[wp] / maximum; wr++; wp++ }
	for i in 0 .. 16 {
		row := 15 - i
		for k in 1 .. 32 { mm[row][k-1] = math.cos(f64((2*row+1)*k)*pi/64.0) * mmax[k-1] }
	}
	mut inner := [31]f64{}
	mut coeff := 0
	mut t := f64(input[255])
	t += f64(input[223]-input[287])*window[coeff]; coeff++
	t += f64(input[191]+input[319])*window[coeff]; coeff++
	t += f64(input[159]-input[351])*window[coeff]; coeff++
	t += f64(input[127]+input[383])*window[coeff]; coeff++
	t += f64(input[95]-input[415])*window[coeff]; coeff++
	t += f64(input[63]+input[447])*window[coeff]; coeff++
	t += f64(input[31]-input[479])*window[coeff]; coeff++
	inner[15] = t
	for i in 0 .. 15 {
		row := 14 - i
		mut s := f64(input[270-row])
		t = f64(input[240+row])
		for k in 0 .. 15 {
			w = window[coeff]; coeff++
			si := s_offsets[k] + (if k < 7 { -row } else { row })
			ti := t_offsets[k] + (if k < 7 { row } else { -row })
			sv := f64(input[si])*w; tv := f64(input[ti])*w
			if k >= 11 { s -= sv } else { s += sv }
			if k >= 7 && k < 11 { t -= tv } else { t += tv }
		}
		inner[30-row] = s; inner[row] = t
	}
	mut s := f64(input[239])
	s += f64(input[175])*window[coeff]; coeff++
	s += f64(input[111])*window[coeff]; coeff++
	s += f64(input[47])*window[coeff]; coeff++
	s -= f64(input[303])*window[coeff]; coeff++
	s -= f64(input[367])*window[coeff]; coeff++
	s -= f64(input[431])*window[coeff]; coeff++
	s -= f64(input[495])*window[coeff]; coeff++
	mut bands := [32]f64{}
	for i in 0 .. 16 {
		row := 15-i
		mut s0 := s
		mut s1 := t*mm[row][0]
		mut at := 1
		for _ in 0 .. 15 { s0 += mm[row][at]*inner[at]; at++; s1 += mm[row][at]*inner[at]; at++ }
		bands[row] = s0+s1; bands[31-row] = s0-s1
	}
	return bands
}

@[export: 'cbench_consumer_lame_window_subband']
pub fn cbench_consumer_lame_window_subband(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if !valid(input, input_length) { return -1 }
		mut window := [256]f64{}
		for i in 0 .. window_count { window[i] = f64(input[sample_count+i])/1000000000.0 }
		bands := filterbank(input, mut window)
		mut staged := [32]i64{}
		for i in 0 .. 32 { staged[i] = round_q1000(bands[i]) }
		if output == nil || output_capacity < output_bytes { return -2 }
		for i in 0 .. 32 { store_i64_le(mut output, 8*i, staged[i]) }
		return output_bytes
	}
}
