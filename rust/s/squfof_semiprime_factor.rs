const MAX_NUMBER: i64 = 1_000_000_000_000;
const MAX_STEPS: i64 = 256;

fn sq_isqrt(value: i64, upper: i64) -> i64 {
    let mut low = 0i64;
    let mut high = upper + 1;
    while low + 1 < high {
        let middle = low + (high - low) / 2;
        if middle * middle <= value { low = middle; }
        else { high = middle; }
    }
    low
}

fn sq_gcd(mut left: i64, mut right: i64) -> i64 {
    while right != 0 {
        let remainder = left % right;
        left = right;
        right = remainder;
    }
    left
}

fn sq_reverse(number: i64, discriminant: i64, a: i64, p: i64, q: i64, cap: i64) -> i64 {
    let root = sq_isqrt(q, 1_414_214);
    if root * root != q { return 0; }
    let quotient = (a - p) / root;
    let mut r = quotient * root + p;
    let mut previous_s = root;
    let mut s = (discriminant - r * r) / root;
    for _ in 0..cap {
        let next_quotient = (a + r) / s;
        let next_r = next_quotient * s - r;
        if next_r == r {
            let factor = sq_gcd(number, r);
            if factor > 1 && factor < number {
                return factor.min(number / factor);
            }
            return 0;
        }
        let next_s = previous_s + next_quotient * (r - next_r);
        previous_s = s;
        s = next_s;
        r = next_r;
    }
    0
}

#[no_mangle]
pub unsafe extern "C" fn squfof_semiprime_factor(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 3 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let number = values[0];
    let forward_cap = values[1];
    let reverse_cap = values[2];
    if number < 3 || number > MAX_NUMBER || number % 2 == 0
        || forward_cap < 0 || forward_cap > MAX_STEPS
        || reverse_cap < 0 || reverse_cap > MAX_STEPS { return -1; }
    let exact_root = sq_isqrt(number, 1_000_000);
    if exact_root * exact_root == number { return exact_root; }
    let discriminant = if number % 4 == 1 { 2 * number } else { number };
    let a = sq_isqrt(discriminant, 1_414_214);
    let mut previous_q = 1i64;
    let mut q = discriminant - a * a;
    let mut p = a;
    let mut index = 1i64;
    for _ in 0..forward_cap {
        let quotient = (a + p) / q;
        let next_p = quotient * q - p;
        let next_q = previous_q + quotient * (p - next_p);
        previous_q = q;
        q = next_q;
        p = next_p;
        index += 1;
        if index % 2 == 0 {
            let factor = sq_reverse(number, discriminant, a, p, q, reverse_cap);
            if factor != 0 { return factor; }
        }
    }
    0
}
