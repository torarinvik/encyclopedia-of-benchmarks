/*
Copyright 1992 by Stichting Mathematisch Centrum, Amsterdam, The Netherlands.

                        All Rights Reserved

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted,
provided that the above copyright notice appear in all copies and that
both that copyright notice and this permission notice appear in
supporting documentation, and that the names of Stichting Mathematisch
Centrum or CWI not be used in advertising or publicity pertaining to
distribution of the software without specific, written prior permission.

STICHTING MATHEMATISCH CENTRUM DISCLAIMS ALL WARRANTIES WITH REGARD TO
THIS SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS, IN NO EVENT SHALL STICHTING MATHEMATISCH CENTRUM BE LIABLE
FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT
OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
*/

module lac_adpcm;

const int[16] INDEX_TABLE = {-1,-1,-1,-1,2,4,6,8,-1,-1,-1,-1,2,4,6,8};
const int[89] STEP_TABLE = {
    7,8,9,10,11,12,13,14,16,17,19,21,23,25,28,31,34,37,41,45,50,55,60,66,73,80,
    88,97,107,118,130,143,157,173,190,209,230,253,279,307,337,371,408,449,494,544,
    598,658,724,796,876,963,1060,1166,1282,1411,1552,1707,1878,2066,2272,2499,2749,
    3024,3327,3660,4026,4428,4871,5358,5894,6484,7132,7845,8630,9493,10442,11487,
    12635,13899,15289,16818,18500,20350,22385,24623,27086,29794,32767
};

fn int clamp_index(int value) { if (value < 0) return 0; if (value > 88) return 88; return value; }
fn int clamp_sample(int value) { if (value < -32768) return -32768; if (value > 32767) return 32767; return value; }

fn int encode_one(int sample, int* predictor, int* index) {
    int step = STEP_TABLE[*index];
    int diff = sample - *predictor;
    int sign = diff < 0 ? 8 : 0;
    if (sign != 0) diff = -diff;
    int code = 0;
    int difference = step >> 3;
    if (diff >= step) { code = 4; diff -= step; difference += step; }
    step >>= 1;
    if (diff >= step) { code |= 2; diff -= step; difference += step; }
    step >>= 1;
    if (diff >= step) { code |= 1; difference += step; }
    *predictor = clamp_sample(*predictor + (sign != 0 ? -difference : difference));
    code |= sign;
    *index = clamp_index(*index + INDEX_TABLE[code]);
    return code;
}

fn int decode_one(int code, int* predictor, int* index) {
    int step = STEP_TABLE[*index];
    *index = clamp_index(*index + INDEX_TABLE[code]);
    int magnitude = code & 7;
    int difference = step >> 3;
    if ((magnitude & 4) != 0) difference += step;
    if ((magnitude & 2) != 0) difference += step >> 1;
    if ((magnitude & 1) != 0) difference += step >> 2;
    *predictor = clamp_sample(*predictor + ((code & 8) != 0 ? -difference : difference));
    return *predictor;
}

fn long lac_adpcm(long* input, usz length, char* output, usz capacity) @export("lac_adpcm") {
    if (input == null || length < 2 || length > 258) return -1;
    long mode = input[0];
    long count = input[1];
    if (mode == 1) {
        if (count < 0 || count > 256 || length != (usz)count + 2) return -1;
        for (usz i = 0; i < (usz)count; i++) if (input[i + 2] < -32768 || input[i + 2] > 32767) return -1;
    } else if (mode == 2) {
        if (count < 0 || count > 128 || length != (usz)count + 2) return -1;
        for (usz i = 0; i < (usz)count; i++) if (input[i + 2] < 0 || input[i + 2] > 255) return -1;
    } else return -1;

    usz n = (usz)count;
    usz required = mode == 1 ? (n + 1) / 2 : n * 4;
    if (required == 0) return 0;
    if (output == null || capacity < required) return -2;
    int predictor = 0;
    int index = 0;
    if (mode == 1) {
        for (usz i = 0; i < n; i++) {
            int code = encode_one((int)input[i + 2], &predictor, &index);
            if ((i & 1) == 0) output[i / 2] = (char)(code << 4);
            else output[i / 2] |= (char)code;
        }
    } else {
        for (usz i = 0; i < n; i++) {
            int packed = (int)input[i + 2];
            for (usz half = 0; half < 2; half++) {
                int code = half == 0 ? packed >> 4 : packed & 15;
                int sample = decode_one(code, &predictor, &index);
                usz position = (i * 2 + half) * 2;
                output[position] = (char)(sample & 255);
                output[position + 1] = (char)((sample >> 8) & 255);
            }
        }
    }
    return (long)required;
}
