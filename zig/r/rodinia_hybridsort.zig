/// Rodinia hybrid histogram bucket partition followed by per-bucket merge sort.
const max_items = 64;

fn bucket(value: f32, minimum: f32, span: f32) usize {
    var index: i32 = @intFromFloat(((value - minimum) / span) * 1024.0);
    if (index < 0) index = 0;
    if (index >= 1024) index = 1023;
    return @intCast(index);
}

fn mergeSort(items: []i64, scratch: []i64) void {
    const count = items.len;
    var width: usize = 1;
    while (width < count) : (width *= 2) {
        var left: usize = 0;
        while (left < count) : (left += 2 * width) {
            const middle = @min(left + width, count);
            const right = @min(left + 2 * width, count);
            var a = left; var b = middle; var out = left;
            while (a < middle and b < right) : (out += 1) {
                if (items[a] <= items[b]) { scratch[out] = items[a]; a += 1; }
                else { scratch[out] = items[b]; b += 1; }
            }
            while (a < middle) : ({ a += 1; out += 1; }) { scratch[out] = items[a]; }
            while (b < right) : ({ b += 1; out += 1; }) { scratch[out] = items[b]; }
        }
        @memcpy(items, scratch[0..count]);
    }
}

fn putI64(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| output[offset + b] = @truncate(bits >> @intCast(8 * b));
}

export fn rodinia_hybridsort(input: [*]const i64, length: usize, output: [*]u8, capacity: usize) i64 {
    if (@intFromPtr(input) == 0 or length < 3 or length > max_items + 1) return -1;
    if (input[0] < 2 or input[0] > max_items or length != 1 + @as(usize, @intCast(input[0]))) return -1;
    const count: usize = @intCast(input[0]);
    var items: [max_items]i64 = @splat(0);
    var scratch: [max_items]i64 = @splat(0);
    var min_raw: i64 = std.math.maxInt(i64); var max_raw: i64 = std.math.minInt(i64);
    for (0..count) |i| {
        const raw = input[1 + i];
        if (raw < 0 or raw > 1_000_000 or @mod(raw, 1000) != 0) return -1;
        items[i] = raw; min_raw = @min(min_raw, raw); max_raw = @max(max_raw, raw);
    }
    if (min_raw == max_raw) return -1;
    const bytes = count * 8;
    if (@intFromPtr(output) == 0 or capacity < bytes) return -2;
    const minimum: f32 = @as(f32, @floatFromInt(min_raw)) / 1_000_000.0;
    const maximum: f32 = @as(f32, @floatFromInt(max_raw)) / 1_000_000.0;
    const span = maximum - minimum;
    var histogram: [1024]usize = @splat(0);
    var offsets: [1025]usize = @splat(0);
    var next: [1024]usize = @splat(0);
    var scattered: [max_items]i64 = @splat(0);
    for (0..count) |i| {
        const value: f32 = @as(f32, @floatFromInt(items[i])) / 1_000_000.0;
        histogram[bucket(value, minimum, span)] += 1;
    }
    for (0..1024) |b| { offsets[b + 1] = offsets[b] + histogram[b]; next[b] = offsets[b]; }
    for (0..count) |i| {
        const value: f32 = @as(f32, @floatFromInt(items[i])) / 1_000_000.0;
        const b = bucket(value, minimum, span);
        scattered[next[b]] = items[i]; next[b] += 1;
    }
    for (0..1024) |b| {
        const start = offsets[b]; const end = offsets[b + 1];
        if (end > start) mergeSort(scattered[start..end], scratch[0 .. end - start]);
    }
    for (0..count) |i| putI64(output, i * 8, scattered[i]);
    return @intCast(bytes);
}
