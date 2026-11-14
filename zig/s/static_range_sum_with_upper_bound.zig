pub export fn static_range_sum_with_upper_bound(input: [*c]const i64, length: usize,
                                                output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 258) return -1;
    if (input[0] < 1 or input[0] > 64 or input[1] < 1 or input[1] > 64) return -1;
    const n: usize = @intCast(input[0]);
    const q: usize = @intCast(input[1]);
    if (length != 2+n+3*q) return -1;
    var current: [64]u64 = @splat(0);
    var scratch: [64]u64 = @splat(0);
    for (0..n) |i| {
        if (input[2+i] < 0 or input[2+i] > 1000000000) return -1;
        current[i] = @intCast(input[2+i]);
    }
    for (0..q) |i| {
        const b = 2+n+3*i;
        if (input[b] < 0 or input[b] > input[b+1] or input[b+1] > @as(i64, @intCast(n)) or
            input[b+2] < 0 or input[b+2] > 1000000000) return -1;
    }
    if (output == null or capacity < 16*q) return -2;
    var counts: [30][65]usize = @splat(@splat(0));
    var sums: [30][65]u64 = @splat(@splat(0));
    var offsets: [30]usize = @splat(0);
    for (0..30) |level| {
        const bit: u6 = @intCast(29-level);
        const mask = @as(u64, 1) << bit;
        for (0..n) |i| {
            const zero = current[i] & mask == 0;
            counts[level][i+1] = counts[level][i] + @as(usize, @intFromBool(zero));
            sums[level][i+1] = sums[level][i] + (if (zero) current[i] else 0);
        }
        offsets[level] = counts[level][n];
        var z: usize = 0; var o = offsets[level];
        for (0..n) |i| {
            if (current[i] & mask == 0) { scratch[z] = current[i]; z += 1; }
            else { scratch[o] = current[i]; o += 1; }
        }
        for (0..n) |i| current[i] = scratch[i];
    }
    for (0..q) |i| {
        const b = 2+n+3*i;
        var l: usize = @intCast(input[b]); var r: usize = @intCast(input[b+1]);
        const key: u64 = @intCast(input[b+2]+1);
        var count: u64 = 0; var sum: u64 = 0;
        for (0..30) |level| {
            const zl = counts[level][l]; const zr = counts[level][r];
            const bit: u6 = @intCast(29-level);
            if (key & (@as(u64, 1) << bit) != 0) {
                count += @intCast(zr-zl); sum += sums[level][r]-sums[level][l];
                l += offsets[level]-zl; r += offsets[level]-zr;
            } else { l = zl; r = zr; }
        }
        for (0..8) |byte| {
            const shift: u6 = @intCast(8*byte);
            output[16*i+byte] = @truncate(count >> shift);
            output[16*i+8+byte] = @truncate(sum >> shift);
        }
    }
    return @intCast(16*q);
}
