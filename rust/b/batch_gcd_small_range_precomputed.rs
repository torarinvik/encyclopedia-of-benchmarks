const MAX_VALUE: usize = 64;
const MAX_QUERIES: usize = 64;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_QUERIES;
const MAX_SMALL: usize = 8;

#[no_mangle]
pub unsafe extern "C" fn batch_gcd_small_range_precomputed(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH + 1 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let limit_value = values[0];
    let query_value = values[1];
    if limit_value < 1 || limit_value > MAX_VALUE as i64 ||
        query_value < 0 || query_value > MAX_QUERIES as i64 { return -1; }
    let limit = limit_value as usize;
    let queries = query_value as usize;
    if length != 2 + 2 * queries { return -1; }
    for query in 0..queries {
        let left = values[2 + 2 * query];
        let right = values[3 + 2 * query];
        if left < 0 || left > limit_value || right < 0 || right > limit_value { return -1; }
    }
    let required = 8 * queries;
    if output.is_null() || capacity < required { return -2; }

    let mut least = [0usize; MAX_VALUE + 1];
    let mut primes = [0usize; MAX_VALUE + 1];
    let mut prime_count = 0usize;
    for value in 2..=limit {
        if least[value] == 0 {
            least[value] = value;
            primes[prime_count] = value;
            prime_count += 1;
        }
        for &prime in &primes[..prime_count] {
            let composite = value * prime;
            if composite > limit || prime > least[value] { break; }
            least[composite] = prime;
        }
    }

    let mut factors = [[0usize; 3]; MAX_VALUE + 1];
    factors[1] = [1, 1, 1];
    for value in 2..=limit {
        let prime = least[value];
        let quotient = value / prime;
        let mut triple = factors[quotient];
        triple[0] *= prime;
        triple.sort_unstable();
        factors[value] = triple;
    }

    let mut small_limit = 1usize;
    while (small_limit + 1) * (small_limit + 1) <= limit { small_limit += 1; }
    let mut gcd_table = [[0usize; MAX_SMALL + 1]; MAX_SMALL + 1];
    for left in 1..=small_limit {
        gcd_table[left][0] = left;
        for right in 1..left {
            gcd_table[left][right] = gcd_table[right][left % right];
        }
    }

    let output_bytes = std::slice::from_raw_parts_mut(output, required);
    for query in 0..queries {
        let left = values[2 + 2 * query] as usize;
        let mut remaining = values[3 + 2 * query] as usize;
        let mut result = 0usize;
        if left == 0 {
            result = remaining;
        } else {
            result = 1;
            for &factor in &factors[left] {
                let common = if factor <= small_limit {
                    gcd_table[factor][remaining % factor]
                } else if remaining % factor == 0 {
                    factor
                } else {
                    1
                };
                remaining /= common;
                result *= common;
            }
        }
        output_bytes[8 * query..8 * query + 8].copy_from_slice(&(result as i64).to_le_bytes());
    }
    required as i64
}
