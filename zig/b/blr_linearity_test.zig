const MaxInput = 130;
const OutputBytes = 24;

fn putWord(out: *[OutputBytes]u8, offset: usize, value: i64) void {
    const bytes = @as(u64, @bitCast(value));
    for (0..8) |i| out[offset + i] = @truncate(bytes >> @intCast(8 * i));
}

export fn blr_linearity_test(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MaxInput) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > 6 or input[1] < 1 or input[1] > 32) return -1;
    const n: usize = @intCast(input[0]);
    const q: usize = @intCast(input[1]);
    const domain = @as(usize, 1) << @intCast(n);
    if (length != 2 + domain + 2*q) return -1;
    const table_at: usize = 2;
    const tape_at: usize = 2 + domain;
    for (0..domain) |i| if (input[table_at+i] != 0 and input[table_at+i] != 1) return -1;
    for (0..2*q) |i| {
        const point = input[tape_at+i];
        if (point < 0 or @as(u64, @intCast(point)) >= domain) return -1;
    }
    var rounds: usize = 0;
    var accepted: i64 = 1;
    for (0..q) |round| {
        const x: usize = @intCast(input[tape_at+2*round]);
        const y: usize = @intCast(input[tape_at+2*round+1]);
        rounds += 1;
        if ((input[table_at+x] ^ input[table_at+y]) != input[table_at+(x ^ y)]) {
            accepted = 0;
            break;
        }
    }
    if (output_opt == null or capacity < OutputBytes) return -2;
    var staged: [OutputBytes]u8 = @splat(0);
    putWord(&staged, 0, accepted);
    putWord(&staged, 8, @intCast(rounds));
    putWord(&staged, 16, @intCast(3*rounds));
    const output = output_opt.?;
    @memcpy(output[0..OutputBytes], staged[0..OutputBytes]);
    return OutputBytes;
}
