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

module cbench_consumer_tiff2bw;

const int MAX_PIXELS = 64;
const int MAX_INPUT_LENGTH = 193;

fn long cbench_consumer_tiff2bw(long* input, usz input_length,
                                u8* output, usz output_capacity) @export("cbench_consumer_tiff2bw") {
    if (input == null || input_length < 4 || input_length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_PIXELS) return -1;
    usz count = input[0].usz();
    if (input_length != 1 + 3 * count) return -1;
    for (usz i = 1; i < input_length; i++) {
        if (input[i] < 0 || input[i] > 255) return -1;
    }
    if (output == null || output_capacity < count) return -2;

    for (usz pixel = 0; pixel < count; pixel++) {
        usz at = 1 + 3 * pixel;
        int value = 71 * input[at].int();
        value += 150 * input[at + 1].int();
        value += 28 * input[at + 2].int();
        output[pixel] = (value >> 8).u8();
    }
    return count.long();
}
