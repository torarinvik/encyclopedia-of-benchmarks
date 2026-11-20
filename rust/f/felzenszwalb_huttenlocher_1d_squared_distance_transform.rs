const MAX_SITES: usize = 128;
const MAX_INPUT_WORDS: usize = 130;
const SENTINEL: i64 = i64::MIN / 2;

fn floor_div(numerator: i64, denominator: i64) -> i64 {
    let mut quotient = numerator / denominator;
    let remainder = numerator % denominator;
    if remainder != 0 && numerator < 0 {
        quotient -= 1;
    }
    quotient
}

unsafe fn store_i64_le(output: *mut u8, word: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        output.add(word * 8 + byte).write((bits >> (byte * 8)) as u8);
    }
}

#[no_mangle]
pub unsafe extern "C" fn felzenszwalb_huttenlocher_1d_squared_distance_transform(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || !(2..=MAX_INPUT_WORDS).contains(&length) {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let n64 = values[0];
    if !(1..=MAX_SITES as i64).contains(&n64) {
        return -1;
    }
    let n = n64 as usize;
    if length != n + 1 || values[1..].iter().any(|&cost| !(0..=1_000_000).contains(&cost)) {
        return -1;
    }
    if output.is_null() || output_capacity < n * 16 {
        return -2;
    }

    let mut sites = [0usize; MAX_SITES];
    let mut starts = [0i64; MAX_SITES];
    let mut top = 0usize;
    sites[0] = 0;
    starts[0] = SENTINEL;
    for q in 1..n {
        loop {
            let p = sites[top];
            let numerator = values[q + 1] + (q * q) as i64
                - values[p + 1] - (p * p) as i64;
            let denominator = (2 * (q - p)) as i64;
            let first = floor_div(numerator, denominator) + 1;
            if top == 0 || first > starts[top] {
                top += 1;
                sites[top] = q;
                starts[top] = first;
                break;
            }
            top -= 1;
        }
    }

    let mut active = 0usize;
    for x in 0..n {
        while active < top && starts[active + 1] <= x as i64 {
            active += 1;
        }
        let site = sites[active];
        let delta = x as i64 - site as i64;
        let distance = delta * delta + values[site + 1];
        store_i64_le(output, 2 * x, distance);
        store_i64_le(output, 2 * x + 1, site as i64);
    }
    (n * 16) as i64
}
