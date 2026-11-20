const MAX_PARSEABLE_LENGTH: usize = 6;
const MAX_DENOMINATION: i64 = 16;
const DISTANCE_INF: i64 = 1_000_000;

fn gcd_i64(mut left: i64, mut right: i64) -> i64 {
    while right != 0 {
        let remainder = left % right;
        left = right;
        right = remainder;
    }
    left
}

fn apery_frobenius(coins: &[i64], modulus: usize) -> i64 {
    let mut distance = [DISTANCE_INF; 16];
    let mut settled = [false; 16];
    distance[0] = 0;
    for _ in 0..modulus {
        let mut source = usize::MAX;
        let mut best = DISTANCE_INF;
        for residue in 0..modulus {
            if !settled[residue] && distance[residue] < best {
                source = residue;
                best = distance[residue];
            }
        }
        if source == usize::MAX { return -1; }
        settled[source] = true;
        for &coin in coins {
            let target = (source + coin as usize) % modulus;
            let candidate = best + coin;
            if candidate < distance[target] { distance[target] = candidate; }
        }
    }
    let maximum = distance[..modulus].iter().copied().max().unwrap_or(0);
    maximum - modulus as i64
}

fn solve(values: &[i64]) -> i64 {
    if values.is_empty() || values.len() > MAX_PARSEABLE_LENGTH { return -1; }
    let count_value = values[0];
    if !(2..=4).contains(&count_value) || values.len() != count_value as usize + 1 { return -1; }
    let coins = &values[1..];
    let mut common = 0;
    let mut minimum = MAX_DENOMINATION + 1;
    for (index, &coin) in coins.iter().enumerate() {
        if !(2..=MAX_DENOMINATION).contains(&coin) { return -1; }
        if coins[..index].contains(&coin) { return -1; }
        common = gcd_i64(common, coin);
        minimum = minimum.min(coin);
    }
    if common != 1 { return -1; }
    apery_frobenius(coins, minimum as usize)
}

#[no_mangle]
pub unsafe extern "C" fn frobenius_number_apery(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=MAX_PARSEABLE_LENGTH).contains(&length) { return -1; }
    solve(std::slice::from_raw_parts(input, length))
}
