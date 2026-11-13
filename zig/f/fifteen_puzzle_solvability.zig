export fn fifteen_puzzle_solvability(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length != 16) return -1;
    const input = input_opt.?;

    var blank: i64 = -1;
    for (0..16) |i| {
        const value = input[i];
        if (value < 0 or value >= 16) return -1;
        for (0..i) |j| {
            if (value == input[j]) return -1;
        }
        if (value == 0) blank = @intCast(i);
    }
    if (blank < 0) return -1;

    var inversions: i64 = 0;
    for (0..16) |i| {
        if (input[i] == 0) continue;
        for ((i + 1)..16) |j| {
            if (input[j] != 0 and input[i] > input[j]) inversions += 1;
        }
    }
    const blank_row_from_top = @divTrunc(blank, 4) + 1;
    return if (@mod(inversions + blank_row_from_top, 2) == 0) 1 else 0;
}
