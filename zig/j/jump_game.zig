pub export fn jump_game(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > 1025) return -2;
    if (input[0] < 1 or input[0] > 1024 or length != @as(usize, @intCast(input[0])) + 1) return -2;
    const n: usize = @intCast(input[0]);
    for (0..n) |i| if (input[i + 1] < 0 or input[i + 1] > 1000000) return -2;
    var last_pos = n - 1;
    var i = n;
    while (i > 0) {
        i -= 1;
        if (i + @as(usize, @intCast(input[i + 1])) >= last_pos) last_pos = i;
    }
    return if (last_pos == 0) 1 else 0;
}
