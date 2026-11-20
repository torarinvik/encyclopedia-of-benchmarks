const max_n: usize = 12;
const max_length: usize = 14;
const max_states: usize = 1 << max_n;

export fn linear_extension_count(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > max_length) return -1;
    const words = input.?;
    if (words[0] < 0 or words[0] > @as(i64, @intCast(max_n))) return -1;
    const n: usize = @intCast(words[0]);
    if (length != n + 1) return -1;
    const full: usize = (@as(usize, 1) << @intCast(n)) - 1;
    var predecessor = [_]usize{0} ** max_n;
    for (0..n) |vertex| {
        if (words[1 + vertex] < 0 or words[1 + vertex] > @as(i64, @intCast(full))) return -1;
        predecessor[vertex] = @intCast(words[1 + vertex]);
    }

    var ways = [_]i64{0} ** max_states;
    ways[0] = 1;
    for (0..full + 1) |prefix| {
        const count = ways[prefix];
        if (count == 0) continue;
        for (0..n) |vertex| {
            const bit = @as(usize, 1) << @intCast(vertex);
            if ((prefix & bit) == 0 and (predecessor[vertex] & prefix) == predecessor[vertex])
                ways[prefix | bit] += count;
        }
    }
    return ways[full];
}
