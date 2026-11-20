const MAX_KEYS: usize = 256;
const MAX_QUERIES: usize = 256;
const BUCKET_SIZE: usize = 16;
const MAX_BUCKETS: usize = 16;
const MAX_TRIE_NODES: usize = 257;
const MAX_INPUT_VALUES: usize = 514;
const MAX_PARSEABLE_VALUES: usize = 515;
const UNIVERSE_BITS: usize = 16;

fn successorBucket(children: *const [2 * MAX_TRIE_NODES]i32,
                    min_rank: *const [MAX_TRIE_NODES]i32,
                    leaf_rank: *const [MAX_TRIE_NODES]i32,
                    query: i64, bucket_count: usize) i32 {
    if (bucket_count == 0) return -1;
    var node: i32 = 0;
    var candidate: i32 = -1;
    for (0..UNIVERSE_BITS) |bit_position| {
        const shift = UNIVERSE_BITS - 1 - bit_position;
        const branch: usize = @intCast((query >> @intCast(shift)) & 1);
        if (branch == 0) {
            const right_child = children[@as(usize, @intCast(node)) * 2 + 1];
            if (right_child >= 0) candidate = min_rank[@intCast(right_child)];
        }
        const next_node = children[@as(usize, @intCast(node)) * 2 + branch];
        if (next_node < 0) {
            node = -1;
            break;
        }
        node = next_node;
    }
    if (node >= 0 and leaf_rank[@intCast(node)] >= 0) return leaf_rank[@intCast(node)];
    if (candidate >= 0) return candidate;
    return @intCast(bucket_count - 1);
}

fn lowerBound(keys: *const [MAX_KEYS]i64, start: usize, end: usize, query: i64) usize {
    var low = start;
    var high = end;
    while (low < high) {
        const middle = low + (high - low) / 2;
        if (keys[middle] < query) low = middle + 1 else high = middle;
    }
    return low;
}

fn upperBound(keys: *const [MAX_KEYS]i64, start: usize, end: usize, query: i64) usize {
    var low = start;
    var high = end;
    while (low < high) {
        const middle = low + (high - low) / 2;
        if (keys[middle] <= query) low = middle + 1 else high = middle;
    }
    return low;
}

export fn y_fast_trie_static_predecessor(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_PARSEABLE_VALUES) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const q64 = input[1];
    if (n64 < 0 or n64 > @as(i64, @intCast(MAX_KEYS)) or q64 < 0 or q64 > @as(i64, @intCast(MAX_QUERIES))) return -1;
    const n: usize = @intCast(n64);
    const q: usize = @intCast(q64);
    if (length != 2 + n + q or length > MAX_INPUT_VALUES) return -1;

    var keys: [MAX_KEYS]i64 = @splat(0);
    var queries: [MAX_QUERIES]i64 = @splat(0);
    for (0..n) |index| {
        keys[index] = input[2 + index];
        if (keys[index] < 0 or keys[index] > 65535) return -1;
    }
    for (1..n) |index| {
        const key = keys[index];
        var position = index;
        while (position > 0 and key < keys[position - 1]) {
            keys[position] = keys[position - 1];
            position -= 1;
        }
        keys[position] = key;
    }
    for (1..n) |index| if (keys[index] == keys[index - 1]) return -1;
    for (0..q) |index| {
        queries[index] = input[2 + n + index];
        if (queries[index] < 0 or queries[index] > 65535) return -1;
    }
    if (n == 0 or q == 0) return 0;

    const bucket_count = (n + BUCKET_SIZE - 1) / BUCKET_SIZE;
    var children: [2 * MAX_TRIE_NODES]i32 = @splat(-1);
    var min_rank: [MAX_TRIE_NODES]i32 = @splat(-1);
    var leaf_rank: [MAX_TRIE_NODES]i32 = @splat(-1);
    min_rank[0] = 0;
    var node_count: usize = 1;
    for (0..bucket_count) |bucket| {
        const end = @min((bucket + 1) * BUCKET_SIZE, n);
        const separator = keys[end - 1];
        var node: usize = 0;
        for (0..UNIVERSE_BITS) |bit_position| {
            const shift = UNIVERSE_BITS - 1 - bit_position;
            const branch: usize = @intCast((separator >> @intCast(shift)) & 1);
            const slot = node * 2 + branch;
            var child = children[slot];
            if (child < 0) {
                child = @intCast(node_count);
                children[slot] = child;
                min_rank[node_count] = @intCast(bucket);
                node_count += 1;
            } else if (min_rank[@intCast(child)] < 0 or @as(i32, @intCast(bucket)) < min_rank[@intCast(child)]) {
                min_rank[@intCast(child)] = @intCast(bucket);
            }
            node = @intCast(child);
        }
        leaf_rank[node] = @intCast(bucket);
    }

    var checksum: i64 = 0;
    for (0..q) |index| {
        const query = queries[index];
        const bucket_value = successorBucket(&children, &min_rank, &leaf_rank, query, bucket_count);
        const bucket: usize = @intCast(bucket_value);
        const start = bucket * BUCKET_SIZE;
        const end = @min(start + BUCKET_SIZE, n);
        const lower = lowerBound(&keys, start, end, query);
        const upper = upperBound(&keys, start, end, query);
        var predecessor: i64 = -1;
        var successor: i64 = -1;
        if (lower > start) predecessor = keys[lower - 1]
        else if (bucket > 0) predecessor = keys[start - 1];
        if (upper < end) successor = keys[upper]
        else if (bucket + 1 < bucket_count) successor = keys[end];
        checksum += (@as(i64, @intCast(index + 1))) * ((predecessor + 1) + 65537 * (successor + 1));
    }
    return checksum;
}
