/// Compare lowercase ASCII strings by their letter frequencies.
export fn valid_anagram(input: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 2050) return -1;
    const first: u64 = @bitCast(input[0]);
    const second: u64 = @bitCast(input[1]);
    if (first > 1024 or second > 1024 or length != 2 + first + second) return -1;
    if (first != second) {
        for (input[2..length]) |value| {
            if (@as(u64, @bitCast(value)) -% 97 > 25) return -1;
        }
        return 0;
    }

    var counts: [26]u16 = @splat(0);
    const count: usize = @intCast(first);
    for (input[2 .. 2 + count], input[2 + count .. length]) |left_raw, right_raw| {
        const left = @as(u64, @bitCast(left_raw)) -% 97;
        const right = @as(u64, @bitCast(right_raw)) -% 97;
        if (left > 25 or right > 25) return -1;
        if (left != right) {
            counts[@intCast(left)] +%= 1;
            counts[@intCast(right)] -%= 1;
        }
    }
    for (counts) |balance| {
        if (balance != 0) return 0;
    }
    return 1;
}
