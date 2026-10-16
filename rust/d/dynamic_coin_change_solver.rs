#[no_mangle]
pub unsafe extern "C" fn dynamic_coin_change_solver(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > 11 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let amount = values[0];
    let count = values[1];
    if !(1..=18).contains(&amount) || !(1..=9).contains(&count) || length != count as usize + 2 { return -1; }
    let mut coins = values[2..].to_vec();
    if coins.iter().any(|&coin| !(1..=9).contains(&coin)) || !coins.contains(&1) { return -1; }
    coins.sort_unstable_by(|a, b| b.cmp(a));
    if coins.windows(2).any(|pair| pair[0] == pair[1]) { return -1; }
    let mut changes = [[0i64; 9]; 19];
    let mut sizes = [0usize; 19];
    for value in 1..=amount as usize {
        for &coin in &coins {
            if coin as usize <= value {
                changes[value][sizes[value]] = (value as i64) - coin;
                sizes[value] += 1;
            }
        }
    }
    let mut current = amount as usize;
    let mut code = 0i64;
    for _ in 0..18 {
        let mut next = i64::MAX;
        let mut min_change = i64::MAX;
        for i in 0..sizes[current] {
            let change = changes[current][i];
            if change == 0 { next = 0; break; }
            let minimum = (0..sizes[change as usize]).map(|j| changes[change as usize][j]).min().unwrap();
            if minimum < min_change { min_change = minimum; next = change; }
        }
        if next == i64::MAX { return -1; }
        code = code * 10 + current as i64 - next;
        if next == 0 { return code; }
        current = next as usize;
    }
    -1
}
