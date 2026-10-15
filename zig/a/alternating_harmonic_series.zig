const MAX_COUNT: i64 = 1000;

/// Check whether each rational input approximates its canonical alternating term.
export fn alternating_harmonic_series(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1) return -1;
    const count = input[0];
    if (count < 0 or count > MAX_COUNT or length != @as(usize, @intCast(1 + 2 * count))) return -1;
    for (0..@as(usize, @intCast(count))) |index| {
        const numerator = input[1 + 2 * index];
        const denominator = input[2 + 2 * index];
        if (numerator < -1000 or numerator > 1000 or denominator < 1 or denominator > 1000) return -1;
        const sign: i64 = if (index % 2 == 0) 1 else -1;
        const position: i64 = @intCast(index + 1);
        const difference = numerator * position - sign * denominator;
        const magnitude = if (difference < 0) -difference else difference;
        if (magnitude * 1_000_000_000 > denominator * position) return 0;
    }
    return 1;
}
