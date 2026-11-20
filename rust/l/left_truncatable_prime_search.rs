const MAX_QUEUE: usize = 70_000;
const MAX_LIMIT: i64 = 100_000;

fn is_prime(value: i64) -> bool {
    if value < 2 { return false; }
    if value % 2 == 0 { return value == 2; }
    let mut divisor = 3;
    while divisor * divisor <= value {
        if value % divisor == 0 { return false; }
        divisor += 2;
    }
    true
}

fn search(base: i64, digits: i64) -> i64 {
    let mut queue = [0i64; MAX_QUEUE];
    let mut end = 0usize;
    for value in 2..base {
        if is_prime(value) { queue[end] = value; end += 1; }
    }
    let mut best = queue[end - 1];
    let mut level_start = 0usize;
    let mut level_end = end;
    let mut place = base;
    let mut width = 1;
    while width < digits && level_start < level_end {
        for index in level_start..level_end {
            let suffix = queue[index];
            for leading in 1..base {
                let candidate = leading * place + suffix;
                if is_prime(candidate) {
                    if end >= MAX_QUEUE { return -1; }
                    queue[end] = candidate;
                    end += 1;
                    if candidate > best { best = candidate; }
                }
            }
        }
        level_start = level_end;
        level_end = end;
        place *= base;
        width += 1;
    }
    best
}

#[no_mangle]
pub unsafe extern "C" fn left_truncatable_prime_search(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > 3 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let base = values[0];
    let digits = values[1];
    if length != 2 || !(3..=16).contains(&base) || !(1..=10).contains(&digits) { return -1; }
    let mut limit = 1i64;
    for _ in 0..digits { limit *= base; }
    if limit > MAX_LIMIT { return -1; }
    search(base, digits)
}
