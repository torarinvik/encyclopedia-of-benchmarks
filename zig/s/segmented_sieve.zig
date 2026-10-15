const MAX_N: usize = 10_000;
fn putI64Le(out: [*]u8, offset: usize, value: i64) void {
    for (0..8) |byte| out[offset + byte] = @truncate(@as(u64, @bitCast(value)) >> @intCast(8 * byte));
}

pub export fn segmented_sieve(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length != 1 or input[0] < 2 or input[0] > MAX_N) return -1;
    const n: usize = @intCast(input[0]);
    var end: usize = 0;
    while ((end + 1) * (end + 1) <= n) : (end += 1) {}
    var base_marks: [101]bool = @splat(false);
    var base: [25]i64 = @splat(0);
    var base_count: usize = 0;
    for (2..end + 1) |i| base_marks[i] = true;
    for (2..end + 1) |p| {
        if (!base_marks[p]) continue;
        base[base_count] = @intCast(p);
        base_count += 1;
        var multiple = p * p;
        while (multiple <= end) : (multiple += p) base_marks[multiple] = false;
    }
    var primes: [1229]i64 = @splat(0);
    var prime_count: usize = 0;
    for (0..base_count) |i| { primes[prime_count] = base[i]; prime_count += 1; }
    var low = end + 1;
    var high = @min(2 * end, n);
    while (low <= n) {
        var segment: [201]bool = @splat(false);
        const segment_length = high - low + 1;
        for (0..segment_length) |i| segment[i] = true;
        for (0..base_count) |i| {
            const p: usize = @intCast(base[i]);
            var first = (low / p) * p;
            if (first < low) first += p;
            while (first <= high) : (first += p) segment[first - low] = false;
        }
        for (0..segment_length) |i| {
            if (segment[i]) { primes[prime_count] = @intCast(low + i); prime_count += 1; }
        }
        low = high + 1;
        high = @min(high + end, n);
    }
    const output_length = prime_count * 8;
    if (capacity < output_length or (output_length > 0 and output == null)) return -2;
    for (0..prime_count) |i| putI64Le(output, i * 8, primes[i]);
    return @intCast(output_length);
}
