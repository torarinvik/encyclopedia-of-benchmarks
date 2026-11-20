const MAX_INPUT: usize = 3;
const MAX_STACK: usize = 128;
const MAX_DIVISOR_COUNT: i64 = 63;
const MAX_LIMIT: i64 = 1_000_000;
const PRIMES: [i64; 5] = [2, 3, 5, 7, 11];

fn execute(input: &[i64]) -> Result<i64, ()> {
    if input.len() < 2 || input.len() > MAX_INPUT || input.len() != 2 { return Err(()); }
    let (divisor_count, limit) = (input[0], input[1]);
    if !(1..=MAX_DIVISOR_COUNT).contains(&divisor_count) || !(1..=MAX_LIMIT).contains(&limit) {
        return Err(());
    }

    let mut remaining_stack = [0i64; MAX_STACK];
    let mut max_factor_stack = [0i64; MAX_STACK];
    let mut prime_index_stack = [0usize; MAX_STACK];
    let mut product_stack = [0i64; MAX_STACK];
    let mut top = 1usize;
    remaining_stack[0] = divisor_count;
    max_factor_stack[0] = divisor_count;
    product_stack[0] = 1;
    let mut best = limit + 1;

    while top != 0 {
        top -= 1;
        let remaining = remaining_stack[top];
        let max_factor = max_factor_stack[top];
        let prime_index = prime_index_stack[top];
        let product = product_stack[top];
        if remaining == 1 {
            best = best.min(product);
            continue;
        }
        if prime_index >= PRIMES.len() { continue; }
        let prime = PRIMES[prime_index];
        let factor_limit = max_factor.min(remaining);
        for factor in 2..=factor_limit {
            if remaining % factor != 0 { continue; }
            let mut candidate = product;
            let mut valid = true;
            for _ in 1..factor {
                if candidate > limit / prime { valid = false; break; }
                candidate *= prime;
            }
            if valid && candidate < best {
                if top >= MAX_STACK { return Err(()); }
                remaining_stack[top] = remaining / factor;
                max_factor_stack[top] = factor;
                prime_index_stack[top] = prime_index + 1;
                product_stack[top] = candidate;
                top += 1;
            }
        }
    }
    Ok(if best <= limit { best } else { 0 })
}

#[no_mangle]
pub unsafe extern "C" fn smallest_number_with_n_divisors(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    execute(std::slice::from_raw_parts(input, length)).unwrap_or(-1)
}
