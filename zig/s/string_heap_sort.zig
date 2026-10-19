const MAX_KEYS: usize = 64;
const WIDTH: usize = 4;
fn siftDown(a: *[MAX_KEYS]u32, root_value: usize, end: usize) void {
    var root = root_value;
    while (root < end / 2) {
        var child = 2 * root + 1;
        if (child + 1 < end and a[child] < a[child + 1]) child += 1;
        if (a[root] >= a[child]) break;
        const t = a[root]; a[root] = a[child]; a[child] = t;
        root = child;
    }
}
export fn string_heap_sort(values: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (values == null or length < 1 or length > 257) return -1;
    const raw_count = values[0];
    if (raw_count < 0 or raw_count > MAX_KEYS) return -1;
    const count: usize = @intCast(raw_count);
    if (length != 1 + WIDTH * count) return -1;
    var keys: [MAX_KEYS]u32 = @splat(0);
    for (0..count) |i| {
        var key: u32 = 0;
        for (0..WIDTH) |b| {
            const x = values[1 + WIDTH*i + b];
            if (x < 0 or x > 127) return -1;
            key = (key << 8) | @as(u32, @intCast(x));
        }
        keys[i] = key;
    }
    var start = count / 2;
    while (start > 0) { start -= 1; siftDown(&keys, start, count); }
    var ending = count;
    while (ending > 1) {
        ending -= 1;
        const t = keys[0]; keys[0] = keys[ending]; keys[ending] = t;
        siftDown(&keys, 0, ending);
    }
    const byte_count = count * WIDTH;
    if (output == null or capacity < byte_count) return -2;
    for (0..count) |i| for (0..WIDTH) |b| {
        output[i*WIDTH+b] = @truncate(keys[i] >> @intCast(24-8*b));
    };
    return @intCast(byte_count);
}
