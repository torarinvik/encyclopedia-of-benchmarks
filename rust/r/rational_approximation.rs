const MAX_COMPONENT: i64 = 1_000_000_000;

#[derive(Clone, Copy)]
struct Bounds {
    lower_numerator: i64,
    lower_denominator: i64,
    upper_numerator: i64,
    upper_denominator: i64,
}

fn gcd_positive(mut left: i64, mut right: i64) -> i64 {
    while right != 0 {
        let remainder = left % right;
        left = right;
        right = remainder;
    }
    left
}

fn bounded_neighbors(limit: i64, x: i64, y: i64) -> Bounds {
    let divisor = gcd_positive(x, y);
    let reduced_x = x / divisor;
    let reduced_y = y / divisor;
    if reduced_x <= limit && reduced_y <= limit {
        return Bounds {
            lower_numerator: reduced_x,
            lower_denominator: reduced_y,
            upper_numerator: reduced_x,
            upper_denominator: reduced_y,
        };
    }

    let (mut a, mut b) = (0i64, 1i64);
    let (mut c, mut d) = (1i64, 0i64);
    loop {
        let middle_numerator = a + c;
        let middle_denominator = b + d;
        if middle_numerator > limit || middle_denominator > limit { break; }

        let target_side = middle_numerator * y;
        let middle_side = middle_denominator * x;
        if target_side == middle_side {
            return Bounds {
                lower_numerator: middle_numerator,
                lower_denominator: middle_denominator,
                upper_numerator: middle_numerator,
                upper_denominator: middle_denominator,
            };
        }
        if target_side < middle_side {
            let lower_gap = b * x - a * y;
            let upper_gap = c * y - d * x;
            let mut step = lower_gap / upper_gap;
            step = step.min((limit - a) / c);
            if d > 0 { step = step.min((limit - b) / d); }
            a += step * c;
            b += step * d;
        } else {
            let upper_gap = c * y - d * x;
            let lower_gap = b * x - a * y;
            let mut step = upper_gap / lower_gap;
            if a > 0 { step = step.min((limit - c) / a); }
            step = step.min((limit - d) / b);
            c += step * a;
            d += step * b;
        }
    }
    Bounds {
        lower_numerator: a,
        lower_denominator: b,
        upper_numerator: c,
        upper_denominator: d,
    }
}

fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { output[offset + byte] = ((bits >> (byte * 8)) & 0xff) as u8; }
}

/// Packed input `[N, x, y]`; writes the bounded lower and upper fractions.
#[no_mangle]
pub unsafe extern "C" fn rational_approximation(
    values: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if values.is_null() || length != 3 { return -1; }
    let limit = *values;
    let x = *values.add(1);
    let y = *values.add(2);
    if !(1..=MAX_COMPONENT).contains(&limit)
        || !(1..=MAX_COMPONENT).contains(&x)
        || !(1..=MAX_COMPONENT).contains(&y) { return -1; }
    if output.is_null() || capacity < 32 { return -2; }

    let bounds = bounded_neighbors(limit, x, y);
    let result = std::slice::from_raw_parts_mut(output, capacity);
    store_i64_le(result, 0, bounds.lower_numerator);
    store_i64_le(result, 8, bounds.lower_denominator);
    store_i64_le(result, 16, bounds.upper_numerator);
    store_i64_le(result, 24, bounds.upper_denominator);
    32
}
