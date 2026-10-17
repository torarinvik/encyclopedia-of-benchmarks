const MAX_OPERATIONS: usize = 128;
const MAX_ENTRIES: usize = 128;
const MAX_INITIAL_CAPACITY: usize = 64;
const MAX_CAPACITY: usize = 256;
const MAX_INPUT_LENGTH: usize = 2 + 3 * MAX_OPERATIONS;
const FNV_OFFSET: u64 = 0xcbf29ce484222325;
const FNV_PRIME: u64 = 0x100000001b3;

fn hashByte(hash: u64, byte: u8) u64 {
    return (hash ^ byte) *% FNV_PRIME;
}

fn hashKey(key: i64) u64 {
    var hash = FNV_OFFSET;
    var magnitude: u64 = @intCast(if (key < 0) -key else key);
    var digits: [10]u8 = @splat(0);
    var count: usize = 0;
    while (true) {
        digits[count] = @intCast(magnitude % 10);
        count += 1;
        magnitude /= 10;
        if (magnitude == 0) break;
    }
    if (key < 0) hash = hashByte(hash, '-');
    while (count > 0) {
        count -= 1;
        hash = hashByte(hash, '0' + digits[count]);
    }
    return hash ^ (hash >> 16);
}

fn bucketFor(key: i64, capacity: usize) usize {
    return @intCast(hashKey(key) & @as(u64, @intCast(capacity - 1)));
}

fn putI64Le(output: [*c]u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[word * 8 + byte] = @truncate(bits >> @as(u6, @intCast(byte * 8)));
}

export fn hashmap(input: [*c]const i64, length: usize, output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const initial_capacity = input[0];
    const operation_count = input[1];
    if (initial_capacity < 1 or initial_capacity > @as(i64, @intCast(MAX_INITIAL_CAPACITY)) or
        (initial_capacity & (initial_capacity - 1)) != 0 or operation_count < 0 or
        operation_count > @as(i64, @intCast(MAX_OPERATIONS)) or
        length != 2 + 3 * @as(usize, @intCast(operation_count))) return -1;
    for (0..@as(usize, @intCast(operation_count))) |operation| {
        const op = input[2 + 3 * operation];
        const key = input[3 + 3 * operation];
        const value = input[4 + 3 * operation];
        if (op < 0 or op > 2 or key < -2147483648 or key > 2147483647) return -1;
        if (op == 0) {
            if (value < -2147483648 or value > 2147483647) return -1;
        } else if (value != 0) return -1;
    }

    var keys: [MAX_ENTRIES]i64 = @splat(0);
    var values: [MAX_ENTRIES]i64 = @splat(0);
    var results: [1 + 3 * MAX_OPERATIONS + 2]i64 = @splat(0);
    var next: [MAX_ENTRIES]i32 = @splat(-1);
    var heads: [MAX_CAPACITY]i32 = @splat(-1);
    var tails: [MAX_CAPACITY]i32 = @splat(-1);
    var size: usize = 0;
    var map_capacity: usize = @intCast(initial_capacity);
    var result_words: usize = 1;
    var query_count: usize = 0;

    for (0..@as(usize, @intCast(operation_count))) |operation| {
        const op = input[2 + 3 * operation];
        const key = input[3 + 3 * operation];
        const value = input[4 + 3 * operation];
        const bucket = bucketFor(key, map_capacity);
        var entry = heads[bucket];
        while (entry >= 0 and keys[@intCast(entry)] != key) entry = next[@intCast(entry)];
        if (op == 0) {
            if (entry >= 0) {
                values[@intCast(entry)] = value;
                continue;
            }
            if (size >= MAX_ENTRIES) return -1;
            entry = @intCast(size);
            size += 1;
            keys[@intCast(entry)] = key;
            values[@intCast(entry)] = value;
            if (heads[bucket] < 0) heads[bucket] = entry
            else next[@intCast(tails[bucket])] = entry;
            tails[bucket] = entry;
            if (size * 4 > map_capacity * 3) {
                var order: [MAX_ENTRIES]i32 = @splat(0);
                var order_count: usize = 0;
                for (0..map_capacity) |old_bucket| {
                    var node = heads[old_bucket];
                    while (node >= 0) {
                        order[order_count] = node;
                        order_count += 1;
                        node = next[@intCast(node)];
                    }
                }
                map_capacity *= 2;
                heads = @splat(-1);
                tails = @splat(-1);
                for (0..size) |i| next[i] = -1;
                for (order[0..order_count]) |node| {
                    const node_index: usize = @intCast(node);
                    const new_bucket = bucketFor(keys[node_index], map_capacity);
                    if (heads[new_bucket] < 0) heads[new_bucket] = node
                    else next[@intCast(tails[new_bucket])] = node;
                    tails[new_bucket] = node;
                }
            }
        } else {
            results[result_words] = op;
            result_words += 1;
            if (op == 1) {
                results[result_words] = if (entry >= 0) 1 else 0;
                result_words += 1;
                results[result_words] = if (entry >= 0) values[@intCast(entry)] else 0;
                result_words += 1;
            } else {
                results[result_words] = if (entry >= 0) 1 else 0;
                result_words += 1;
            }
            query_count += 1;
        }
    }
    results[0] = @intCast(query_count);
    results[result_words] = @intCast(size);
    result_words += 1;
    results[result_words] = @intCast(map_capacity);
    result_words += 1;
    const output_bytes = result_words * 8;
    if (output == null or output_capacity < output_bytes) return -2;
    for (0..result_words) |word| putI64Le(output, word, results[word]);
    return @intCast(output_bytes);
}
