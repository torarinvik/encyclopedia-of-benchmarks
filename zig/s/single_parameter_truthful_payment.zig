const MAX_STEPS: usize = 8;
const MAX_INPUT: usize = 18;
const MAX_OUTPUT: usize = 16;
const MAX_BID: i64 = 16;

fn putI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| { const shift: u6 = @intCast(b*8); output[offset+b] = @truncate(bits >> shift); }
}

export fn single_parameter_truthful_payment(values: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (values == null or length < 4 or length > MAX_INPUT) return -1;
    if (values[0] < 0 or values[0] > MAX_BID or values[1] < 1 or values[1] > @as(i64, @intCast(MAX_STEPS))) return -1;
    const bid: usize = @intCast(values[0]);
    const k: usize = @intCast(values[1]);
    if (length != 2 + 2*k) return -1;
    for (0..k) |i| {
        const point = values[2+2*i];
        const load = values[3+2*i];
        if (point < 0 or point >= MAX_BID or load < 0 or load > MAX_BID) return -1;
        if ((i == 0 and point != 0) or (i > 0 and (point <= values[2+2*(i-1)] or load > values[3+2*(i-1)]))) return -1;
    }
    var allocation: i64 = 0;
    if (bid < @as(usize, @intCast(MAX_BID))) {
        for (0..k) |i| { if (@as(usize, @intCast(values[2+2*i])) <= bid) allocation = values[3+2*i]; }
    }
    var area: i64 = 0;
    for (0..k) |i| {
        const start: usize = @intCast(values[2+2*i]);
        const finish: usize = if (i+1 < k) @intCast(values[2+2*(i+1)]) else @intCast(MAX_BID);
        const left = @max(start, bid);
        if (finish > left) area += @as(i64, @intCast(finish-left)) * values[3+2*i];
    }
    const payment = @as(i64, @intCast(bid)) * allocation + area;
    if (output == null or capacity < MAX_OUTPUT) return -2;
    var staged: [MAX_OUTPUT]u8 = @splat(0);
    putI64Le(&staged, 0, allocation);
    putI64Le(&staged, 8, payment);
    for (0..MAX_OUTPUT) |i| output[i] = staged[i];
    return @intCast(MAX_OUTPUT);
}
