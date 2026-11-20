const MAX_ITEMS: usize = 12;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 27;
const RATIO_BASE: i64 = 120_001;

fn gcd_positive(mut a: i64, mut b: i64) -> i64 {
    while b != 0 {
        let remainder = a % b;
        a = b;
        b = remainder;
    }
    a
}

fn choose_count(n: usize, k: usize) -> usize {
    let mut count = 1usize;
    for i in 1..=k {
        count = count * (n - i + 1) / i;
    }
    count
}

#[no_mangle]
pub unsafe extern "C" fn dinkelbach_fixed_cardinality_ratio(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    let selected_count_value = values[1];
    if !(1..=MAX_ITEMS as i64).contains(&n_value)
        || selected_count_value < 1
        || selected_count_value > n_value
    {
        return -1;
    }
    let n = n_value as usize;
    let selected_count = selected_count_value as usize;
    if length != 2 + 2 * n {
        return -1;
    }

    let mut numerators = [0i64; MAX_ITEMS];
    let mut denominators = [0i64; MAX_ITEMS];
    for item in 0..n {
        let numerator = values[2 + 2 * item];
        let denominator = values[3 + 2 * item];
        if !(0..=10_000).contains(&numerator) || !(1..=10_000).contains(&denominator) {
            return -1;
        }
        numerators[item] = numerator;
        denominators[item] = denominator;
    }

    let mut current_numerator = 0i64;
    let mut current_denominator = 1i64;
    let iteration_limit = choose_count(n, selected_count);
    for _ in 0..=iteration_limit {
        let mut residuals = [0i64; MAX_ITEMS];
        let mut order = [0usize; MAX_ITEMS];
        for item in 0..n {
            residuals[item] = numerators[item] * current_denominator
                - current_numerator * denominators[item];
            order[item] = item;
        }
        for position in 1..n {
            let candidate = order[position];
            let mut insertion = position;
            while insertion > 0 {
                let previous = order[insertion - 1];
                if residuals[candidate] > residuals[previous]
                    || (residuals[candidate] == residuals[previous] && candidate < previous)
                {
                    order[insertion] = previous;
                    insertion -= 1;
                } else {
                    break;
                }
            }
            order[insertion] = candidate;
        }

        let mut numerator_total = 0i64;
        let mut denominator_total = 0i64;
        for &item in order.iter().take(selected_count) {
            numerator_total += numerators[item];
            denominator_total += denominators[item];
        }
        let residual_total = numerator_total * current_denominator
            - current_numerator * denominator_total;
        if residual_total == 0 {
            let divisor = gcd_positive(numerator_total, denominator_total);
            return (numerator_total / divisor) * RATIO_BASE + denominator_total / divisor;
        }
        if residual_total < 0 {
            return -1;
        }
        let divisor = gcd_positive(numerator_total, denominator_total);
        current_numerator = numerator_total / divisor;
        current_denominator = denominator_total / divisor;
    }
    -1
}
