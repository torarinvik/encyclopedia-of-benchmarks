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

package cbench_consumer_tiff2bw

import "core:c"

MAX_PIXELS :: 64
MAX_INPUT_LENGTH :: 193

@(export)
cbench_consumer_tiff2bw :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT_LENGTH do return -1
	if input[0] < 1 || input[0] > MAX_PIXELS do return -1
	pixel_count := int(input[0])
	if length != c.size_t(1 + 3 * pixel_count) do return -1
	for i := 1; i < pixel_count*3+1; i += 1 {
		if input[i] < 0 || input[i] > 255 do return -1
	}
	if output == nil || capacity < c.size_t(pixel_count) do return -2

	for pixel := 0; pixel < pixel_count; pixel += 1 {
		at := 1 + 3 * pixel
		value := 71 * int(input[at])
		value += 150 * int(input[at+1])
		value += 28 * int(input[at+2])
		output[pixel] = u8(value >> 8)
	}
	return i64(pixel_count)
}
