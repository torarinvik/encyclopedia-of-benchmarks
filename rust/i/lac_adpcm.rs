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

const INDEX_TABLE: [i32; 16] = [-1,-1,-1,-1,2,4,6,8,-1,-1,-1,-1,2,4,6,8];
const STEP_TABLE: [i32; 89] = [
    7,8,9,10,11,12,13,14,16,17,19,21,23,25,28,31,34,37,41,45,50,55,60,66,73,80,
    88,97,107,118,130,143,157,173,190,209,230,253,279,307,337,371,408,449,494,544,
    598,658,724,796,876,963,1060,1166,1282,1411,1552,1707,1878,2066,2272,2499,2749,
    3024,3327,3660,4026,4428,4871,5358,5894,6484,7132,7845,8630,9493,10442,11487,
    12635,13899,15289,16818,18500,20350,22385,24623,27086,29794,32767,
];

fn clamp_index(index: i32) -> usize { index.clamp(0, 88) as usize }
fn clamp_sample(sample: i32) -> i32 { sample.clamp(-32768, 32767) }

fn encode_one(sample: i32, predictor: &mut i32, index: &mut usize) -> u8 {
    let mut step = STEP_TABLE[*index];
    let mut diff = sample - *predictor;
    let sign = if diff < 0 { 8 } else { 0 };
    if sign != 0 { diff = -diff; }
    let mut code = 0;
    let mut change = step >> 3;
    if diff >= step { code = 4; diff -= step; change += step; }
    step >>= 1;
    if diff >= step { code |= 2; diff -= step; change += step; }
    step >>= 1;
    if diff >= step { code |= 1; change += step; }
    *predictor = clamp_sample(*predictor + if sign != 0 { -change } else { change });
    code |= sign;
    *index = clamp_index(*index as i32 + INDEX_TABLE[code as usize]);
    code as u8
}

fn decode_one(code: u8, predictor: &mut i32, index: &mut usize) -> i32 {
    let step = STEP_TABLE[*index];
    *index = clamp_index(*index as i32 + INDEX_TABLE[code as usize]);
    let magnitude = (code & 7) as i32;
    let mut change = step >> 3;
    if magnitude & 4 != 0 { change += step; }
    if magnitude & 2 != 0 { change += step >> 1; }
    if magnitude & 1 != 0 { change += step >> 2; }
    *predictor = clamp_sample(*predictor + if code & 8 != 0 { -change } else { change });
    *predictor
}

#[no_mangle]
pub unsafe extern "C" fn lac_adpcm(input: *const i64, input_length: usize,
        output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || input_length < 2 || input_length > 258 { return -1; }
    let mode = *input;
    let count = *input.add(1);
    let n: usize;
    if mode == 1 {
        if !(0..=256).contains(&count) || input_length != count as usize + 2 { return -1; }
        n = count as usize;
        if std::slice::from_raw_parts(input.add(2), n).iter().any(|&x| !(-32768..=32767).contains(&x)) { return -1; }
    } else if mode == 2 {
        if !(0..=128).contains(&count) || input_length != count as usize + 2 { return -1; }
        n = count as usize;
        if std::slice::from_raw_parts(input.add(2), n).iter().any(|&x| !(0..=255).contains(&x)) { return -1; }
    } else { return -1; }

    let required = if mode == 1 { (n + 1) / 2 } else { n * 4 };
    if required == 0 { return 0; }
    if output.is_null() || output_capacity < required { return -2; }
    let mut predictor = 0i32;
    let mut index = 0usize;
    if mode == 1 {
        for i in 0..n {
            let code = encode_one(*input.add(i + 2) as i32, &mut predictor, &mut index);
            if i & 1 == 0 { *output.add(i / 2) = code << 4; }
            else { *output.add(i / 2) |= code; }
        }
    } else {
        for i in 0..n {
            let packed = *input.add(i + 2) as u8;
            for half in 0..2 {
                let code = if half == 0 { packed >> 4 } else { packed & 15 };
                let bits = decode_one(code, &mut predictor, &mut index) as u16;
                let position = (i * 2 + half) * 2;
                *output.add(position) = bits as u8;
                *output.add(position + 1) = (bits >> 8) as u8;
            }
        }
    }
    required as i64
}
