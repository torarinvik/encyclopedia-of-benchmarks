const MAX_N: i64 = 16;
const MAX_INPUT: usize = 34;
const TABLE_SIZE: usize = 32;

fn gcd_positive(mut a: i32, mut b: i32) -> i32 {
    while b != 0 { let remainder = a % b; a = b; b = remainder; }
    a
}

#[no_mangle]
pub unsafe extern "C" fn max_points_on_a_line(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    if !(1..=MAX_N).contains(&n_value) || length != (1 + 2 * n_value) as usize { return -1; }
    let n = n_value as usize;
    let mut x = [0i32; 16];
    let mut y = [0i32; 16];
    for i in 0..n {
        let xv = values[1 + 2 * i];
        let yv = values[2 + 2 * i];
        if !(-100..=100).contains(&xv) || !(-100..=100).contains(&yv) { return -1; }
        x[i] = xv as i32; y[i] = yv as i32;
        for j in 0..i { if x[i] == x[j] && y[i] == y[j] { return -1; } }
    }
    if n == 1 { return 1; }
    let mut answer = 2i64;
    for anchor in 0..n {
        let mut keys = [-1i32; TABLE_SIZE];
        let mut counts = [0i32; TABLE_SIZE];
        let mut best = 0i32;
        for other in 0..n {
            if other == anchor { continue; }
            let (mut dx, mut dy) = (x[other] - x[anchor], y[other] - y[anchor]);
            let divisor = gcd_positive(dx.abs(), dy.abs());
            dx /= divisor; dy /= divisor;
            if dx < 0 || (dx == 0 && dy < 0) { dx = -dx; dy = -dy; }
            let direction_key = dx * 401 + dy + 200;
            let mut slot = direction_key as usize % TABLE_SIZE;
            while keys[slot] != -1 && keys[slot] != direction_key { slot = (slot + 1) % TABLE_SIZE; }
            if keys[slot] == -1 { keys[slot] = direction_key; }
            counts[slot] += 1;
            best = best.max(counts[slot]);
        }
        answer = answer.max((best + 1) as i64);
    }
    answer
}
