// Rodinia SRAD v2 bounded two-kernel profile; full source license and citations:
// benchmarks/r/rodinia_srad_v2/LICENSE.txt.
const PIXELS: usize = 256;
const INPUTS: usize = 258;
const LAMBDA_MIN: u32 = 0x3c23d70a;
const LAMBDA_MAX: u32 = 0x3dcccccd;
const Q0_MIN: u32 = 0x3c23d70a;
const Q0_MAX: u32 = 0x3f800000;
const J_MIN: u32 = 0x3f800000;
const J_MAX: u32 = 0x3fa00000;

#[inline(never)] fn add32(a: f32, b: f32) -> f32 { a + b }
#[inline(never)] fn sub32(a: f32, b: f32) -> f32 { a - b }
#[inline(never)] fn mul32(a: f32, b: f32) -> f32 { a * b }
#[inline(never)] fn div32(a: f32, b: f32) -> f32 { a / b }

#[no_mangle]
pub unsafe extern "C" fn rodinia_srad_v2(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != INPUTS { return -1; }
    let v = unsafe { std::slice::from_raw_parts(values, length) };
    if v.iter().any(|&x| x < 0 || x > u32::MAX as i64) { return -1; }
    let lambda_bits = v[0] as u32;
    let q0_bits = v[1] as u32;
    if !(LAMBDA_MIN..=LAMBDA_MAX).contains(&lambda_bits) || !(Q0_MIN..=Q0_MAX).contains(&q0_bits) { return -1; }
    let lambda = f32::from_bits(lambda_bits);
    let q0sqr = f32::from_bits(q0_bits);
    let mut image = [0.0f32; PIXELS];
    let mut coeff = [0.0f32; PIXELS];
    let mut north = [0.0f32; PIXELS];
    let mut south = [0.0f32; PIXELS];
    let mut west = [0.0f32; PIXELS];
    let mut east = [0.0f32; PIXELS];
    for i in 0..PIXELS {
        let bits = v[i + 2] as u32;
        if !(J_MIN..=J_MAX).contains(&bits) { return -1; }
        image[i] = f32::from_bits(bits);
    }

    for row in 0..16 {
        for col in 0..16 {
            let i = row * 16 + col;
            let jc = image[i];
            let n = sub32(image[(if row > 0 { row - 1 } else { row }) * 16 + col], jc);
            let s = sub32(image[(if row < 15 { row + 1 } else { row }) * 16 + col], jc);
            let w = sub32(image[row * 16 + (if col > 0 { col - 1 } else { col })], jc);
            let e = sub32(image[row * 16 + (if col < 15 { col + 1 } else { col })], jc);
            north[i] = n; south[i] = s; west[i] = w; east[i] = e;
            let mut gradient = add32(add32(add32(mul32(n,n),mul32(s,s)),mul32(w,w)),mul32(e,e));
            gradient = div32(gradient,mul32(jc,jc));
            let laplacian = div32(add32(add32(add32(n,s),w),e),jc);
            let lap_sq = mul32(laplacian,laplacian);
            let num = (0.5f64 * f64::from(gradient) - (1.0f64/16.0f64) * f64::from(lap_sq)) as f32;
            let mut den = (1.0f64 + 0.25f64 * f64::from(laplacian)) as f32;
            if den == 0.0 { return -1; }
            let qsqr = div32(num,mul32(den,den));
            den = div32(sub32(qsqr,q0sqr),mul32(q0sqr,add32(1.0,q0sqr)));
            if den == -1.0 { return -1; }
            let c = (1.0f64 / (1.0f64 + f64::from(den))) as f32;
            if !c.is_finite() { return -1; }
            coeff[i] = c.max(0.0).min(1.0);
        }
    }

    let mut checksum = 0i64;
    for row in 0..16 {
        for col in 0..16 {
            let i = row * 16 + col;
            let cc = coeff[i];
            let cs = coeff[(if row < 15 { row + 1 } else { row }) * 16 + col];
            let ce = coeff[row * 16 + (if col < 15 { col + 1 } else { col })];
            let divergence = add32(add32(add32(mul32(cc,north[i]),mul32(cs,south[i])),mul32(cc,west[i])),mul32(ce,east[i]));
            let updated = (f64::from(image[i]) + 0.25f64 * f64::from(lambda) * f64::from(divergence)) as f32;
            if !updated.is_finite() || updated < 0.0 { return -1; }
            checksum += (f64::from(updated) * 1_000_000.0 + 0.5) as i64;
        }
    }
    checksum
}
