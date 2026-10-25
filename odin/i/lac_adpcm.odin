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

package lac_adpcm

import "core:c"

INDEX_TABLE :: [16]int{-1,-1,-1,-1,2,4,6,8,-1,-1,-1,-1,2,4,6,8}
STEP_TABLE :: [89]int{
    7,8,9,10,11,12,13,14,16,17,19,21,23,25,28,31,34,37,41,45,50,55,60,66,73,80,
    88,97,107,118,130,143,157,173,190,209,230,253,279,307,337,371,408,449,494,544,
    598,658,724,796,876,963,1060,1166,1282,1411,1552,1707,1878,2066,2272,2499,2749,
    3024,3327,3660,4026,4428,4871,5358,5894,6484,7132,7845,8630,9493,10442,11487,
    12635,13899,15289,16818,18500,20350,22385,24623,27086,29794,32767,
}

clamp_index :: proc "contextless" (value: int) -> int {
    if value < 0 do return 0
    if value > 88 do return 88
    return value
}

clamp_sample :: proc "contextless" (value: int) -> int {
    if value < -32768 do return -32768
    if value > 32767 do return 32767
    return value
}

encode_one :: proc "contextless" (sample: int, predictor, index: ^int) -> u8 {
    step := STEP_TABLE[index^]
    diff := sample - predictor^
    sign := 0
    if diff < 0 { sign = 8; diff = -diff }
    code := 0
    change := step >> 3
    if diff >= step { code = 4; diff -= step; change += step }
    step >>= 1
    if diff >= step { code |= 2; diff -= step; change += step }
    step >>= 1
    if diff >= step { code |= 1; change += step }
    predictor^ = clamp_sample(predictor^ + (if sign != 0 then -change else change))
    code |= sign
    index^ = clamp_index(index^ + INDEX_TABLE[code])
    return u8(code)
}

decode_one :: proc "contextless" (code: u8, predictor, index: ^int) -> int {
    step := STEP_TABLE[index^]
    index^ = clamp_index(index^ + INDEX_TABLE[int(code)])
    magnitude := int(code & 7)
    change := step >> 3
    if (magnitude & 4) != 0 do change += step
    if (magnitude & 2) != 0 do change += step >> 1
    if (magnitude & 1) != 0 do change += step >> 2
    predictor^ = clamp_sample(predictor^ + (if (code & 8) != 0 then -change else change))
    return predictor^
}

@(export)
lac_adpcm :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 258 do return -1
    mode, count := input[0], input[1]
    if mode == 1 {
        if count < 0 || count > 256 || length != c.size_t(count) + 2 do return -1
        for i := c.size_t(0); i < c.size_t(count); i += 1 {
            if input[i+2] < -32768 || input[i+2] > 32767 do return -1
        }
    } else if mode == 2 {
        if count < 0 || count > 128 || length != c.size_t(count) + 2 do return -1
        for i := c.size_t(0); i < c.size_t(count); i += 1 {
            if input[i+2] < 0 || input[i+2] > 255 do return -1
        }
    } else do return -1

    n := c.size_t(count)
    required := c.size_t(0)
    if mode == 1 { required = (n+1)/2 } else { required = n*4 }
    if required == 0 do return 0
    if output == nil || capacity < required do return -2
    predictor, index := 0, 0
    if mode == 1 {
        for i := c.size_t(0); i < n; i += 1 {
            code := encode_one(int(input[i+2]), &predictor, &index)
            if (i & 1) == 0 { output[i/2] = code << 4 } else { output[i/2] |= code }
        }
    } else {
        for i := c.size_t(0); i < n; i += 1 {
            packed := u8(input[i+2])
            for half := c.size_t(0); half < 2; half += 1 {
                code := u8(packed >> 4)
                if half != 0 do code = packed & 15
                sample := decode_one(code, &predictor, &index)
                position := (i*2+half)*2
                output[position] = u8(sample & 255)
                output[position+1] = u8((sample >> 8) & 255)
            }
        }
    }
    return i64(required)
}
