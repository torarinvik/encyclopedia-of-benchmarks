const MAX_N: usize = 8;
const MAX_POLY: usize = MAX_N + 1;
const MAX_FACTORS: usize = MAX_N;
const MAX_INPUT: usize = 12;
const MAX_OUTPUT_BYTES: usize = 216;

type Poly = [i64; MAX_POLY];

#[derive(Clone, Copy)]
struct Factor {
    coefficients: Poly,
    degree: usize,
    multiplicity: i64,
}

const EMPTY_FACTOR: Factor = Factor {
    coefficients: [0; MAX_POLY],
    degree: 0,
    multiplicity: 0,
};

fn power_small(base: usize, exponent: usize) -> usize {
    let mut value = 1;
    for _ in 0..exponent { value *= base; }
    value
}

fn monic_from_code(degree: usize, mut code: usize, prime: usize) -> Poly {
    let mut polynomial = [0; MAX_POLY];
    for i in 0..degree {
        polynomial[i] = (code % prime) as i64;
        code /= prime;
    }
    polynomial[degree] = 1;
    polynomial
}

fn exact_quotient(polynomial: &Poly, degree: usize, divisor: &Poly,
                  divisor_degree: usize, prime: usize) -> Option<Poly> {
    if degree < divisor_degree { return None; }
    let mut remainder = *polynomial;
    let mut quotient = [0; MAX_POLY];
    let quotient_degree = degree - divisor_degree;
    for shift in (0..=quotient_degree).rev() {
        let factor = remainder[shift + divisor_degree];
        quotient[shift] = factor;
        for j in 0..=divisor_degree {
            let mut value = (remainder[shift + j] - factor * divisor[j]) % prime as i64;
            if value < 0 { value += prime as i64; }
            remainder[shift + j] = value;
        }
    }
    if remainder[..divisor_degree].iter().any(|&value| value != 0) {
        None
    } else {
        Some(quotient)
    }
}

fn irreducible(candidate: &Poly, degree: usize, prime: usize) -> bool {
    for divisor_degree in 1..=degree / 2 {
        for code in 0..power_small(prime, divisor_degree) {
            let divisor = monic_from_code(divisor_degree, code, prime);
            if exact_quotient(candidate, degree, &divisor, divisor_degree, prime).is_some() {
                return false;
            }
        }
    }
    true
}

fn factorize(coefficients: &Poly, input_degree: usize, prime: usize) -> ([Factor; MAX_FACTORS], usize) {
    let mut factors = [EMPTY_FACTOR; MAX_FACTORS];
    let mut work = *coefficients;
    let mut work_degree = input_degree;
    let mut factor_count = 0;
    for degree in 1..=input_degree / 2 {
        for code in 0..power_small(prime, degree) {
            let candidate = monic_from_code(degree, code, prime);
            if !irreducible(&candidate, degree, prime) { continue; }
            let mut multiplicity = 0;
            while work_degree >= degree {
                let Some(quotient) = exact_quotient(&work, work_degree, &candidate, degree, prime) else {
                    break;
                };
                work = quotient;
                work_degree -= degree;
                multiplicity += 1;
            }
            if multiplicity != 0 {
                factors[factor_count] = Factor { coefficients: candidate, degree, multiplicity };
                factor_count += 1;
            }
        }
    }
    if work_degree > 0 {
        factors[factor_count] = Factor { coefficients: work, degree: work_degree, multiplicity: 1 };
        factor_count += 1;
    }
    factors[..factor_count].sort_by(|left, right| {
        left.degree.cmp(&right.degree).then_with(|| left.coefficients.cmp(&right.coefficients))
    });
    (factors, factor_count)
}

unsafe fn store_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = ((bits >> (8 * byte)) & 255) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn factorization_of_polynomials(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    let degree_value = input[0];
    let prime_value = input[1];
    if !(0..=MAX_N as i64).contains(&degree_value) ||
        !(prime_value == 2 || prime_value == 3 || prime_value == 5) ||
        length != degree_value as usize + 3 { return -1; }
    let degree = degree_value as usize;
    let prime = prime_value as usize;
    if input[degree + 2] != 1 { return -1; }
    let mut coefficients = [0; MAX_POLY];
    for i in 0..=degree {
        let coefficient = input[i + 2];
        if coefficient < 0 || coefficient >= prime_value { return -1; }
        coefficients[i] = coefficient;
    }

    let (factors, factor_count) = factorize(&coefficients, degree, prime);
    let words = 1 + factors[..factor_count].iter().map(|factor| factor.degree + 3).sum::<usize>();
    let bytes = 8 * words;
    if bytes > MAX_OUTPUT_BYTES { return -1; }
    if output.is_null() || capacity < bytes { return -2; }
    unsafe {
        let mut word = 0;
        store_le(output, 8 * word, factor_count as i64);
        word += 1;
        for factor in &factors[..factor_count] {
            store_le(output, 8 * word, factor.multiplicity);
            word += 1;
            store_le(output, 8 * word, factor.degree as i64);
            word += 1;
            for coefficient in &factor.coefficients[..=factor.degree] {
                store_le(output, 8 * word, *coefficient);
                word += 1;
            }
        }
    }
    bytes as i64
}
