const MAX_OPS: usize = 256;
const FNV_OFFSET: u64 = 0xcbf29ce484222325;
const FNV_PRIME: u64 = 0x100000001b3;

fn hashI64(hash: u64, value: i64) u64 {
    var result = hash;
    const bits: u64 = @bitCast(value);
    for (0..8) |byte_index| result = (result ^ @as(u64, @truncate(bits >> @intCast(byte_index * 8)))) *% FNV_PRIME;
    return result;
}

export fn immutable_hash_map(input: ?[*]const i64, length: usize) i64 {
    const values = input orelse return -1;
    if (length < 1 or length > 1 + 3 * MAX_OPS) return -1;
    const count64 = values[0];
    if (count64 < 0 or count64 > MAX_OPS or length != 1 + 3 * @as(usize, @intCast(count64))) return -1;
    const count: usize = @intCast(count64);
    var keys: [MAX_OPS]i32 = undefined;
    var map_values: [MAX_OPS]i32 = undefined;
    var trace: [MAX_OPS]i64 = undefined;
    var map_size: usize = 0;

    for (0..count) |i| {
        const operation = values[1 + 3 * i];
        const key64 = values[2 + 3 * i];
        const value64 = values[3 + 3 * i];
        if (operation < 0 or operation > 3 or key64 < -2147483648 or key64 > 2147483647 or value64 < -2147483648 or value64 > 2147483647) return -1;
        const key: i32 = @intCast(key64);
        const value: i32 = @intCast(value64);
        if (operation == 0) {
            if (value == 0) return -1;
            keys[map_size] = key;
            map_values[map_size] = value;
            map_size += 1;
            trace[i] = @intCast(map_size);
        } else if (operation == 1 or operation == 2) {
            var found_value: i32 = 0;
            var j = map_size;
            while (j > 0) {
                j -= 1;
                if (keys[j] == key) { found_value = map_values[j]; break; }
            }
            if (operation == 1) trace[i] = @as(i64, found_value)
            else trace[i] = if (found_value != 0) 1 else 0;
        } else {
            trace[i] = @intCast(map_size);
        }
    }
    var hash = hashI64(FNV_OFFSET, count64);
    for (trace[0..count]) |word| hash = hashI64(hash, word);
    return @intCast(hash & 0x7fffffffffffffff);
}
