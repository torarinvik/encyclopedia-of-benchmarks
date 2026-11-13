const STAGE1_PRIMES: [i64; 11] = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31];

#[derive(Clone, Copy)]
struct XPoint {
    x: i64,
    z: i64,
}

fn mod_norm(value: i64, modulus: i64) -> i64 {
    value.rem_euclid(modulus)
}

fn gcd_i64(mut left: i64, mut right: i64) -> i64 {
    left = left.abs();
    right = right.abs();
    while right != 0 {
        let remainder = left % right;
        left = right;
        right = remainder;
    }
    left
}

fn square_free(number: i64) -> bool {
    let mut divisor = 2i64;
    while divisor * divisor <= number {
        if number % (divisor * divisor) == 0 {
            return false;
        }
        divisor += 1;
    }
    true
}

fn x_double(point: XPoint, a24: i64, modulus: i64) -> XPoint {
    let plus = mod_norm(point.x + point.z, modulus);
    let minus = mod_norm(point.x - point.z, modulus);
    let plus_sq = plus * plus % modulus;
    let minus_sq = minus * minus % modulus;
    let delta = mod_norm(plus_sq - minus_sq, modulus);
    XPoint {
        x: plus_sq * minus_sq % modulus,
        z: delta * mod_norm(minus_sq + a24 * delta, modulus) % modulus,
    }
}

fn x_add(left: XPoint, right: XPoint, difference: XPoint, modulus: i64) -> XPoint {
    let first = mod_norm(left.x - left.z, modulus)
        * mod_norm(right.x + right.z, modulus) % modulus;
    let second = mod_norm(left.x + left.z, modulus)
        * mod_norm(right.x - right.z, modulus) % modulus;
    let sum_term = mod_norm(first + second, modulus);
    let difference_term = mod_norm(first - second, modulus);
    XPoint {
        x: difference.z * sum_term % modulus * sum_term % modulus,
        z: difference.x * difference_term % modulus * difference_term % modulus,
    }
}

fn x_multiply(point: XPoint, scalar: i64, a24: i64, modulus: i64) -> XPoint {
    let mut r0 = XPoint { x: 1, z: 0 };
    let mut r1 = point;
    let highest = (i64::BITS - 1 - scalar.leading_zeros()) as i32;
    for bit in (0..=highest).rev() {
        if scalar & (1i64 << bit) != 0 {
            r0 = x_add(r0, r1, point, modulus);
            r1 = x_double(r1, a24, modulus);
        } else {
            r1 = x_add(r0, r1, point, modulus);
            r0 = x_double(r0, a24, modulus);
        }
    }
    r0
}

#[no_mangle]
pub unsafe extern "C" fn elliptic_curve_method_stage1(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 5 {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let (number, curve_a, point_x, point_y, bound) =
        (values[0], values[1], values[2], values[3], values[4]);
    if number < 3 || number > 10_000 || number % 2 == 0 || !(2..=32).contains(&bound)
        || !(0..number).contains(&curve_a) || !(0..number).contains(&point_x)
        || !(0..number).contains(&point_y) || !square_free(number)
    {
        return -1;
    }
    if gcd_i64(curve_a * curve_a - 4, number) != 1 {
        return -1;
    }
    let x_sq = point_x * point_x % number;
    let rhs = (x_sq * point_x + curve_a * x_sq + point_x) % number;
    if point_y * point_y % number != rhs {
        return -1;
    }
    let inverse_four = if number % 4 == 3 {
        (number + 1) / 4
    } else {
        (3 * number + 1) / 4
    };
    let a24 = (curve_a + 2) * inverse_four % number;
    let mut point = XPoint { x: point_x, z: 1 };
    for prime in STAGE1_PRIMES {
        if prime > bound {
            break;
        }
        let mut prime_power = prime;
        while prime_power <= bound / prime {
            prime_power *= prime;
        }
        point = x_multiply(point, prime_power, a24, number);
        let divisor = gcd_i64(point.z, number);
        if divisor > 1 {
            return if divisor < number { 1 } else { 0 };
        }
    }
    0
}
