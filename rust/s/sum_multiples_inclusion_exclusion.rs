#[no_mangle]
pub extern "C" fn sum_multiples_inclusion_exclusion(limit: i64) -> i64 {
    if !(1..=100_000).contains(&limit) { return -1; }
    let last = limit - 1;
    let threes = last / 3;
    let fives = last / 5;
    let fifteens = last / 15;
    3 * threes * (threes + 1) / 2
        + 5 * fives * (fives + 1) / 2
        - 15 * fifteens * (fifteens + 1) / 2
}
