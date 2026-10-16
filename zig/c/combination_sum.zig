const max_candidates: usize = 8;
const max_target: usize = 20;
const max_packed_words: usize = 4096;

const Search = struct {
    candidates: [*]const i64,
    count: usize,
    path: [max_target]i64 = @splat(0),
    packed_values: [max_packed_words]i64 = @splat(0),
    used: usize = 1,
};

fn enumerate(search: *Search, start: usize, remaining: i64, depth: usize) void {
    if (remaining == 0) {
        search.packed_values[search.used] = @intCast(depth);
        search.used += 1;
        for (0..depth) |i| {
            search.packed_values[search.used] = search.path[i];
            search.used += 1;
        }
        search.packed_values[0] += 1;
        return;
    }
    for (start..search.count) |i| {
        const candidate = search.candidates[i];
        if (candidate > remaining) break;
        search.path[depth] = candidate;
        enumerate(search, i, remaining - candidate, depth + 1);
    }
}

fn putI64(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

pub export fn combination_sum(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 3) return -1;
    const count_value = input[0];
    const target = input[1];
    if (count_value < 1 or count_value > max_candidates or target < 0 or target > max_target) return -1;
    const count: usize = @intCast(count_value);
    if (length != count + 2) return -1;
    for (0..count) |i| {
        const candidate = input[i + 2];
        if (candidate < 1 or candidate > 24 or (i > 0 and input[i + 1] >= candidate)) return -1;
    }

    var search = Search{ .candidates = input + 2, .count = count };
    enumerate(&search, 0, target, 0);
    const required = search.used * 8;
    if (output == null or capacity < required) return -2;
    for (0..search.used) |i| putI64(output, i * 8, search.packed_values[i]);
    return @intCast(required);
}
