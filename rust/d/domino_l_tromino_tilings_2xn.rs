const MAX_WIDTH: i64 = 32;

fn count_tilings(width: i64) -> i64 {
    let (mut state0, mut state1, mut state2, mut state3) = (1_i64, 0_i64, 0_i64, 0_i64);
    for _ in 0..width {
        let next0 = state0 + state3;
        let next1 = state0 + state2;
        let next2 = state0 + state1;
        let next3 = state0 + state1 + state2;
        state0 = next0;
        state1 = next1;
        state2 = next2;
        state3 = next3;
    }
    state0
}

#[no_mangle]
pub unsafe extern "C" fn domino_l_tromino_tilings_2xn(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=2).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if length != 1 || !(0..=MAX_WIDTH).contains(&values[0]) { return -1; }
    count_tilings(values[0])
}
