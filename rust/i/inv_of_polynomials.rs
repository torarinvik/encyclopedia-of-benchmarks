const MODULUS: i64 = 998_244_353;
const MAX_LENGTH: usize = 6;
const MAX_INPUT: usize = 14;
const CAPACITY: usize = 16;
type Poly = [i64; CAPACITY];

fn power_mod(mut base: i64, mut exponent: i64) -> i64 {
    let mut result = 1_i64;
    while exponent > 0 {
        if exponent % 2 != 0 { result = result * base % MODULUS; }
        base = base * base % MODULUS;
        exponent /= 2;
    }
    result
}

fn trim(poly: &Poly, mut length: usize) -> usize {
    while length > 0 && poly[length - 1] == 0 { length -= 1; }
    length
}

fn divide_poly(dividend: &Poly, dividend_length: usize, divisor: &Poly, divisor_length: usize)
    -> (Poly, usize, Poly, usize) {
    let mut quotient = [0_i64; CAPACITY];
    let mut remainder = *dividend;
    let mut remainder_length = trim(&remainder, dividend_length);
    if remainder_length >= divisor_length {
        let inverse_lead = power_mod(divisor[divisor_length - 1], MODULUS - 2);
        while remainder_length >= divisor_length {
            let shift = remainder_length - divisor_length;
            let factor = remainder[remainder_length - 1] * inverse_lead % MODULUS;
            quotient[shift] = factor;
            for j in 0..divisor_length {
                let mut value = (remainder[shift + j] - factor * divisor[j]) % MODULUS;
                if value < 0 { value += MODULUS; }
                remainder[shift + j] = value;
            }
            remainder_length = trim(&remainder, remainder_length);
        }
    }
    let quotient_bound = if dividend_length >= divisor_length { dividend_length - divisor_length + 1 } else { 0 };
    let quotient_length = trim(&quotient, quotient_bound);
    (quotient, quotient_length, remainder, remainder_length)
}

fn multiply(left: &Poly, left_length: usize, right: &Poly, right_length: usize) -> (Poly, usize) {
    let mut product = [0_i64; CAPACITY];
    if left_length == 0 || right_length == 0 { return (product, 0); }
    for i in 0..left_length {
        for j in 0..right_length {
            if i + j < CAPACITY {
                product[i + j] = (product[i + j] + left[i] * right[j]) % MODULUS;
            }
        }
    }
    let bound = (left_length + right_length - 1).min(CAPACITY);
    let length = trim(&product, bound);
    (product, length)
}

fn subtract(left: &Poly, left_length: usize, right: &Poly, right_length: usize) -> (Poly, usize) {
    let mut difference = [0_i64; CAPACITY];
    let bound = left_length.max(right_length);
    for i in 0..bound {
        let a = if i < left_length { left[i] } else { 0 };
        let b = if i < right_length { right[i] } else { 0 };
        difference[i] = (a - b + MODULUS) % MODULUS;
    }
    let length = trim(&difference, bound);
    (difference, length)
}

unsafe fn store_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = ((bits >> (8 * byte)) & 255) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn inv_of_polynomials(input: *const i64, length: usize,
                                               output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if input[0] < 1 || input[0] > MAX_LENGTH as i64 || input[1] < 1 || input[1] > MAX_LENGTH as i64 { return -1; }
    let n = input[0] as usize;
    let m = input[1] as usize;
    if length != 2 + n + m { return -1; }
    let mut f = [0_i64; CAPACITY];
    let mut g = [0_i64; CAPACITY];
    for i in 0..n {
        f[i] = input[2 + i];
        if f[i] < 0 || f[i] >= MODULUS { return -1; }
    }
    for i in 0..m {
        g[i] = input[2 + n + i];
        if g[i] < 0 || g[i] >= MODULUS { return -1; }
    }
    if f[n - 1] == 0 || g[m - 1] == 0 { return -1; }

    let mut inverse = [0_i64; CAPACITY];
    let mut inverse_length = 0;
    if m > 1 {
        let initial = divide_poly(&f, n, &g, m);
        let mut r0 = g;
        let mut r0_length = m;
        let mut r1 = initial.2;
        let mut r1_length = initial.3;
        let mut s0 = [0_i64; CAPACITY];
        let mut s0_length = 0;
        let mut s1 = [0_i64; CAPACITY];
        s1[0] = 1;
        let mut s1_length = 1;
        while r1_length > 0 {
            let division = divide_poly(&r0, r0_length, &r1, r1_length);
            let product = multiply(&division.0, division.1, &s1, s1_length);
            let next_s = subtract(&s0, s0_length, &product.0, product.1);
            r0 = r1;
            r0_length = r1_length;
            r1 = division.2;
            r1_length = division.3;
            s0 = s1;
            s0_length = s1_length;
            s1 = next_s.0;
            s1_length = next_s.1;
        }
        if r0_length != 1 { return -1; }
        let scale = power_mod(r0[0], MODULUS - 2);
        for i in 0..s0_length { inverse[i] = s0[i] * scale % MODULUS; }
        inverse_length = trim(&inverse, s0_length);
    }

    let bytes = 8 * inverse_length;
    if output.is_null() || capacity < bytes { return -2; }
    for i in 0..inverse_length { unsafe { store_le(output, 8 * i, inverse[i]); } }
    bytes as i64
}
