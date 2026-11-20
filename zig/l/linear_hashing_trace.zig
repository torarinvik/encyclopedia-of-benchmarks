fn bucketIndex(key: i64, level: usize, split: usize) usize {
    const base = @as(i64, 1) << @intCast(level);
    var remainder = key % base;
    if (remainder < 0) remainder += base;
    var index: usize = @intCast(remainder);
    if (index < split) {
        remainder = key % (base << 1);
        if (remainder < 0) remainder += base << 1;
        index = @intCast(remainder);
    }
    return index;
}

pub export fn linear_hashing_trace(values: ?[*]const i64, length: usize) callconv(.c) i64 {
    const input = values orelse return -1;
    if (length < 1 or length > 128) return -1;
    const operation_count = input[0];
    if (operation_count < 0 or operation_count > 63
        or length != 1 + 2 * @as(usize, @intCast(operation_count))) return -1;

    var heads = [_]i32{-1} ** 32;
    var keys = [_]i64{0} ** 63;
    var links = [_]i32{-1} ** 63;
    var level: usize = 1;
    var split: usize = 0;
    var live_count: usize = 0;
    var allocated: usize = 0;
    var result: i64 = 0;

    for (0..@as(usize, @intCast(operation_count))) |operation| {
        const opcode = input[1 + 2 * operation];
        const key = input[2 + 2 * operation];
        if (opcode < 0 or opcode > 2 or key < -1024 or key > 1023) return -1;
        const bucket = bucketIndex(key, level, split);
        var previous: i32 = -1;
        var node = heads[bucket];
        while (node != -1 and keys[@intCast(node)] != key) {
            previous = node;
            node = links[@intCast(node)];
        }
        const found = node != -1;
        var succeeded: i64 = 0;

        if (opcode == 0 and !found) {
            node = @intCast(allocated);
            allocated += 1;
            keys[@intCast(node)] = key;
            links[@intCast(node)] = heads[bucket];
            heads[bucket] = node;
            live_count += 1;
            succeeded = 1;
            const base = @as(usize, 1) << @intCast(level);
            const bucket_count = base + split;
            if (bucket_count < 32 and live_count > 2 * bucket_count) {
                const old_bucket = split;
                const new_bucket = base + split;
                var current = heads[old_bucket];
                heads[old_bucket] = -1;
                while (current != -1) {
                    const following = links[@intCast(current)];
                    const modulus: i64 = @intCast(base << 1);
                    var remainder = keys[@intCast(current)] % modulus;
                    if (remainder < 0) remainder += modulus;
                    if (@as(usize, @intCast(remainder)) == new_bucket) {
                        links[@intCast(current)] = heads[new_bucket];
                        heads[new_bucket] = current;
                    } else {
                        links[@intCast(current)] = heads[old_bucket];
                        heads[old_bucket] = current;
                    }
                    current = following;
                }
                split += 1;
                if (split == base) {
                    level += 1;
                    split = 0;
                }
            }
        } else if (opcode == 1 and found) {
            if (previous == -1) heads[bucket] = links[@intCast(node)]
            else links[@intCast(previous)] = links[@intCast(node)];
            live_count -= 1;
            succeeded = 1;
        } else if (opcode == 2 and found) {
            succeeded = 1;
        }
        result = (result << 1) | succeeded;
    }
    return result;
}
