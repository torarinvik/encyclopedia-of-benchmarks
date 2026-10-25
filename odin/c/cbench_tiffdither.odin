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

package cbench_tiffdither

import "core:c"

MAX_WIDTH :: 32
MAX_HEIGHT :: 16
MAX_PIXELS :: 512
MAX_OUTPUT_BYTES :: 60

trunc_div :: proc "contextless" (value, divisor: int) -> int {
	if value < 0 do return -((-value) / divisor)
	return value / divisor
}

@(export)
cbench_tiffdither :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 5 || length > 515 do return -1
	if input[0] < 1 || input[0] > MAX_WIDTH || input[1] < 2 || input[1] > MAX_HEIGHT ||
		input[2] < 0 || input[2] > 255 do return -1
	width := int(input[0])
	height := int(input[1])
	threshold := int(input[2])
	pixel_count := width * height
	if length != c.size_t(3 + pixel_count) do return -1

	work: [MAX_PIXELS]i16 = {}
	for i := 0; i < pixel_count; i += 1 {
		if input[i+3] < 0 || input[i+3] > 255 do return -1
		work[i] = i16(input[i+3])
	}

	row_bytes := (width + 7) / 8
	output_size := row_bytes * (height - 1)
	if output == nil || capacity < c.size_t(output_size) do return -2
	staged: [MAX_OUTPUT_BYTES]u8 = {}

	for y := 0; y < height-1; y += 1 {
		last_line := y + 2 == height
		for x := 0; x < width; x += 1 {
			at := y * width + x
			value := int(work[at])
			if value < 0 { value = 0 } else if value > 255 { value = 255 }
			if value > threshold {
				staged[y*row_bytes+x/8] |= u8(0x80 >> (x % 8))
				value -= 255
			}
			if x+1 < width { work[at+1] = i16(int(work[at+1]) + trunc_div(value*7, 16)) }
			if !last_line {
				if x > 0 { work[at+width-1] = i16(int(work[at+width-1]) + trunc_div(value*3, 16)) }
				work[at+width] = i16(int(work[at+width]) + trunc_div(value*5, 16))
				if x+1 < width { work[at+width+1] = i16(int(work[at+width+1]) + trunc_div(value, 16)) }
			}
		}
	}
	for i := 0; i < output_size; i += 1 { output[i] = staged[i] }
	return i64(output_size)
}
