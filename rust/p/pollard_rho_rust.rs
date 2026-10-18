const MAX_NUM: i64 = 1_000_000_000;
const ITERATIONS_BEFORE_CHECK: i64 = 32;
const ITERATIONS_CUTOFF: i64 = 1 << 18;

fn gcd_nonnegative(mut left: i64, mut right: i64) -> i64 {
    while left != 0 {
        let remainder = right % left;
        right = left;
        left = remainder;
    }
    right
}

fn mod_power(mut base: i64, mut power: i64, modulus: i64) -> i64 {
    base %= modulus;
    if base == 0 { return 0; }
    let mut result = 1i64;
    while power > 0 {
        if power % 2 != 0 { result = result * base % modulus; }
        base = base * base % modulus;
        power /= 2;
    }
    result
}

fn probable_prime(number: i64) -> bool {
    if number <= 4 { return number == 2 || number == 3; }
    const BASES: [i64; 4] = [2, 3, 5, 7];
    if BASES.contains(&number) { return true; }
    let mut odd_power = number - 1;
    let mut two_power = 0i64;
    while odd_power % 2 == 0 { odd_power /= 2; two_power += 1; }
    for base in BASES {
        let mut value = mod_power(base, odd_power, number);
        if value == 1 || value == number - 1 { continue; }
        let mut passed = false;
        for _ in 1..two_power {
            value = value * value % number;
            if value == number - 1 { passed = true; break; }
        }
        if !passed { return false; }
    }
    true
}

fn next_u32(state: &mut u32) -> u32 {
    *state = state.wrapping_mul(1_103_515_245).wrapping_add(12_345);
    *state
}

fn draw_mod(state: &mut u32, modulus: i64) -> i64 {
    let high = next_u32(state) as u64;
    let low = next_u32(state) as u64;
    let modulus = modulus as u64;
    (((high % modulus) * ((1u64 << 32) % modulus) + low % modulus) % modulus) as i64
}

fn advance(x: i64, c: i64, number: i64) -> i64 {
    (x * x + c) % number
}

fn brent_factor(number: i64, x0: i64, c: i64) -> i64 {
    let mut x = x0;
    let mut x_start = 0i64;
    let mut y = 0i64;
    let mut remainder = 1i64;
    let mut current_gcd = 1i64;
    let mut max_iterations = 1i64;
    while current_gcd == 1 {
        y = x;
        for _ in 1..max_iterations { x = advance(x, c, number); }
        let mut big_iteration = 0i64;
        while big_iteration < max_iterations && current_gcd == 1 {
            x_start = x;
            let mut small_iteration = 0i64;
            while small_iteration < ITERATIONS_BEFORE_CHECK &&
                small_iteration < max_iterations - big_iteration {
                small_iteration += 1;
                x = advance(x, c, number);
                remainder = remainder * (x - y).abs() % number;
            }
            current_gcd = gcd_nonnegative(remainder, number);
            big_iteration += ITERATIONS_BEFORE_CHECK;
        }
        max_iterations *= 2;
        if max_iterations > ITERATIONS_CUTOFF { break; }
    }
    if current_gcd == number {
        while current_gcd == 1 {
            x_start = advance(x_start, c, number);
            current_gcd = gcd_nonnegative((x_start - y).abs(), number);
        }
    }
    current_gcd
}

#[no_mangle]
pub unsafe extern "C" fn pollard_rho_rust(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 3 { return -1; }
    let number = *input;
    let seed = *input.add(1);
    let restart_limit = *input.add(2);
    if number < 2 || number > MAX_NUM || seed < 0 || seed > u32::MAX as i64 ||
        restart_limit < 1 || restart_limit > 16 { return -1; }
    if probable_prime(number) { return number; }

    let mut state = seed as u32;
    for _ in 0..restart_limit {
        let x0 = draw_mod(&mut state, number - 3) + 2;
        let c = draw_mod(&mut state, number - 2) + 1;
        let factor = brent_factor(number, x0, c);
        if factor != 1 && factor != number { return factor; }
    }
    0
}
