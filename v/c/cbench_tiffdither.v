/*
Copyright (c) 1988-1997 Sam Leffler
Copyright (c) 1991-1997 Silicon Graphics, Inc.

Permission to use, copy, modify, distribute, and sell this software and
its documentation for any purpose is hereby granted without fee, provided
that (i) the above copyright notices and this permission notice appear in
all copies of the software and related documentation, and (ii) the names of
Sam Leffler and Silicon Graphics may not be used in any advertising or
publicity relating to the software without the specific, prior written
permission of Sam Leffler and Silicon Graphics.

THE SOFTWARE IS PROVIDED "AS-IS" AND WITHOUT WARRANTY OF ANY KIND,
EXPRESS, IMPLIED OR OTHERWISE, INCLUDING WITHOUT LIMITATION, ANY
WARRANTY OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.

IN NO EVENT SHALL SAM LEFFLER OR SILICON GRAPHICS BE LIABLE FOR
ANY SPECIAL, INCIDENTAL, INDIRECT OR CONSEQUENTIAL DAMAGES OF ANY KIND,
OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
WHETHER OR NOT ADVISED OF THE POSSIBILITY OF DAMAGE, AND ON ANY THEORY OF
LIABILITY, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE
OF THIS SOFTWARE.
*/

module main

const max_width = 32
const max_height = 16
const max_pixels = 512
const max_output_bytes = 60

fn trunc_div(value int, divisor int) int {
	return if value < 0 { -((-value) / divisor) } else { value / divisor }
}

@[export: 'cbench_tiffdither']
pub fn cbench_tiffdither(input &i64, input_length usize, output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || input_length < 5 || input_length > 515 { return -1 }
	width_value := unsafe { input[0] }
	height_value := unsafe { input[1] }
	threshold_value := unsafe { input[2] }
	if width_value < 1 || width_value > max_width || height_value < 2 || height_value > max_height ||
		threshold_value < 0 || threshold_value > 255 { return -1 }
	width := int(width_value)
	height := int(height_value)
	threshold := int(threshold_value)
	pixel_count := width * height
	if input_length != usize(3 + pixel_count) { return -1 }

	mut work := [max_pixels]i16{}
	for i in 0 .. pixel_count {
		pixel := unsafe { input[i + 3] }
		if pixel < 0 || pixel > 255 { return -1 }
		work[i] = i16(pixel)
	}

	row_bytes := (width + 7) / 8
	output_size := row_bytes * (height - 1)
	if unsafe { output == nil } || output_capacity < usize(output_size) { return -2 }
	mut staged := [max_output_bytes]u8{}

	for y in 0 .. height - 1 {
		last_line := y + 2 == height
		for x in 0 .. width {
			at := y * width + x
			mut value := int(work[at])
			if value < 0 { value = 0 } else if value > 255 { value = 255 }
			if value > threshold {
				staged[y * row_bytes + x / 8] |= u8(0x80 >> (x % 8))
				value -= 255
			}
			if x + 1 < width { work[at + 1] = i16(int(work[at + 1]) + trunc_div(value * 7, 16)) }
			if !last_line {
				if x > 0 { work[at + width - 1] = i16(int(work[at + width - 1]) + trunc_div(value * 3, 16)) }
				work[at + width] = i16(int(work[at + width]) + trunc_div(value * 5, 16))
				if x + 1 < width { work[at + width + 1] = i16(int(work[at + width + 1]) + trunc_div(value, 16)) }
			}
		}
	}
	for i in 0 .. output_size { unsafe { output[i] = staged[i] } }
	return i64(output_size)
}
