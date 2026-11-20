const MAX_EGGS: usize = 32;
const MAX_MOVES: usize = 32;

fn solve(input: &[i64]) -> i64 {
    if input.len() != 2 { return -1; }
    let (eggs_raw, moves_raw) = (input[0], input[1]);
    if eggs_raw < 0 || eggs_raw > MAX_EGGS as i64
        || moves_raw < 0 || moves_raw > MAX_MOVES as i64
    {
        return -1;
    }
    let (eggs, moves) = (eggs_raw as usize, moves_raw as usize);
    let mut covered = [0_i64; MAX_EGGS + 1];
    for _ in 0..moves {
        let mut egg = eggs;
        while egg > 0 {
            covered[egg] += covered[egg - 1] + 1;
            egg -= 1;
        }
    }
    covered[eggs]
}

#[no_mangle]
pub unsafe extern "C" fn egg_drop_max_floors_by_moves(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    solve(std::slice::from_raw_parts(input, length))
}
