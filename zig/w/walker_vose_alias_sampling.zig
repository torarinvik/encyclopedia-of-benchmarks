export fn walker_vose_alias_sampling(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > 83) return -1;
    const input = input_opt.?;
    const nr = input[0];
    const qr = input[1];
    if (nr < 1 or nr > 16 or qr < 0 or qr > 32) return -1;
    const n: usize = @intCast(nr);
    const q: usize = @intCast(qr);
    if (length != 2 + n + 2 * q) return -1;
    var total: i64 = 0;
    for (0..n) |i| {
        if (input[2+i] < 0 or input[2+i] > 100) return -1;
        total += input[2+i];
    }
    if (total == 0) return -1;
    for (0..q) |i| {
        const col = input[2+n+2*i];
        const ticket = input[3+n+2*i];
        if (col < 0 or col >= nr or ticket < 0 or ticket >= total) return -1;
    }
    if (q == 0) return 0;
    if (output_opt == null or capacity < 8*q) return -2;
    var mass: [16]i64 = @splat(0);
    var threshold: [16]i64 = @splat(0);
    var aliases: [16]usize = @splat(0);
    var small: [16]usize = @splat(0);
    var large: [16]usize = @splat(0);
    var ns: usize = 0;
    var nl: usize = 0;
    for (0..n) |i| {
        mass[i] = nr * input[2+i]; threshold[i] = total; aliases[i] = i;
        if (mass[i] < total) { small[ns] = i; ns += 1; } else { large[nl] = i; nl += 1; }
    }
    while (ns > 0 and nl > 0) {
        ns -= 1; nl -= 1;
        const low = small[ns];
        const high = large[nl];
        threshold[low] = mass[low]; aliases[low] = high;
        mass[high] -= total - mass[low];
        if (mass[high] < total) { small[ns] = high; ns += 1; } else { large[nl] = high; nl += 1; }
    }
    var staged: [256]u8 = @splat(0);
    for (0..q) |i| {
        const col: usize = @intCast(input[2+n+2*i]);
        const chosen: u64 = @intCast(if (input[3+n+2*i] < threshold[col]) col else aliases[col]);
        for (0..8) |b| staged[8*i+b] = @truncate(chosen >> @intCast(8*b));
    }
    const output = output_opt.?;
    for (0..8*q) |i| output[i] = staged[i];
    return @intCast(8*q);
}
