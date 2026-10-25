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

const MAX_WIDTH: i64 = 32;
const MAX_HEIGHT: i64 = 16;
const MAX_PIXELS: usize = 512;
const MAX_OUTPUT_BYTES: usize = 60;

pub export fn cbench_tiffdither(input: [*c]const i64, input_length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or input_length < 5 or input_length > 515) return -1;
    const width_value = input[0];
    const height_value = input[1];
    const threshold_value = input[2];
    if (width_value < 1 or width_value > MAX_WIDTH or height_value < 2 or height_value > MAX_HEIGHT or
        threshold_value < 0 or threshold_value > 255) return -1;
    const width: usize = @intCast(width_value);
    const height: usize = @intCast(height_value);
    const threshold: i32 = @intCast(threshold_value);
    const pixel_count = width * height;
    if (input_length != 3 + pixel_count) return -1;

    var work = [_]i16{0} ** MAX_PIXELS;
    for (0..pixel_count) |i| {
        const pixel = input[i + 3];
        if (pixel < 0 or pixel > 255) return -1;
        work[i] = @intCast(pixel);
    }

    const row_bytes = (width + 7) / 8;
    const output_size = row_bytes * (height - 1);
    if (output == null or output_capacity < output_size) return -2;
    var staged = [_]u8{0} ** MAX_OUTPUT_BYTES;

    for (0..height - 1) |y| {
        const last_line = y + 2 == height;
        for (0..width) |x| {
            const at = y * width + x;
            var value: i32 = work[at];
            if (value < 0) value = 0 else if (value > 255) value = 255;
            if (value > threshold) {
                const shift: u3 = @intCast(x % 8);
                staged[y * row_bytes + x / 8] |= @as(u8, 0x80) >> shift;
                value -= 255;
            }
            if (x + 1 < width) {
                work[at + 1] = @intCast(@as(i32, work[at + 1]) + @divTrunc(value * 7, 16));
            }
            if (!last_line) {
                if (x > 0) {
                    work[at + width - 1] = @intCast(@as(i32, work[at + width - 1]) + @divTrunc(value * 3, 16));
                }
                work[at + width] = @intCast(@as(i32, work[at + width]) + @divTrunc(value * 5, 16));
                if (x + 1 < width) {
                    work[at + width + 1] = @intCast(@as(i32, work[at + width + 1]) + @divTrunc(value, 16));
                }
            }
        }
    }
    for (0..output_size) |i| output[i] = staged[i];
    return @intCast(output_size);
}
