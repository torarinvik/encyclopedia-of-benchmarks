export fn chaining(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > 260) return -1;
    const values = input.?;
    const bucket_count_value = values[0];
    const operation_count_value = values[1];
    if (bucket_count_value < 1 or bucket_count_value > 127
        or operation_count_value < 0 or operation_count_value > 128) return -1;
    const operation_count: usize = @intCast(operation_count_value);
    if (length != 2 + 2 * operation_count) return -1;

    var heads: [127]i64 = @splat(-1);
    var keys: [128]i64 = @splat(0);
    var next_nodes: [128]i64 = @splat(-1);
    var inserted: usize = 0;
    var query_count: usize = 0;
    var mask: u64 = 0;
    for (0..operation_count) |operation_index| {
        const offset = 2 + 2 * operation_index;
        const operation = values[offset];
        const key = values[offset + 1];
        if ((operation != 0 and operation != 1) or key < 0 or key > 2147483647) return -1;
        const bucket: usize = @intCast(@mod(key, bucket_count_value));
        if (operation == 0) {
            if (inserted >= keys.len) return -1;
            keys[inserted] = key;
            next_nodes[inserted] = -1;
            if (heads[bucket] < 0) heads[bucket] = @intCast(inserted)
            else {
                var node = heads[bucket];
                while (next_nodes[@intCast(node)] >= 0) node = next_nodes[@intCast(node)];
                next_nodes[@intCast(node)] = @intCast(inserted);
            }
            inserted += 1;
        } else {
            if (query_count >= 63) return -1;
            var node = heads[bucket];
            while (node >= 0 and keys[@intCast(node)] != key) node = next_nodes[@intCast(node)];
            if (node >= 0) mask |= @as(u64, 1) << @intCast(query_count);
            query_count += 1;
        }
    }
    return @intCast(mask);
}
