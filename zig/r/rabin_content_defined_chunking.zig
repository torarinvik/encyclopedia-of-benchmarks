fn reduce(value: u32) u16 {
    var remainder = value;
    var step: u5 = 0;
    while (step < 16) : (step += 1) {
        const bit: u5 = 31 - step;
        if (remainder & (@as(u32, 1) << bit) != 0)
            remainder ^= @as(u32, 0x1100b) << @as(u5, @intCast(bit - 16));
    }
    return @truncate(remainder);
}

export fn rabin_content_defined_chunking(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > 65) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > 64) return -1;
    const n: usize = @intCast(input[0]);
    if (length != n + 1) return -1;
    for (0..n) |i| if (input[i+1] < 0 or input[i+1] > 255) { return -1; };
    var outgoing: [256]u16 = undefined;
    for (0..256) |i| outgoing[i] = reduce(@as(u32, @intCast(i)) << 24);
    var fingerprint: u16 = 0;
    var boundaries: [64]u8 = undefined;
    var count: usize = 0;
    for (0..n) |i| {
        fingerprint = reduce((@as(u32, fingerprint) << 8) | @as(u32, @intCast(input[i+1])));
        if (i >= 4) fingerprint ^= outgoing[@intCast(input[i-3])];
        if (fingerprint & 7 == 0) { boundaries[count] = @intCast(i+1); count += 1; }
    }
    if (n > 0 and (count == 0 or boundaries[count-1] != n)) {
        boundaries[count] = @intCast(n); count += 1;
    }
    if (output_opt == null or capacity < count) return -2;
    const output = output_opt.?;
    for (0..count) |i| output[i] = boundaries[i];
    return @intCast(count);
}
