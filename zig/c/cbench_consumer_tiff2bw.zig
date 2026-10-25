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

const MAX_PIXELS: i64 = 64;
const MAX_INPUT_LENGTH: usize = 193;

pub export fn cbench_consumer_tiff2bw(input: [*c]const i64, input_length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or input_length < 4 or input_length > MAX_INPUT_LENGTH) return -1;
    const pixel_count_value = input[0];
    if (pixel_count_value < 1 or pixel_count_value > MAX_PIXELS) return -1;
    const pixel_count: usize = @intCast(pixel_count_value);
    if (input_length != 1 + 3 * pixel_count) return -1;
    for (1..input_length) |i| {
        if (input[i] < 0 or input[i] > 255) return -1;
    }
    if (output == null or output_capacity < pixel_count) return -2;

    for (0..pixel_count) |pixel| {
        const at = 1 + 3 * pixel;
        var value: i32 = @intCast(input[at] * 71);
        value += @as(i32, @intCast(input[at + 1])) * 150;
        value += @as(i32, @intCast(input[at + 2])) * 28;
        output[pixel] = @intCast(value >> 8);
    }
    return @intCast(pixel_count);
}
