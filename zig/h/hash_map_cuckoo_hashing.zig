const MAX_KEYS: usize = 128;
const FNV_OFFSET: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;

fn h1(key: i64, capacity: i64) i64 {
    const r = @rem(key, capacity);
    return if (r < 0) r + capacity else r;
}

fn h2(key: i64, capacity: i64) i64 {
    const quotient = @divTrunc(key, capacity);
    const r = @rem(quotient, capacity);
    return if (r < 0) r + capacity else r;
}

fn hashWord(hash_value: u64, word: i64) u64 {
    var hash = hash_value;
    const bits: u64 = @bitCast(word);
    for (0..8) |i| hash = (hash ^ @as(u64, @truncate(bits >> @as(u6, @intCast(i * 8))))) *% FNV_PRIME;
    return hash;
}

export fn hash_map_cuckoo_hashing(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_KEYS + 2) return -1;
    const capacity = input[0];
    const n64 = input[1];
    if (capacity < 16 or capacity > 256 or (@as(u64, @bitCast(capacity)) & (@as(u64, @bitCast(capacity)) - 1)) != 0 or
        n64 < 0 or n64 > @as(i64, @intCast(MAX_KEYS)) or length != @as(usize, @intCast(n64)) + 2) return -1;
    const n: usize = @intCast(n64);
    var keys: [MAX_KEYS]i64 = @splat(0);
    for (0..n) |i| {
        const key = input[i + 2];
        if (key < -2147483647 or key > 2147483647) return -1;
        for (0..i) |j| if (keys[j] == key) return -1;
        keys[i] = key;
    }
    var class_a = false;
    if (n == 2) class_a = h1(keys[0], capacity) == h1(keys[1], capacity) and h2(keys[0], capacity) != h1(keys[0], capacity);
    var class_b = true;
    for (0..n) |i| for (0..i) |j| { if (h1(keys[i], capacity) == h1(keys[j], capacity)) class_b = false; };
    if (!class_a and !class_b) return -1;

    var positions: [MAX_KEYS]i64 = @splat(0);
    if (class_a) {
        positions[0] = h2(keys[0], capacity);
        positions[1] = h1(keys[0], capacity);
    } else {
        var final_capacity = capacity;
        var size: i64 = 0;
        for (0..n) |_| {
            if (@as(f64, @floatFromInt(size + 1)) > @as(f64, @floatFromInt(final_capacity)) * 0.7) final_capacity *= 2;
            size += 1;
        }
        for (0..n) |i| positions[i] = h1(keys[i], final_capacity);
    }
    var hash = hashWord(FNV_OFFSET, n64);
    for (positions[0..n]) |position| hash = hashWord(hash, position);
    return @intCast(hash & 0x7fffffffffffffff);
}
