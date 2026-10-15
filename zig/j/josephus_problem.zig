export fn josephus_problem(values: [*]const i64, length: usize) i64 {
    if (length != 2) return -1;
    const n = values[0];
    const step = values[1];
    if (n < 1 or n > 100000 or step < 1) return -1;
    var winner: i64 = 0;
    var size: i64 = 1;
    while (size <= n) : (size += 1) winner = @mod(winner + @mod(step, size), size);
    return winner + 1;
}
