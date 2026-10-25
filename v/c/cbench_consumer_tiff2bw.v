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

const max_pixels = 64
const max_input_length = 193

@[export: 'cbench_consumer_tiff2bw']
pub fn cbench_consumer_tiff2bw(input &i64, input_length usize, output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || input_length < 4 || input_length > max_input_length { return -1 }
	pixel_count_value := unsafe { input[0] }
	if pixel_count_value < 1 || pixel_count_value > max_pixels { return -1 }
	pixel_count := int(pixel_count_value)
	if input_length != usize(1 + 3 * pixel_count) { return -1 }
	for i in 1 .. 3 * pixel_count + 1 {
		channel := unsafe { input[i] }
		if channel < 0 || channel > 255 { return -1 }
	}
	if unsafe { output == nil } || output_capacity < usize(pixel_count) { return -2 }

	for pixel in 0 .. pixel_count {
		at := 1 + 3 * pixel
		mut value := int(71 * unsafe { input[at] })
		value += int(150 * unsafe { input[at + 1] })
		value += int(28 * unsafe { input[at + 2] })
		unsafe { output[pixel] = u8(value >> 8) }
	}
	return i64(pixel_count)
}
