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

module lac_adpcm

const index_table = [16]i32{-1, -1, -1, -1, 2, 4, 6, 8, -1, -1, -1, -1, 2, 4, 6, 8}
const step_table = [89]i32{
    7,8,9,10,11,12,13,14,16,17,19,21,23,25,28,31,34,37,41,45,50,55,60,66,73,80,
    88,97,107,118,130,143,157,173,190,209,230,253,279,307,337,371,408,449,494,544,
    598,658,724,796,876,963,1060,1166,1282,1411,1552,1707,1878,2066,2272,2499,2749,
    3024,3327,3660,4026,4428,4871,5358,5894,6484,7132,7845,8630,9493,10442,11487,
    12635,13899,15289,16818,18500,20350,22385,24623,27086,29794,32767,
}

fn clamp_index(value i32) i32 {
    if value < 0 { return 0 }
    if value > 88 { return 88 }
    return value
}
fn clamp_sample(value i32) i32 {
    if value < -32768 { return -32768 }
    if value > 32767 { return 32767 }
    return value
}
fn encode_one(sample i32, mut predictor i32, mut index i32) u8 {
    mut step := step_table[int(index)]
    mut diff := sample - predictor
    sign := if diff < 0 { i32(8) } else { i32(0) }
    if sign != 0 { diff = -diff }
    mut code := i32(0)
    mut change := step >> 3
    if diff >= step { code = 4; diff -= step; change += step }
    step >>= 1
    if diff >= step { code |= 2; diff -= step; change += step }
    step >>= 1
    if diff >= step { code |= 1; change += step }
    predictor = clamp_sample(predictor + if sign != 0 { -change } else { change })
    code |= sign
    index = clamp_index(index + index_table[int(code)])
    return u8(code)
}
fn decode_one(code u8, mut predictor i32, mut index i32) i32 {
    step := step_table[int(index)]
    index = clamp_index(index + index_table[int(code)])
    magnitude := i32(code & 7)
    mut change := step >> 3
    if magnitude & 4 != 0 { change += step }
    if magnitude & 2 != 0 { change += step >> 1 }
    if magnitude & 1 != 0 { change += step >> 2 }
    predictor = clamp_sample(predictor + if code & 8 != 0 { -change } else { change })
    return predictor
}

@[export: 'lac_adpcm']
pub fn lac_adpcm(input &i64, length usize, mut output &u8, capacity usize) i64 {
    unsafe {
        if input == nil || length < 2 || length > 258 { return -1 }
        mode := input[0]
        count := input[1]
        if mode == 1 {
            if count < 0 || count > 256 || length != usize(count) + 2 { return -1 }
            for i in 0 .. int(count) { if input[i + 2] < -32768 || input[i + 2] > 32767 { return -1 } }
        } else if mode == 2 {
            if count < 0 || count > 128 || length != usize(count) + 2 { return -1 }
            for i in 0 .. int(count) { if input[i + 2] < 0 || input[i + 2] > 255 { return -1 } }
        } else { return -1 }

        n := int(count)
        required := if mode == 1 { (n + 1) / 2 } else { n * 4 }
        if required == 0 { return 0 }
        if output == nil || capacity < usize(required) { return -2 }
        mut predictor := i32(0)
        mut index := i32(0)
        if mode == 1 {
            for i in 0 .. n {
                code := encode_one(i32(input[i + 2]), mut predictor, mut index)
                if i & 1 == 0 { output[i / 2] = code << 4 } else { output[i / 2] |= code }
            }
        } else {
            for i in 0 .. n {
                packed := u8(input[i + 2])
                for half in 0 .. 2 {
                    code := if half == 0 { packed >> 4 } else { packed & 15 }
                    sample := decode_one(code, mut predictor, mut index)
                    bits := u16(sample & 65535)
                    position := (i * 2 + half) * 2
                    output[position] = u8(bits & 255)
                    output[position + 1] = u8(bits >> 8)
                }
            }
        }
        return i64(required)
    }
}
