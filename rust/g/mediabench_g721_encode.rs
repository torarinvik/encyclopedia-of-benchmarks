/*
 * This source code is a product of Sun Microsystems, Inc. and is provided
 * for unrestricted use.  Users may copy or modify this source code without
 * charge.
 *
 * SUN SOURCE CODE IS PROVIDED AS IS WITH NO WARRANTIES OF ANY KIND INCLUDING
 * THE WARRANTIES OF DESIGN, MERCHANTIBILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE, OR ARISING FROM A COURSE OF DEALING, USAGE OR TRADE PRACTICE.
 *
 * Sun source code is provided with no support and without any obligation on
 * the part of Sun Microsystems, Inc. to assist in its use, correction,
 * modification or enhancement.
 *
 * SUN MICROSYSTEMS, INC. SHALL HAVE NO LIABILITY WITH RESPECT TO THE
 * INFRINGEMENT OF COPYRIGHTS, TRADE SECRETS OR ANY PATENTS BY THIS SOFTWARE
 * OR ANY PART THEREOF.
 *
 * In no event will Sun Microsystems, Inc. be liable for any lost revenue
 * or profits or other special, indirect and consequential damages, even if
 * Sun has been advised of the possibility of such damages.
 *
 * Sun Microsystems, Inc.
 * 2550 Garcia Avenue
 * Mountain View, California  94043
 */

const MAX_SAMPLES: usize = 16;
const POWER2: [i64; 15] = [1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384];
const QTAB: [i64; 7] = [-124,80,178,246,300,349,400];
const DQLNTAB: [i64; 16] = [-2048,4,135,213,273,323,373,425,425,373,323,273,213,135,4,-2048];
const WITAB: [i64; 16] = [-12,18,41,64,112,198,355,1122,1122,355,198,112,64,41,18,-12];
const FITAB: [i64; 16] = [0,0,0,512,512,512,1536,3584,3584,1536,512,512,512,0,0,0];

struct State { yl: i64, yu: i64, dms: i64, dml: i64, ap: i64, a: [i64; 2], b: [i64; 6], pk: [i64; 2], dq: [i64; 6], sr: [i64; 2], td: i64 }

