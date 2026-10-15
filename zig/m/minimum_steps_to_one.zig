const MAX_N: usize = 10_000;

export fn minimum_steps_to_one(n: i64) i64 {
    if (n < 1 or n > @as(i64, MAX_N)) return -1;
    const limit: usize = @intCast(n);
    var table: [MAX_N + 1]i64 = undefined;
    for (0..limit + 1) |index| table[index] = n + 1;
    table[1] = 0;
    var i: usize = 1;
    while (i < limit) : (i += 1) {
        const candidate = table[i] + 1;
        if (table[i + 1] > candidate) table[i + 1] = candidate;
        if (i * 2 <= limit and table[i * 2] > candidate) table[i * 2] = candidate;
        if (i * 3 <= limit and table[i * 3] > candidate) table[i * 3] = candidate;
    }
    return table[limit];
}
