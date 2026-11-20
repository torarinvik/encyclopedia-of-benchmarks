const MAX_WIDTH: i64 = 32;

fn countTilings(width: i64) i64 {
    var state0: i64 = 1;
    var state1: i64 = 0;
    var state2: i64 = 0;
    var state3: i64 = 0;
    var column: i64 = 0;
    while (column < width) : (column += 1) {
        const next0 = state0 + state3;
        const next1 = state0 + state2;
        const next2 = state0 + state1;
        const next3 = state0 + state1 + state2;
        state0 = next0;
        state1 = next1;
        state2 = next2;
        state3 = next3;
    }
    return state0;
}

export fn domino_l_tromino_tilings_2xn(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > 2) return -1;
    const input = input_opt.?[0..length];
    if (length != 1 or input[0] < 0 or input[0] > MAX_WIDTH) return -1;
    return countTilings(input[0]);
}