fn wrap16(value: i64) -> i64 { let low = (value as u64) & 0xffff; if low >= 0x8000 { low as i64 - 65536 } else { low as i64 } }
fn quant_table(value: i64, table: &[i64]) -> i64 { table.iter().take_while(|&&entry| value >= entry).count() as i64 }
fn fmult(coefficient: i64, encoded: i64) -> i64 {
    let magnitude = if coefficient > 0 { coefficient } else { (-coefficient) & 0x1fff };
    let exponent = quant_table(magnitude, &POWER2) - 6;
    let mantissa = if magnitude == 0 { 32 } else if exponent >= 0 { magnitude >> exponent } else { magnitude << (-exponent as u32) };
    let product_exponent = exponent + ((encoded >> 6) & 15) - 13;
    let product_mantissa = (mantissa * (encoded & 0o77) + 0x30) >> 4;
    let result = if product_exponent >= 0 { (product_mantissa << product_exponent) & 0x7fff } else { product_mantissa >> (-product_exponent as u32) };
    if (coefficient ^ encoded) < 0 { -result } else { result }
}
fn predictor_zero(s: &State) -> i64 { let mut sum = fmult(s.b[0] >> 2, s.dq[0]); for i in 1..6 { sum += fmult(s.b[i] >> 2, s.dq[i]); } sum }
fn predictor_pole(s: &State) -> i64 { fmult(s.a[1] >> 2, s.sr[1]) + fmult(s.a[0] >> 2, s.sr[0]) }
fn step_size(s: &State) -> i64 {
    if s.ap >= 256 { return s.yu; }
    let mut y = s.yl >> 6; let difference = s.yu - y; let weight = s.ap >> 2;
    if difference > 0 { y += (difference * weight) >> 6; } else if difference < 0 { y += (difference * weight + 0x3f) >> 6; }
    y
}
fn quantize(difference: i64, step: i64) -> i64 {
    let magnitude = if difference < 0 { -difference } else { difference };
    let exponent = quant_table(magnitude >> 1, &POWER2);
    let mantissa = ((magnitude << 7) >> exponent) & 0x7f;
    let normalized = ((exponent << 7) + mantissa) - (step >> 2);
    let index = quant_table(normalized, &QTAB);
    if difference < 0 { 15 - index } else if index == 0 { 15 } else { index }
}
fn reconstruct(sign: i64, dqln: i64, step: i64) -> i64 {
    let dql = dqln + (step >> 2);
    if dql < 0 { return if sign != 0 { -32768 } else { 0 }; }
    let exponent = (dql >> 7) & 15; let mantissa = 128 + (dql & 127);
    let value = (mantissa << 7) >> (14 - exponent);
    if sign != 0 { value - 32768 } else { value }
}
fn abs64(value: i64) -> i64 { if value < 0 { -value } else { value } }
fn update(step: i64, wi: i64, fi: i64, dq: i64, sr: i64, dqsez: i64, s: &mut State) {
    let mag = dq & 0x7fff; let ylint = s.yl >> 15; let ylfrac = (s.yl >> 10) & 0x1f;
    let thr1 = (32 + ylfrac) << ylint; let thr2 = if ylint > 9 { 31 << 10 } else { thr1 };
    let dqthr = (thr2 + (thr2 >> 1)) >> 1; let tr = s.td != 0 && mag > dqthr;
    s.yu = wrap16(step + ((wi - step) >> 5)); if s.yu < 544 { s.yu = 544; } else if s.yu > 5120 { s.yu = 5120; }
    s.yl += s.yu + ((-s.yl) >> 6);
    if tr { s.a = [0; 2]; s.b = [0; 6]; }
    else {
        let pk0 = if dqsez < 0 { 1 } else { 0 }; let pks1 = pk0 ^ s.pk[0]; let mut a2p = s.a[1] - (s.a[1] >> 7);
        if dqsez != 0 {
            let fa1 = if pks1 != 0 { s.a[0] } else { -s.a[0] };
            if fa1 < -8191 { a2p -= 0x100; } else if fa1 > 8191 { a2p += 0xff; } else { a2p += fa1 >> 5; }
            if (pk0 ^ s.pk[1]) != 0 {
                if a2p <= -12160 { a2p = -12288; } else if a2p >= 12416 { a2p = 12288; } else { a2p -= 0x80; }
            } else if a2p <= -12416 { a2p = -12288; } else if a2p >= 12160 { a2p = 12288; } else { a2p += 0x80; }
        }
        a2p = wrap16(a2p); s.a[1] = a2p; s.a[0] = wrap16(s.a[0] - (s.a[0] >> 8));
        if dqsez != 0 { s.a[0] = wrap16(s.a[0] + if pks1 == 0 { 192 } else { -192 }); }
        let limit = 15360 - a2p; if s.a[0] < -limit { s.a[0] = -limit; } else if s.a[0] > limit { s.a[0] = limit; }
        s.a[0] = wrap16(s.a[0]);
        for i in 0..6 { s.b[i] = wrap16(s.b[i] - (s.b[i] >> 8)); if dq & 0x7fff != 0 { s.b[i] = wrap16(s.b[i] + if (dq ^ s.dq[i]) >= 0 { 128 } else { -128 }); } }
    }
    for i in (1..6).rev() { s.dq[i] = s.dq[i - 1]; }
    if mag == 0 { s.dq[0] = if dq >= 0 { 0x20 } else { wrap16(0xfc20) }; }
    else { let e = quant_table(mag, &POWER2); let z = (e << 6) + ((mag << 6) >> e); s.dq[0] = wrap16(if dq >= 0 { z } else { z - 0x400 }); }
    s.sr[1] = s.sr[0];
    if sr == 0 { s.sr[0] = 0x20; }
    else if sr > 0 { let e = quant_table(sr, &POWER2); s.sr[0] = wrap16((e << 6) + ((sr << 6) >> e)); }
    else if sr > -32768 { let m = -sr; let e = quant_table(m, &POWER2); s.sr[0] = wrap16((e << 6) + ((m << 6) >> e) - 0x400); }
    else { s.sr[0] = wrap16(0xfc20); }
    s.pk[1] = s.pk[0]; s.pk[0] = if dqsez < 0 { 1 } else { 0 }; s.td = if tr { 0 } else if s.a[1] < -11776 { 1 } else { 0 };
    s.dms = wrap16(s.dms + ((fi - s.dms) >> 5)); s.dml = wrap16(s.dml + (((fi << 2) - s.dml) >> 7));
    if tr { s.ap = 256; } else if step < 1536 || s.td == 1 || abs64((s.dms << 2) - s.dml) >= (s.dml >> 3) { s.ap = wrap16(s.ap + ((0x200 - s.ap) >> 4)); }
    else { s.ap = wrap16(s.ap + ((-s.ap) >> 4)); }
}
fn init_state() -> State { State { yl:34816,yu:544,dms:0,dml:0,ap:0,a:[0;2],b:[0;6],pk:[0;2],dq:[32;6],sr:[32;2],td:0 } }
fn ulaw_to_linear(input: i64) -> i64 { let value = (!input) & 0xff; let mut t = ((value & 15) << 3) + 0x84; t <<= (value & 0x70) >> 4; if value & 0x80 != 0 { 0x84 - t } else { t - 0x84 } }
fn encode_one(input: i64, s: &mut State) -> i64 {
    let sample = ulaw_to_linear(input) >> 2; let sezi = wrap16(predictor_zero(s)); let sez = sezi >> 1;
    let se = wrap16((sezi + predictor_pole(s)) >> 1); let d = wrap16(sample - se); let y = wrap16(step_size(s));
    let code = quantize(d,y); let dq = wrap16(reconstruct(code & 8,DQLNTAB[code as usize],y));
    let sr = wrap16(if dq < 0 { se - (dq & 0x3fff) } else { se + dq }); let dqsez = wrap16(sr + sez - se);
    update(y,WITAB[code as usize] << 5,FITAB[code as usize],dq,sr,dqsez,s); code
}

#[no_mangle]
pub unsafe extern "C" fn mediabench_g721_encode(input: *const i64, input_length: usize, output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || input_length < 1 || input_length > MAX_SAMPLES + 1 { return -1; }
    let count_value = *input;
    if count_value < 0 || count_value > MAX_SAMPLES as i64 { return -1; }
    let count = count_value as usize;
    if input_length != count + 1 { return -1; }
    for i in 0..count { let value = *input.add(i + 1); if !(0..=255).contains(&value) { return -1; } }
    let required = (count + 1) / 2;
    if required == 0 { return 0; }
    if output.is_null() || output_capacity < required { return -2; }
    let mut state = init_state();
    for i in 0..count { let code = encode_one(*input.add(i + 1), &mut state) as u8; if i & 1 == 0 { *output.add(i / 2) = code; } else { *output.add(i / 2) |= code << 4; } }
    required as i64
}
