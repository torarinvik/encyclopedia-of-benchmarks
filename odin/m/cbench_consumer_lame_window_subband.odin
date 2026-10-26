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
package cbench_consumer_lame_window_subband
import "core:c"
import "core:math"

SAMPLE_COUNT :: 511
WINDOW_COUNT :: 256
INPUT_COUNT :: 767
MAX_INPUT_LENGTH :: c.size_t(768)
OUTPUT_BYTES :: 256
PI :: 3.14159265358979323846264338327950288
S_OFFSETS :: [15]int{334,398,462,14,78,142,206,16,80,144,208,272,336,400,464}
T_OFFSETS :: [15]int{176,112,48,496,432,368,304,494,430,366,302,238,174,110,46}

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}
round_q1000 :: proc(value: f64) -> i64 {
	scaled := value * 1000.0
	magnitude := if scaled < 0.0 do -scaled else scaled
	rounded := i64(magnitude + 0.5)
	return if scaled < 0.0 do -rounded else rounded
}
valid :: proc(input: [^]i64, length: c.size_t) -> bool {
	if input == nil || length == 0 || length > MAX_INPUT_LENGTH || length != c.size_t(INPUT_COUNT) do return false
	for i := 0; i < SAMPLE_COUNT; i += 1 { if input[i] < -32768 || input[i] > 32767 do return false }
	for i := 0; i < WINDOW_COUNT; i += 1 { if input[SAMPLE_COUNT+i] < -4500000 || input[SAMPLE_COUNT+i] > 36000000 do return false }
	for i := 0; i < WINDOW_COUNT; i += 1 { if (i == 0 || (i >= 8 && (i-8)%16 == 0)) && input[SAMPLE_COUNT+i] <= 25000000 do return false }
	return true
}
filterbank :: proc(input: [^]i64, window: [^]f64, bands: [^]f64) {
	maximum := window[248]
	mmax: [31]f64
	mm: [16][31]f64
	wp, wr := 0, 0
	w := window[wp]; wp += 1
	mmax[15] = w / maximum
	for k := 0; k < 7; k += 1 { window[wr] = window[wp] / w; wr += 1; wp += 1 }
	for i := 14; i >= 0; i -= 1 {
		w = window[wp]; wp += 1
		mmax[i] = w / maximum; mmax[30-i] = w / maximum
		for k := 0; k < 15; k += 1 { window[wr] = window[wp] / w; wr += 1; wp += 1 }
	}
	wp += 1
	for k := 0; k < 7; k += 1 { window[wr] = window[wp] / maximum; wr += 1; wp += 1 }
	for i := 15; i >= 0; i -= 1 { for k := 1; k < 32; k += 1 { mm[i][k-1] = math.cos(f64((2*i+1)*k)*PI/64.0)*mmax[k-1] } }
	inner: [31]f64
	coeff := 0
	t := f64(input[255])
	t += f64(input[223]-input[287])*window[coeff]; coeff += 1
	t += f64(input[191]+input[319])*window[coeff]; coeff += 1
	t += f64(input[159]-input[351])*window[coeff]; coeff += 1
	t += f64(input[127]+input[383])*window[coeff]; coeff += 1
	t += f64(input[95]-input[415])*window[coeff]; coeff += 1
	t += f64(input[63]+input[447])*window[coeff]; coeff += 1
	t += f64(input[31]-input[479])*window[coeff]; coeff += 1
	inner[15] = t
	for i := 14; i >= 0; i -= 1 {
		s := f64(input[270-i]); t = f64(input[240+i])
		for k := 0; k < 15; k += 1 {
			w = window[coeff]; coeff += 1
			si := S_OFFSETS[k] + (if k < 7 do -i else i)
			ti := T_OFFSETS[k] + (if k < 7 do i else -i)
			sv := f64(input[si])*w; tv := f64(input[ti])*w
			if k >= 11 do s -= sv else s += sv
			if k >= 7 && k < 11 do t -= tv else t += tv
		}
		inner[30-i] = s; inner[i] = t
	}
	s := f64(input[239])
	s += f64(input[175])*window[coeff]; coeff += 1
	s += f64(input[111])*window[coeff]; coeff += 1
	s += f64(input[47])*window[coeff]; coeff += 1
	s -= f64(input[303])*window[coeff]; coeff += 1
	s -= f64(input[367])*window[coeff]; coeff += 1
	s -= f64(input[431])*window[coeff]; coeff += 1
	s -= f64(input[495])*window[coeff]; coeff += 1
	for i := 15; i >= 0; i -= 1 {
		s0, s1 := s, t*mm[i][0]
		at := 1
		for j := 0; j < 15; j += 1 { s0 += mm[i][2*j+1]*inner[at]; at += 1; s1 += mm[i][2*j+2]*inner[at]; at += 1 }
		bands[i] = s0+s1; bands[31-i] = s0-s1
	}
}

@(export)
cbench_consumer_lame_window_subband :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if !valid(input, input_length) do return -1
	window: [WINDOW_COUNT]f64
	for i := 0; i < WINDOW_COUNT; i += 1 { window[i] = f64(input[SAMPLE_COUNT+i])/1000000000.0 }
	bands: [32]f64
	filterbank(input, &window[0], &bands[0])
	staged: [32]i64
	for i := 0; i < 32; i += 1 { staged[i] = round_q1000(bands[i]) }
	if output == nil || output_capacity < c.size_t(OUTPUT_BYTES) do return -2
	for i := 0; i < 32; i += 1 { store_i64_le(output, 8*i, staged[i]) }
	return OUTPUT_BYTES
}
