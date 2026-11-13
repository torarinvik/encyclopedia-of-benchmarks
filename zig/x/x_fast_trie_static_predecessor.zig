const MAX_KEYS: usize = 24;
const MAX_QUERIES: usize = 24;
const UNIVERSE_BITS: usize = 16;
const LEVELS: usize = 17;
const MAX_PARSEABLE: usize = 51;

fn prefix_of(key: i64, depth: usize) i64 {
    return if (depth == 0) 0 else key >> @intCast(UNIVERSE_BITS - depth);
}

fn find_prefix(prefixes: []const i64, counts: []const usize, depth: usize, wanted: i64) ?usize {
    var low: usize = 0;
    var high = counts[depth];
    const row = depth * MAX_KEYS;
    while (low < high) {
        const middle = low + (high - low) / 2;
        if (prefixes[row + middle] < wanted) low = middle + 1 else high = middle;
    }
    if (low < counts[depth] and prefixes[row + low] == wanted) return low;
    return null;
}

fn predecessor(prefixes: []const i64, maxima: []const i64, counts: []const usize, query: i64) i64 {
    var low: usize = 0;
    var high: usize = LEVELS;
    while (high - low > 1) {
        const middle = low + (high - low) / 2;
        if (find_prefix(prefixes, counts, middle, prefix_of(query, middle)) != null) low = middle
        else high = middle;
    }
    if (low == UNIVERSE_BITS) return query;
    var depth = low + 1;
    while (depth > 0) : (depth -= 1) {
        const query_prefix = query >> @intCast(UNIVERSE_BITS - depth);
        if (@as(u64, @bitCast(query_prefix)) & 1 != 0) {
            if (find_prefix(prefixes, counts, depth, query_prefix - 1)) |position| {
                return maxima[depth * MAX_KEYS + position];
            }
        }
    }
    return -1;
}

export fn x_fast_trie_static_predecessor(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_PARSEABLE) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > @as(i64, @intCast(MAX_KEYS)) or
        input[1] < 0 or input[1] > @as(i64, @intCast(MAX_QUERIES))) return -1;
    const n: usize = @intCast(input[0]);
    const q: usize = @intCast(input[1]);
    if (length != 2 + n + q) return -1;
    var keys: [MAX_KEYS]i64 = @splat(0);
    var queries: [MAX_QUERIES]i64 = @splat(0);
    for (0..n) |i| {
        keys[i] = input[2 + i];
        if (keys[i] < 0 or keys[i] > 65535) return -1;
    }
    for (1..n) |i| {
        const key = keys[i];
        var at = i;
        while (at > 0 and key < keys[at - 1]) : (at -= 1) keys[at] = keys[at - 1];
        keys[at] = key;
    }
    for (1..n) |i| if (keys[i] == keys[i - 1]) return -1;
    for (0..q) |i| {
        queries[i] = input[2 + n + i];
        if (queries[i] < 0 or queries[i] > 65535) return -1;
    }
    if (n == 0 or q == 0) return 0;

    var prefixes = [_]i64{0} ** (LEVELS * MAX_KEYS);
    var maxima = [_]i64{0} ** (LEVELS * MAX_KEYS);
    var counts = [_]usize{0} ** LEVELS;
    for (0..LEVELS) |depth| {
        const row = depth * MAX_KEYS;
        for (0..n) |i| {
            const value = prefix_of(keys[i], depth);
            const count = counts[depth];
            if (count == 0 or prefixes[row + count - 1] != value) {
                prefixes[row + count] = value;
                maxima[row + count] = keys[i];
                counts[depth] += 1;
            } else maxima[row + count - 1] = keys[i];
        }
    }
    var checksum: i64 = 0;
    for (0..q) |i| {
        const pred = predecessor(prefixes[0..], maxima[0..], counts[0..], queries[i]);
        checksum += @as(i64, @intCast(i + 1)) * (pred + 1);
    }
    return checksum;
}
