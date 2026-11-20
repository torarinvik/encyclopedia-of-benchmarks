const FIELD: i32 = 7;
const MAX_N: usize = 7;
const MAX_POLYNOMIAL: usize = 16;
const MAX_INPUT_LENGTH: usize = 11;

#[derive(Clone, Copy)]
struct Polynomial {
    coefficients: [i32; MAX_POLYNOMIAL],
    length: usize,
}

fn normalize(value: i32) -> i32 {
    value.rem_euclid(FIELD)
}

fn zero_polynomial() -> Polynomial {
    Polynomial { coefficients: [0; MAX_POLYNOMIAL], length: 1 }
}

fn constant_polynomial(value: i32) -> Polynomial {
    let mut result = zero_polynomial();
    result.coefficients[0] = normalize(value);
    result
}

fn trim(polynomial: &mut Polynomial) {
    while polynomial.length > 1 && polynomial.coefficients[polynomial.length - 1] == 0 {
        polynomial.length -= 1;
    }
}

fn is_zero(polynomial: &Polynomial) -> bool {
    polynomial.length == 1 && polynomial.coefficients[0] == 0
}

fn multiply_linear(polynomial: Polynomial, root: i32) -> Polynomial {
    let mut result = zero_polynomial();
    result.length = polynomial.length + 1;
    for degree in 0..polynomial.length {
        result.coefficients[degree] = normalize(
            result.coefficients[degree] - root * polynomial.coefficients[degree],
        );
        result.coefficients[degree + 1] = normalize(
            result.coefficients[degree + 1] + polynomial.coefficients[degree],
        );
    }
    trim(&mut result);
    result
}

fn add_scaled(mut target: Polynomial, source: Polynomial, scale: i32) -> Polynomial {
    target.length = target.length.max(source.length);
    for degree in 0..source.length {
        target.coefficients[degree] = normalize(
            target.coefficients[degree] + scale * source.coefficients[degree],
        );
    }
    trim(&mut target);
    target
}

fn multiply(left: Polynomial, right: Polynomial) -> Polynomial {
    let mut result = zero_polynomial();
    result.length = left.length + right.length - 1;
    for i in 0..left.length {
        for j in 0..right.length {
            result.coefficients[i + j] = normalize(
                result.coefficients[i + j] + left.coefficients[i] * right.coefficients[j],
            );
        }
    }
    trim(&mut result);
    result
}

fn divide_with_remainder(numerator: Polynomial, denominator: Polynomial) -> Option<(Polynomial, Polynomial)> {
    const INVERSE: [i32; 7] = [0, 1, 4, 5, 2, 3, 6];
    if is_zero(&denominator) { return None; }
    let mut quotient = zero_polynomial();
    let mut remainder = numerator;
    trim(&mut remainder);
    let mut divisor = denominator;
    trim(&mut divisor);
    let inverse_lead = INVERSE[divisor.coefficients[divisor.length - 1] as usize];
    while !is_zero(&remainder) && remainder.length >= divisor.length {
        let shift = remainder.length - divisor.length;
        let factor = normalize(remainder.coefficients[remainder.length - 1] * inverse_lead);
        if quotient.length < shift + 1 { quotient.length = shift + 1; }
        quotient.coefficients[shift] = normalize(quotient.coefficients[shift] + factor);
        for degree in 0..divisor.length {
            remainder.coefficients[shift + degree] = normalize(
                remainder.coefficients[shift + degree] - factor * divisor.coefficients[degree],
            );
        }
        trim(&mut remainder);
    }
    trim(&mut quotient);
    Some((quotient, remainder))
}

fn interpolate(n: usize, received: &[i32; MAX_N]) -> (Polynomial, Polynomial) {
    let mut vanishing = constant_polynomial(1);
    for point in 0..n {
        vanishing = multiply_linear(vanishing, point as i32);
    }

    const INVERSE: [i32; 7] = [0, 1, 4, 5, 2, 3, 6];
    let mut interpolant = zero_polynomial();
    for i in 0..n {
        let mut basis = constant_polynomial(1);
        let mut denominator = 1i32;
        for j in 0..n {
            if i == j { continue; }
            basis = multiply_linear(basis, j as i32);
            denominator = normalize(denominator * (i as i32 - j as i32));
        }
        let scale = normalize(received[i] * INVERSE[denominator as usize]);
        interpolant = add_scaled(interpolant, basis, scale);
    }
    (vanishing, interpolant)
}

fn decode(n: usize, k: usize, error_limit: usize, received: &[i32; MAX_N]) -> i64 {
    let (vanishing, interpolant) = interpolate(n, received);
    if is_zero(&interpolant) { return 1; }

    let mut remainder_previous = vanishing;
    let mut remainder_current = interpolant;
    let mut bezout_previous = zero_polynomial();
    let mut bezout_current = constant_polynomial(1);
    let threshold = (n + k - 1) / 2;
    while !is_zero(&remainder_current) && remainder_current.length - 1 > threshold {
        let Some((quotient, remainder_next)) = divide_with_remainder(remainder_previous, remainder_current) else {
            return 0;
        };
        let product = multiply(quotient, bezout_current);
        let bezout_next = add_scaled(bezout_previous, product, -1);
        remainder_previous = remainder_current;
        remainder_current = remainder_next;
        bezout_previous = bezout_current;
        bezout_current = bezout_next;
    }
    if is_zero(&remainder_current) || is_zero(&bezout_current) { return 0; }

    let Some((mut message, remainder)) = divide_with_remainder(remainder_current, bezout_current) else {
        return 0;
    };
    if !is_zero(&remainder) { return 0; }
    trim(&mut message);
    if message.length > k { return 0; }

    let mut mismatches = 0usize;
    for (x, &symbol) in received[..n].iter().enumerate() {
        let mut value = 0i32;
        for degree in (0..message.length).rev() {
            value = (value * x as i32 + message.coefficients[degree]) % FIELD;
        }
        if value != symbol { mismatches += 1; }
    }
    if mismatches > error_limit { return 0; }

    let mut encoded = 1i64;
    let mut place = 1i64;
    for degree in 0..k {
        if degree < message.length {
            encoded += i64::from(message.coefficients[degree]) * place;
        }
        place *= i64::from(FIELD);
    }
    encoded
}

#[no_mangle]
pub unsafe extern "C" fn gao_rs_decode(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_LENGTH { return -1; }
    let values = core::slice::from_raw_parts(input, length);
    let n_value = values[0];
    let k_value = values[1];
    let error_value = values[2];
    if !(2..=7).contains(&n_value) || !(1..=3).contains(&k_value)
        || k_value > n_value || !(0..=2).contains(&error_value) {
        return -1;
    }
    let n = n_value as usize;
    let k = k_value as usize;
    let error_limit = error_value as usize;
    if 2 * error_limit > n - k || length != 3 + n { return -1; }

    let mut received = [0i32; MAX_N];
    for index in 0..n {
        let symbol = values[3 + index];
        if !(0..7).contains(&symbol) { return -1; }
        received[index] = symbol as i32;
    }
    decode(n, k, error_limit, &received)
}
