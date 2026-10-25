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

module cbench_tiffdither;

const int MAX_WIDTH = 32;
const int MAX_HEIGHT = 16;
const int MAX_PIXELS = 512;
const int MAX_OUTPUT_BYTES = 60;

fn int trunc_div(int value, int divisor) {
    if (value < 0) return -((-value) / divisor);
    return value / divisor;
}

fn long cbench_tiffdither(long* input, usz input_length, u8* output, usz output_capacity) @export("cbench_tiffdither") {
    if (input == null || input_length < 5 || input_length > 515) return -1;
    if (input[0] < 1 || input[0] > MAX_WIDTH || input[1] < 2 || input[1] > MAX_HEIGHT || input[2] < 0 || input[2] > 255) return -1;
    usz width = input[0].usz();
    usz height = input[1].usz();
    int threshold = input[2].int();
    usz pixel_count = width * height;
    if (input_length != 3 + pixel_count) return -1;

    i16 work[MAX_PIXELS] = {0};
    for (usz i = 0; i < pixel_count; i++) {
        if (input[i + 3] < 0 || input[i + 3] > 255) return -1;
        work[i] = input[i + 3].i16();
    }

    usz row_bytes = (width + 7) / 8;
    usz output_size = row_bytes * (height - 1);
    if (output == null || output_capacity < output_size) return -2;
    u8 staged[MAX_OUTPUT_BYTES] = {0};

    for (usz y = 0; y + 1 < height; y++) {
        bool last_line = y + 2 == height;
        for (usz x = 0; x < width; x++) {
            usz at = y * width + x;
            int value = work[at].int();
            if (value < 0) value = 0;
            else if (value > 255) value = 255;
            if (value > threshold) {
                staged[y * row_bytes + x / 8] |= (0x80 >> (x % 8)).u8();
                value -= 255;
            }
            if (x + 1 < width) work[at + 1] = (work[at + 1].int() + trunc_div(value * 7, 16)).i16();
            if (!last_line) {
                if (x > 0) work[at + width - 1] = (work[at + width - 1].int() + trunc_div(value * 3, 16)).i16();
                work[at + width] = (work[at + width].int() + trunc_div(value * 5, 16)).i16();
                if (x + 1 < width) work[at + width + 1] = (work[at + width + 1].int() + trunc_div(value, 16)).i16();
            }
        }
    }
    for (usz i = 0; i < output_size; i++) output[i] = staged[i];
    return output_size.long();
}
