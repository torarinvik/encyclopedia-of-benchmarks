const MaxNodes = 16;
const MaxBits = 6;
const MaxInput = 116;
const MaxOutput = 128;
fn put(out: [*]u8, offset: usize, value: i64) void { const bits: u64 = @bitCast(value); for (0..8) |b| out[offset + b] = @truncate(bits >> @intCast(8 * b)); }

export fn p2p_chord_finger_lookup(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > MaxInput) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > MaxBits or input[1] < 2 or input[1] > MaxNodes) return -1;
    const bits: usize = @intCast(input[0]); const n: usize = @intCast(input[1]);
    const ring: usize = @as(usize, 1) << @intCast(bits);
    if (n > ring or input[2] < 0 or input[2] >= input[1] or input[3] < 0 or input[3] >= @as(i64, @intCast(ring))) return -1;
    if (length != 4 + n + n * bits) return -1;
    var ids: [MaxNodes]usize = @splat(0);
    var fingers: [MaxNodes * MaxBits]usize = @splat(0);
    for (0..n) |i| {
        const raw = input[4 + i];
        if (raw < 0 or raw >= @as(i64, @intCast(ring))) return -1;
        ids[i] = @intCast(raw);
        if (i > 0 and ids[i] <= ids[i - 1]) return -1;
    }
    for (0..n) |node| for (0..bits) |level| {
        const target = (ids[node] + (@as(usize, 1) << @intCast(level))) % ring;
        var successor: usize = 0;
        while (successor < n and ids[successor] < target) : (successor += 1) {}
        if (successor == n) successor = 0;
        const raw = input[4 + n + node * bits + level];
        if (raw < 0 or raw >= @as(i64, @intCast(n)) or @as(usize, @intCast(raw)) != successor) return -1;
        fingers[node * bits + level] = successor;
    };
    const key: usize = @intCast(input[3]);
    var owner: usize = 0;
    while (owner < n and ids[owner] < key) : (owner += 1) {}
    if (owner == n) owner = 0;
    var route: [MaxNodes]usize = @splat(0); var route_len: usize = 1;
    var current: usize = @intCast(input[2]); route[0] = current;
    for (0..n) |_| {
        if (current == owner) break;
        const target_distance = (ids[owner] + ring - ids[current]) % ring;
        var chosen: ?usize = null;
        var level = bits;
        while (level > 0) {
            level -= 1;
            const candidate = fingers[current * bits + level];
            const progress = (ids[candidate] + ring - ids[current]) % ring;
            if (progress > 0 and progress <= target_distance) { chosen = candidate; break; }
        }
        if (chosen == null or route_len >= n) return -1;
        const next = chosen.?;
        for (0..route_len) |i| if (route[i] == next) return -1;
        current = next; route[route_len] = current; route_len += 1;
    }
    if (current != owner) return -1;
    const bytes = 8 * route_len;
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?;
    var staged: [MaxOutput]u8 = @splat(0);
    for (0..route_len) |i| put(&staged, 8 * i, @intCast(ids[route[i]]));
    @memcpy(output[0..bytes], staged[0..bytes]);
    return @intCast(bytes);
}
