const MAX_PARAMETER: i64 = 1_000_000_000;

fn floor_sum(mut n: i64, mut m: i64, mut a: i64, mut b: i64) -> i64 {
    let mut answer = 0i64;
    loop {
        if a >= m {
            let quotient = a / m;
            let mut left = n;
            let mut right = n - 1;
            if left % 2 == 0 { left /= 2; }
            else { right /= 2; }
            answer += left * right * quotient;
            a %= m;
        }
        if b >= m {
            answer += n * (b / m);
            b %= m;
        }
        let numerator = a * n + b;
        let height = numerator / m;
        if height == 0 { return answer; }
        b = numerator % m;
        n = height;
        std::mem::swap(&mut m, &mut a);
    }
}

#[no_mangle]
pub unsafe extern "C" fn min_of_mod_of_linear(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 4 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n = values[0];
    let m = values[1];
    let a = values[2];
    let b = values[3];
    if !(1..=MAX_PARAMETER).contains(&n) || !(1..=MAX_PARAMETER).contains(&m)
        || a < 0 || a >= m || b < 0 || b >= m { return -1; }
    let target = floor_sum(n, m, a, b) + n;
    let mut low = -1i64;
    let mut high = m - 1;
    while high - low > 1 {
        let candidate = low + (high - low) / 2;
        let shift = m - 1 - candidate;
        if floor_sum(n, m, a, b + shift) < target { high = candidate; }
        else { low = candidate; }
    }
    high
}
