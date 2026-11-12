use std::slice;

const MODULUS: i64 = 998_244_353;
const PRNG_MODULUS: i64 = 2_147_483_647;
const MAX_N: usize = 8;
const MAX_INPUT: usize = 10;
const MAX_PRODUCT: usize = 17;

#[derive(Clone, Copy)]
struct Polynomial {
    coefficients: [i64; MAX_PRODUCT],
    degree: i32,
}

fn zero_poly() -> Polynomial {
    Polynomial { coefficients: [0; MAX_PRODUCT], degree: -1 }
}

fn normalize(value: i64) -> i64 {
    let reduced = value % MODULUS;
    if reduced < 0 { reduced + MODULUS } else { reduced }
}

fn power_mod(mut base: i64, mut exponent: i64) -> i64 {
    let mut result = 1_i64;
    while exponent > 0 {
        if exponent & 1 != 0 { result = result * base % MODULUS; }
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    result
}

fn trim(poly: &mut Polynomial) {
    while poly.degree >= 0 && poly.coefficients[poly.degree as usize] == 0 { poly.degree -= 1; }
}

fn poly_mod(mut value: Polynomial, divisor: &Polynomial) -> Polynomial {
    if divisor.degree <= 0 || value.degree < 0 { return zero_poly(); }
    let inverse = power_mod(divisor.coefficients[divisor.degree as usize], MODULUS - 2);
    while value.degree >= divisor.degree {
        let shift = (value.degree - divisor.degree) as usize;
        let factor = value.coefficients[value.degree as usize] * inverse % MODULUS;
        for i in 0..=divisor.degree as usize {
            value.coefficients[shift + i] = normalize(
                value.coefficients[shift + i] - factor * divisor.coefficients[i]);
        }
        trim(&mut value);
    }
    value
}

fn multiply_mod(left: &Polynomial, right: &Polynomial, modulus_poly: &Polynomial) -> Polynomial {
    if left.degree < 0 || right.degree < 0 { return zero_poly(); }
    let mut product = [0_i64; MAX_PRODUCT];
    for i in 0..=left.degree as usize {
        for j in 0..=right.degree as usize {
            product[i + j] = (product[i + j]
                + left.coefficients[i] * right.coefficients[j]) % MODULUS;
        }
    }
    let mut expanded = zero_poly();
    expanded.degree = left.degree + right.degree;
    expanded.coefficients = product;
    trim(&mut expanded);
    poly_mod(expanded, modulus_poly)
}

fn polynomial_power_mod(mut base: Polynomial, mut exponent: i64, modulus_poly: &Polynomial) -> Polynomial {
    let mut result = zero_poly();
    result.coefficients[0] = 1;
    result.degree = 0;
    base = poly_mod(base, modulus_poly);
    while exponent > 0 {
        if exponent & 1 != 0 { result = multiply_mod(&result, &base, modulus_poly); }
        base = multiply_mod(&base, &base, modulus_poly);
        exponent >>= 1;
    }
    result
}

fn polynomial_gcd(mut left: Polynomial, mut right: Polynomial) -> Polynomial {
    while right.degree >= 0 {
        let remainder = poly_mod(left, &right);
        left = right;
        right = remainder;
    }
    if left.degree < 0 { return left; }
    let inverse = power_mod(left.coefficients[left.degree as usize], MODULUS - 2);
    for i in 0..=left.degree as usize {
        left.coefficients[i] = left.coefficients[i] * inverse % MODULUS;
    }
    left
}

fn divide_exact(mut value: Polynomial, divisor: &Polynomial) -> Polynomial {
    let mut quotient = zero_poly();
    quotient.degree = value.degree - divisor.degree;
    if quotient.degree < 0 { return quotient; }
    let inverse = power_mod(divisor.coefficients[divisor.degree as usize], MODULUS - 2);
    while value.degree >= divisor.degree {
        let shift = (value.degree - divisor.degree) as usize;
        let factor = value.coefficients[value.degree as usize] * inverse % MODULUS;
        quotient.coefficients[shift] = factor;
        for i in 0..=divisor.degree as usize {
            value.coefficients[shift + i] = normalize(
                value.coefficients[shift + i] - factor * divisor.coefficients[i]);
        }
        trim(&mut value);
    }
    trim(&mut quotient);
    quotient
}

fn split_with_affine(polynomial: Polynomial, slope: i64, offset: i64,
    first: &mut Polynomial, second: &mut Polynomial) -> bool {
    let mut affine = zero_poly();
    affine.coefficients[0] = offset;
    affine.coefficients[1] = slope;
    affine.degree = 1;
    affine = poly_mod(affine, &polynomial);
    let mut powered = polynomial_power_mod(affine, (MODULUS - 1) / 2, &polynomial);
    if powered.degree < 0 {
        powered.coefficients[0] = MODULUS - 1;
        powered.degree = 0;
    } else {
        powered.coefficients[0] = normalize(powered.coefficients[0] - 1);
    }
    trim(&mut powered);
    let part = polynomial_gcd(polynomial, powered);
    if part.degree <= 0 || part.degree >= polynomial.degree { return false; }
    *first = part;
    *second = divide_exact(polynomial, &part);
    true
}

fn collect_roots(polynomial: Polynomial, roots: &mut [i64; MAX_N],
    root_count: &mut usize, mut state: i64) {
    if polynomial.degree == 1 {
        roots[*root_count] = normalize(-polynomial.coefficients[0]
            * power_mod(polynomial.coefficients[1], MODULUS - 2));
        *root_count += 1;
        return;
    }
    let mut first = zero_poly();
    let mut second = zero_poly();
    for _ in 0..32 {
        state = state * 48_271 % PRNG_MODULUS;
        let mut slope = state % MODULUS;
        if slope == 0 { slope = 1; }
        state = state * 48_271 % PRNG_MODULUS;
        let offset = state % MODULUS;
        if split_with_affine(polynomial, slope, offset, &mut first, &mut second) {
            collect_roots(first, roots, root_count, state);
            collect_roots(second, roots, root_count, state + 1);
            return;
        }
    }
    for offset in 0..MODULUS {
        if split_with_affine(polynomial, 1, offset, &mut first, &mut second) {
            collect_roots(first, roots, root_count, state);
            collect_roots(second, roots, root_count, state + offset + 1);
            return;
        }
    }
}

fn find_roots(polynomial: Polynomial, roots: &mut [i64; MAX_N]) -> usize {
    if polynomial.degree <= 0 { return 0; }
    let mut x = zero_poly();
    x.coefficients[1] = 1;
    x.degree = 1;
    let x_mod = poly_mod(x, &polynomial);
    let mut x_to_p = polynomial_power_mod(x_mod, MODULUS, &polynomial);
    let largest = x_to_p.degree.max(x_mod.degree);
    if largest >= 0 {
        for i in 0..=largest as usize {
            let left = if i as i32 <= x_to_p.degree { x_to_p.coefficients[i] } else { 0 };
            let right = if i as i32 <= x_mod.degree { x_mod.coefficients[i] } else { 0 };
            x_to_p.coefficients[i] = normalize(left - right);
        }
    }
    x_to_p.degree = largest;
    trim(&mut x_to_p);
    let linear_part = polynomial_gcd(polynomial, x_to_p);
    if linear_part.degree <= 0 { return 0; }
    let mut seed = 1_i64;
    for i in 0..=polynomial.degree as usize {
        seed = (seed * 31 + polynomial.coefficients[i]) % (PRNG_MODULUS - 1) + 1;
    }
    let mut root_count = 0;
    collect_roots(linear_part, roots, &mut root_count, seed);
    roots[..root_count].sort_unstable();
    root_count
}

fn store_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { *output.add(offset + byte) = ((bits >> (8 * byte)) & 255) as u8; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn polynomial_root_finding(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let input = slice::from_raw_parts(input, length);
    if !(0..=MAX_N as i64).contains(&input[0]) || length != input[0] as usize + 2 { return -1; }
    let mut polynomial = zero_poly();
    polynomial.degree = input[0] as i32;
    for i in 0..=polynomial.degree as usize {
        if input[i + 1] < 0 || input[i + 1] >= MODULUS { return -1; }
        polynomial.coefficients[i] = input[i + 1];
    }
    if polynomial.coefficients[polynomial.degree as usize] == 0 { return -1; }
    let mut roots = [0_i64; MAX_N];
    let root_count = find_roots(polynomial, &mut roots);
    let bytes = 8 * (root_count + 1);
    if output.is_null() || capacity < bytes { return -2; }
    store_le(output, 0, root_count as i64);
    for i in 0..root_count { store_le(output, 8 * (i + 1), roots[i]); }
    bytes as i64
}
