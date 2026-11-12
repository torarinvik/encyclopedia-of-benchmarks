const MAX_T: usize = 8;
const MAX_COMPONENT: i64 = 1_000_000;

fn nearest_quotient(numerator: i64, denominator: i64) -> i64 {
    let sign: i64 = if numerator < 0 { -1 } else { 1 };
    let magnitude = numerator.abs();
    let mut quotient = magnitude / denominator;
    let remainder = magnitude % denominator;
    if 2 * remainder >= denominator {
        quotient += 1;
    }
    sign * quotient
}

fn gaussian_gcd(mut ar: i64, mut ai: i64, mut br: i64, mut bi: i64) -> (i64, i64) {
    while br != 0 || bi != 0 {
        let denominator = br * br + bi * bi;
        let qr = nearest_quotient(ar * br + ai * bi, denominator);
        let qi = nearest_quotient(ai * br - ar * bi, denominator);
        let rr = ar - (qr * br - qi * bi);
        let ri = ai - (qr * bi + qi * br);
        ar = br;
        ai = bi;
        br = rr;
        bi = ri;
    }
    if ar != 0 || ai != 0 {
        for _ in 0..4 {
            if ar > 0 && ai >= 0 {
                break;
            }
            (ar, ai) = (-ai, ar);
        }
    }
    (ar, ai)
}

unsafe fn write_u32(output: *mut u8, offset: usize, value: u32) {
    *output.add(offset) = value as u8;
    *output.add(offset + 1) = (value >> 8) as u8;
    *output.add(offset + 2) = (value >> 16) as u8;
    *output.add(offset + 3) = (value >> 24) as u8;
}

#[no_mangle]
pub unsafe extern "C" fn gcd_of_gaussian_integers(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 5 || length > 1 + 4 * MAX_T {
        return -1;
    }
    let t64 = *input;
    if t64 < 1 || t64 > MAX_T as i64 {
        return -1;
    }
    let t = t64 as usize;
    if length != 1 + 4 * t {
        return -1;
    }

    let mut values = [0_i64; 4 * MAX_T];
    for index in 0..4 * t {
        let value = *input.add(index + 1);
        if !(-MAX_COMPONENT..=MAX_COMPONENT).contains(&value) {
            return -1;
        }
        values[index] = value;
    }
    let required = 8 * t;
    if output.is_null() || capacity < required {
        return -2;
    }

    for test in 0..t {
        let (real, imaginary) = gaussian_gcd(
            values[4 * test], values[4 * test + 1],
            values[4 * test + 2], values[4 * test + 3],
        );
        write_u32(output, 8 * test, real as u32);
        write_u32(output, 8 * test + 4, imaginary as u32);
    }
    required as i64
}
