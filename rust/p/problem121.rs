/// Maximum whole-pound prize from the exact probability of a blue majority.
#[no_mangle]
pub extern "C" fn problem121(num_turns: i64) -> i64 {
    if !(1..=15).contains(&num_turns) { return -1; }
    let mut denominator = 1i64;
    for turn in 2..=num_turns + 1 { denominator *= turn; }
    let sequence_count = 1i64 << num_turns;
    let mut winning_weight = 0i64;
    for mask in 0..sequence_count {
        let mut remaining = mask;
        let mut blue = 0i64;
        let mut weight = 1i64;
        for turn in 0..num_turns {
            if remaining % 2 == 0 { weight *= turn + 1; }
            else { blue += 1; }
            remaining /= 2;
        }
        if 2 * blue > num_turns { winning_weight += weight; }
    }
    denominator / winning_weight
}
