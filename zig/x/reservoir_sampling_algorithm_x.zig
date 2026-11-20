fn falling(top: i64, count: usize) i64 {
    var product: i64 = 1;
    for (0..count) |i| product *= top - @as(i64, @intCast(i));
    return product;
}

fn gcdI64(a_value: i64, b_value: i64) i64 {
    var a = a_value;
    var b = b_value;
    while (b != 0) { const remainder = @mod(a, b); a = b; b = remainder; }
    return a;
}

export fn reservoir_sampling_algorithm_x(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > 49 or input[0] < 1 or input[0] > 16) return -1;
    if (input[1] < 1 or input[1] > 8) return -1;
    const n: usize = @intCast(input[0]);
    const k: usize = @intCast(input[1]);
    if ((k & (k-1)) != 0 or k > n or length != 2+n+2*(n-k)) return -1;
    for (0..n) |i| if (input[2+i] < -1000000 or input[2+i] > 1000000) return -1;
    for (2+n..length) |i| if (input[i] < 0 or input[i] > 4294967295) return -1;
    if (output == null or capacity < 8*k) return -2;
    var sample: [8]i64 = @splat(0);
    for (0..k) |i| sample[i] = input[2+i];
    var processed = k;
    var attempt: usize = 0;
    while (processed < n) {
        const draw = input[2+n+2*attempt];
        const slot_draw = input[2+n+2*attempt+1];
        attempt += 1;
        var numerator = falling(@intCast(processed), k);
        var denominator = falling(@as(i64, @intCast(processed))+1, k);
        const divisor = gcdI64(numerator, denominator);
        numerator = @divTrunc(numerator, divisor);
        denominator = @divTrunc(denominator, divisor);
        const max_skip = n-processed-1;
        var selected: usize = 0;
        var found = false;
        for (0..max_skip+1) |skip| {
            if (numerator*4294967297 <= (draw+1)*denominator) { selected = skip; found = true; break; }
            if (skip < max_skip) {
                const top: i64 = @intCast(processed+skip+1);
                numerator *= top+1-@as(i64, @intCast(k));
                denominator *= top+1;
                const reduce_by = gcdI64(numerator, denominator);
                numerator = @divTrunc(numerator, reduce_by);
                denominator = @divTrunc(denominator, reduce_by);
            }
        }
        if (!found) break;
        const slot: usize = @intCast(@mod(slot_draw, @as(i64, @intCast(k))));
        sample[slot] = input[2+processed+selected];
        processed += selected+1;
    }
    for (0..k) |i| {
        var bits: u64 = @bitCast(sample[i]);
        for (0..8) |j| { output[8*i+j] = @truncate(bits); bits >>= 8; }
    }
    return @intCast(8*k);
}
