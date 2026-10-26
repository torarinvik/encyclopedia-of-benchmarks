const Scale: i64 = 16;
const MaxN = 12;
const MaxSteps = 64;
const MaxInput = 79;
const MaxOutput = 208;
fn put(out: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| out[offset + b] = @truncate(bits >> @intCast(8 * b));
}

export fn ring_exact_covering_protocol(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > MaxInput) return -1;
    const input = input_opt.?;
    if (input[0] < 2 or input[0] > MaxN or input[2] < 0 or input[2] > MaxSteps) return -1;
    const n: usize = @intCast(input[0]); const steps: usize = @intCast(input[2]);
    if (length != 3 + n + steps) return -1;
    const circumference: i64 = Scale * @as(i64, @intCast(n)); const visibility = input[1];
    if (visibility < 2 * Scale or visibility > circumference) return -1;
    var position: [MaxN]i64 = @splat(0);
    for (0..n) |i| {
        position[i] = input[3 + i];
        if (position[i] < 0 or position[i] >= circumference or (i > 0 and position[i - 1] >= position[i])) return -1;
    }
    for (0..steps) |j| if (input[3 + n + j] < 0 or input[3 + n + j] >= @as(i64, @intCast(n))) return -1;
    var moved: i64 = 0;
    for (0..steps) |j| {
        const i: usize = @intCast(input[3 + n + j]); const next = (i + 1) % n;
        const gap = @mod(position[next] - position[i] + circumference, circumference);
        const distance = if (gap > visibility) Scale else if (gap > Scale) gap - Scale else 0;
        if (distance != 0) { position[i] = @mod(position[i] + distance, circumference); moved += 1; }
    }
    const words = 2 + 2 * n; const bytes = 8 * words;
    if (output_opt == null or capacity < bytes) return -2;
    var staged: [MaxOutput]u8 = @splat(0); put(&staged, 0, @intCast(n)); put(&staged, 8, moved);
    for (0..n) |i| put(&staged, 8 * (2 + i), position[i]);
    for (0..n) |i| {
        const gap = @mod(position[(i + 1) % n] - position[i] + circumference, circumference);
        put(&staged, 8 * (2 + n + i), gap);
    }
    const output = output_opt.?; @memcpy(output[0..bytes], staged[0..bytes]); return @intCast(bytes);
}
