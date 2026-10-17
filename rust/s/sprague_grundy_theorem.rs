/// Compute a bounded single-heap subtraction game's Sprague-Grundy number.
fn calculate_grundy(position: usize, memo: &mut [i64; 65], moves: &[i64]) -> i64 {
    if memo[position] != -1 {
        return memo[position];
    }
    if position == 0 {
        memo[0] = 0;
        return 0;
    }

    let mut reachable = [false; 33];
    for &move_size in moves {
        let move_size = move_size as usize;
        if move_size <= position {
            let child = calculate_grundy(position - move_size, memo, moves);
            reachable[child as usize] = true;
        }
    }
    let mut mex = 0usize;
    while mex <= 32 && reachable[mex] {
        mex += 1;
    }
    memo[position] = mex as i64;
    mex as i64
}

#[no_mangle]
pub extern "C" fn sprague_grundy_theorem(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > 34 {
        return -1;
    }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    let position_value = input[0];
    let move_count_value = input[1];
    if !(0..=64).contains(&position_value) || !(0..=32).contains(&move_count_value) {
        return -1;
    }
    let move_count = move_count_value as usize;
    if length != 2 + move_count || input[2..].iter().any(|&move_size| !(1..=32).contains(&move_size)) {
        return -1;
    }

    let mut memo = [-1i64; 65];
    calculate_grundy(position_value as usize, &mut memo, &input[2..])
}
