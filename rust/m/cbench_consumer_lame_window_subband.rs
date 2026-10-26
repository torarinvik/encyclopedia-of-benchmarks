/*
 * Copyright (c) 1999 Takehiro TOMINAGA
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */
const SAMPLE_COUNT: usize = 511;
const WINDOW_COUNT: usize = 256;
const INPUT_COUNT: usize = 767;
const MAX_INPUT_LENGTH: usize = 768;
const BAND_COUNT: usize = 32;
const OUTPUT_BYTES: usize = 256;
const PI: f64 = 3.14159265358979323846264338327950288;
const S_OFFSETS: [isize; 15] = [334,398,462,14,78,142,206,16,80,144,208,272,336,400,464];
const T_OFFSETS: [isize; 15] = [176,112,48,496,432,368,304,494,430,366,302,238,174,110,46];

fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { output[offset + byte] = (bits >> (8 * byte)) as u8; }
}

fn round_q1000(value: f64) -> i64 {
    let scaled = value * 1000.0;
    let magnitude = if scaled < 0.0 { -scaled } else { scaled };
    let rounded = (magnitude + 0.5) as i64;
    if scaled < 0.0 { -rounded } else { rounded }
}

fn valid(values: &[i64]) -> bool {
    if values.len() != INPUT_COUNT { return false; }
    if values[..SAMPLE_COUNT].iter().any(|&v| !(-32768..=32767).contains(&v)) { return false; }
    if values[SAMPLE_COUNT..].iter().any(|&v| !(-4500000..=36000000).contains(&v)) { return false; }
    if values[SAMPLE_COUNT] <= 25000000 { return false; }
    for index in (8..WINDOW_COUNT).step_by(16) {
        if values[SAMPLE_COUNT + index] <= 25000000 { return false; }
    }
    true
}

fn window_subband(input: &[i64], window: &mut [f64; WINDOW_COUNT]) -> [f64; BAND_COUNT] {
    let maximum = window[248];
    let mut mmax = [0.0_f64; 31];
    let mut mm = [[0.0_f64; 31]; 16];
    let (mut wp, mut wr) = (0_usize, 0_usize);
    let mut w = window[wp]; wp += 1;
    mmax[15] = w / maximum;
    for _ in 0..7 { window[wr] = window[wp] / w; wr += 1; wp += 1; }
    for i in (0..=14).rev() {
        w = window[wp]; wp += 1;
        mmax[i] = w / maximum;
        mmax[30 - i] = w / maximum;
        for _ in 0..15 { window[wr] = window[wp] / w; wr += 1; wp += 1; }
    }
    wp += 1;
    for _ in 0..7 { window[wr] = window[wp] / maximum; wr += 1; wp += 1; }
    for i in (0..=15).rev() {
        for k in 1..32 {
            mm[i][k - 1] = ((((2 * i + 1) * k) as f64 * PI) / 64.0).cos() * mmax[k - 1];
        }
    }

    let mut inner = [0.0_f64; 31];
    let mut coeff = 0_usize;
    let mut t = input[255] as f64;
    t += (input[223] - input[287]) as f64 * window[coeff]; coeff += 1;
    t += (input[191] + input[319]) as f64 * window[coeff]; coeff += 1;
    t += (input[159] - input[351]) as f64 * window[coeff]; coeff += 1;
    t += (input[127] + input[383]) as f64 * window[coeff]; coeff += 1;
    t += (input[95] - input[415]) as f64 * window[coeff]; coeff += 1;
    t += (input[63] + input[447]) as f64 * window[coeff]; coeff += 1;
    t += (input[31] - input[479]) as f64 * window[coeff]; coeff += 1;
    inner[15] = t;
    for i in (0..=14).rev() {
        let mut s = input[(270 - i) as usize] as f64;
        t = input[240 + i] as f64;
        for k in 0..15 {
            w = window[coeff]; coeff += 1;
            let si = (S_OFFSETS[k] + if k < 7 { -(i as isize) } else { i as isize }) as usize;
            let ti = (T_OFFSETS[k] + if k < 7 { i as isize } else { -(i as isize) }) as usize;
            let sv = input[si] as f64 * w;
            let tv = input[ti] as f64 * w;
            if k >= 11 { s -= sv; } else { s += sv; }
            if (7..11).contains(&k) { t -= tv; } else { t += tv; }
        }
        inner[30 - i] = s;
        inner[i] = t;
    }
    let mut s = input[239] as f64;
    s += input[175] as f64 * window[coeff]; coeff += 1;
    s += input[111] as f64 * window[coeff]; coeff += 1;
    s += input[47] as f64 * window[coeff]; coeff += 1;
    s -= input[303] as f64 * window[coeff]; coeff += 1;
    s -= input[367] as f64 * window[coeff]; coeff += 1;
    s -= input[431] as f64 * window[coeff]; coeff += 1;
    s -= input[495] as f64 * window[coeff];

    let mut bands = [0.0_f64; BAND_COUNT];
    for i in (0..=15).rev() {
        let mut s0 = s;
        let mut s1 = t * mm[i][0];
        let mut at = 1_usize;
        for _ in 0..15 {
            s0 += mm[i][at] * inner[at]; at += 1;
            s1 += mm[i][at] * inner[at]; at += 1;
        }
        bands[i] = s0 + s1;
        bands[31 - i] = s0 - s1;
    }
    bands
}

#[no_mangle]
pub unsafe extern "C" fn cbench_consumer_lame_window_subband(
    input: *const i64, input_length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length == 0 || input_length > MAX_INPUT_LENGTH { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    if !valid(values) { return -1; }
    let mut window = [0.0_f64; WINDOW_COUNT];
    for i in 0..WINDOW_COUNT { window[i] = values[SAMPLE_COUNT + i] as f64 / 1_000_000_000.0; }
    let bands = window_subband(values, &mut window);
    let mut staged = [0_i64; BAND_COUNT];
    for i in 0..BAND_COUNT { staged[i] = round_q1000(bands[i]); }
    if output.is_null() || output_capacity < OUTPUT_BYTES { return -2; }
    let out = unsafe { std::slice::from_raw_parts_mut(output, OUTPUT_BYTES) };
    for i in 0..BAND_COUNT { store_i64_le(out, 8 * i, staged[i]); }
    OUTPUT_BYTES as i64
}
