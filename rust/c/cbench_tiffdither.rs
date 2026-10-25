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

fn trunc_div(value: i32, divisor: i32) -> i32 {
    if value < 0 { -((-value) / divisor) } else { value / divisor }
}

#[no_mangle]
pub unsafe extern "C" fn cbench_tiffdither(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 5 || input_length > 515 { return -1; }
    let values = core::slice::from_raw_parts(input, input_length);
    if values[0] < 1 || values[0] > MAX_WIDTH || values[1] < 2 || values[1] > MAX_HEIGHT ||
        values[2] < 0 || values[2] > 255 { return -1; }
    let width = values[0] as usize;
    let height = values[1] as usize;
    let threshold = values[2] as i32;
    let pixel_count = width * height;
    if input_length != 3 + pixel_count { return -1; }

    let mut work = [0i16; MAX_PIXELS];
    for i in 0..pixel_count {
        let pixel = values[i + 3];
        if !(0..=255).contains(&pixel) { return -1; }
        work[i] = pixel as i16;
    }

    let row_bytes = (width + 7) / 8;
    let output_size = row_bytes * (height - 1);
    if output.is_null() || output_capacity < output_size { return -2; }
    let mut staged = [0u8; MAX_OUTPUT_BYTES];

    for y in 0..height - 1 {
        let last_line = y + 2 == height;
        for x in 0..width {
            let at = y * width + x;
            let mut value = i32::from(work[at]);
            if value < 0 { value = 0; }
            else if value > 255 { value = 255; }
            if value > threshold {
                staged[y * row_bytes + x / 8] |= 0x80 >> (x % 8);
                value -= 255;
            }

            if x + 1 < width {
                work[at + 1] = (i32::from(work[at + 1]) + trunc_div(value * 7, 16)) as i16;
            }
            if !last_line {
                if x > 0 {
                    work[at + width - 1] = (i32::from(work[at + width - 1]) + trunc_div(value * 3, 16)) as i16;
                }
                work[at + width] = (i32::from(work[at + width]) + trunc_div(value * 5, 16)) as i16;
                if x + 1 < width {
                    work[at + width + 1] = (i32::from(work[at + width + 1]) + trunc_div(value, 16)) as i16;
                }
            }
        }
    }

    for i in 0..output_size { output.add(i).write(staged[i]); }
    output_size as i64
}
