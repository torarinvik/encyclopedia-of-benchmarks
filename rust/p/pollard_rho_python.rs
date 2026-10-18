const MAX_NUM: i64 = 1_000_000;

fn gcd_nonnegative(mut left: i64, mut right: i64) -> i64 {
    while right != 0 {
        let remainder = left % right;
        left = right;
        right = remainder;
    }
    left
}

fn advance(value: i64, step: i64, modulus: i64) -> i64 {
    (value * value + step) % modulus
}

#[no_mangle]
pub unsafe extern "C" fn pollard_rho_python(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 5 { return -1; }
    let num = *input;
    let mut seed = *input.add(1);
    let mut step = *input.add(2);
    let attempts = *input.add(3);
    let step_limit = *input.add(4);
    if num < 2 || num > MAX_NUM || seed < 0 || seed >= num || step < 0 || step > 1000 ||
        attempts < 1 || attempts > 8 || step_limit < 1 || step_limit > 64 { return -1; }
    if num > 2 && num % 2 == 0 { return 2; }

    for _ in 0..attempts {
        let mut tortoise = seed;
        let mut hare = seed;
        for _ in 0..step_limit {
            tortoise = advance(tortoise, step, num);
            hare = advance(advance(hare, step, num), step, num);
            let difference = (hare - tortoise).abs();
            let divisor = gcd_nonnegative(difference, num);
            if divisor == 1 { continue; }
            if divisor < num { return divisor; }
            break;
        }
        seed = hare;
        step += 1;
    }
    0
}
