// Unverified deterministic planted 3-SAT generator draft.
export fn planted_3sat_clause_generator(input_opt: ?[*]const i64, length: usize,
                                        output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 5 or length > 83) return -1;
    const input = input_opt.?;
    if (input[0] < 3 or input[0] > 16 or input[1] < 0 or input[1] > 32) return -1;
    const n: usize = @intCast(input[0]);
    const m: usize = @intCast(input[1]);
    if (length != 2+n+2*m) return -1;
    for (0..n) |i| {
        if (input[2+i] != 0 and input[2+i] != 1) return -1;
    }
    const choices = n*(n-1)*(n-2)/6;
    var literals: [96]i64 = undefined;
    for (0..m) |clause| {
        const raw = input[2+n+2*clause];
        const mask = input[3+n+2*clause];
        if (raw < 0 or raw >= @as(i64, @intCast(choices)) or mask < 1 or mask > 7) return -1;
        var rank: usize = @intCast(raw);
        var next: usize = 0;
        for (0..3) |position| {
            var variable = next;
            while (variable < n-(2-position)) : (variable += 1) {
                const remaining = n-variable-1;
                const ways = if (position == 0) remaining*(remaining-1)/2 else if (position == 1) remaining else 1;
                if (rank >= ways) { rank -= ways; continue; }
                const value: i64 = @intCast(variable+1);
                literals[3*clause+position] = if (input[2+variable] == ((mask >> @intCast(position)) & 1)) value else -value;
                next = variable+1;
                break;
            }
        }
    }
    const bytes = 24*m;
    if (bytes == 0) return 0;
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?;
    for (0..3*m) |i| {
        const bits: u64 = @bitCast(literals[i]);
        for (0..8) |b| output[8*i+b] = @truncate(bits >> @intCast(8*b));
    }
    return @intCast(bytes);
}
