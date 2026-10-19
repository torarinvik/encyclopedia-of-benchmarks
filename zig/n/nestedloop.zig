const MAX_N: i64 = 15;

export fn nestedloop(input: i64) i64 {
    if (input < 0 or input > MAX_N) return -1;
    const n: usize = @intCast(input);
    var x: i32 = 0;
    for (0..n) |_| {
        for (0..n) |_| {
            for (0..n) |_| {
                for (0..n) |_| {
                    for (0..n) |_| {
                        for (0..n) |_| {
                            x += 1;
                        }
                    }
                }
            }
        }
    }
    return @intCast(x);
}
