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

#[no_mangle]
pub unsafe extern "C" fn cbench_consumer_tiff2bw(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 4 || input_length > MAX_INPUT_LENGTH { return -1; }
    let values = core::slice::from_raw_parts(input, input_length);
    if values[0] < 1 || values[0] > MAX_PIXELS { return -1; }
    let pixel_count = values[0] as usize;
    if input_length != 1 + 3 * pixel_count { return -1; }
    if values[1..].iter().any(|channel| !(0..=255).contains(channel)) { return -1; }
    if output.is_null() || output_capacity < pixel_count { return -2; }

    for pixel in 0..pixel_count {
        let at = 1 + 3 * pixel;
        let mut value = 71 * values[at] as i32;
        value += 150 * values[at + 1] as i32;
        value += 28 * values[at + 2] as i32;
        output.add(pixel).write((value >> 8) as u8);
    }
    pixel_count as i64
}
