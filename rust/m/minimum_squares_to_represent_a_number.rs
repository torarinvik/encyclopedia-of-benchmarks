/// Bottom-up minimum-square-count dynamic programming, bounded to 4096.
#[no_mangle]
pub extern "C" fn minimum_squares_to_represent_a_number(input: i64) -> i64 {
    if !(0..=4096).contains(&input) { return -1; }
    if input == 0 { return 1; }

    let limit = input as usize;
    let mut answers = [0i64; 4097];
    answers[..=limit].fill(-1);
    answers[0] = 0;
    for value in 1..=limit {
        let mut best = i64::MAX;
        let mut root = 1usize;
        while root <= value / root {
            let candidate = 1 + answers[value - root * root];
            if candidate < best { best = candidate; }
            root += 1;
        }
        answers[value] = best;
    }
    answers[limit]
}
