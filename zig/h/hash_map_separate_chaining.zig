const MAX_OPERATIONS: usize = 512;
const MAX_ENTRIES: usize = 128;
const MAX_KEY: i64 = 99_999;
const BUCKET_COUNT: usize = 16;
const MAX_INPUT_LENGTH: usize = 1537;
const FNV_OFFSET: u64 = 0xcbf29ce484222325;
const FNV_PRIME: u64 = 0x100000001b3;
const RESULT_MASK: u64 = 0x7fffffffffffffff;

fn hashByte(hash: u64, byte: u8) u64 {
    return (hash ^ byte) *% FNV_PRIME;
}

fn hashI32(hash_value: u64, value: i64) u64 {
    var hash = hash_value;
    const bits: u32 = @bitCast(@as(i32, @intCast(value)));
    for (0..4) |index| hash = hashByte(hash, @truncate(bits >> @as(u5, @intCast(index * 8))));
    return hash;
}

fn findEntry(keys: *const [MAX_ENTRIES]i64, next: *const [MAX_ENTRIES]i32,
             buckets: *const [BUCKET_COUNT]i32, key: i64) i32 {
    const bucket: usize = @intCast(@rem(key, @as(i64, @intCast(BUCKET_COUNT))));
    var entry = buckets[bucket];
    while (entry >= 0) {
        const index: usize = @intCast(entry);
        if (keys[index] == key) return entry;
        entry = next[index];
    }
    return -1;
}

export fn hash_map_separate_chaining(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const operation_count = input[0];
    if (operation_count < 0 or operation_count > @as(i64, @intCast(MAX_OPERATIONS)) or
        length != 1 + 3 * @as(usize, @intCast(operation_count))) return -1;

    var keys: [MAX_ENTRIES]i64 = @splat(0);
    var mapped_values: [MAX_ENTRIES]i64 = @splat(0);
    var next: [MAX_ENTRIES]i32 = @splat(-1);
    var buckets: [BUCKET_COUNT]i32 = @splat(-1);
    var free_slots: [MAX_ENTRIES]i32 = undefined;
    for (0..MAX_ENTRIES) |index| free_slots[index] = @intCast(index);
    var free_count: usize = MAX_ENTRIES;
    var size: usize = 0;
    var hash = FNV_OFFSET;

    for (0..@as(usize, @intCast(operation_count))) |operation| {
        const opcode = input[1 + 3 * operation];
        const key = input[2 + 3 * operation];
        const value = input[3 + 3 * operation];
        var result_code: u8 = 0;
        var returned_value: i64 = 0;

        if (opcode == 0) {
            if (key < 0 or key > MAX_KEY or value < -2147483648 or value > 2147483647) return -1;
            const bucket: usize = @intCast(@rem(key, @as(i64, @intCast(BUCKET_COUNT))));
            const found = findEntry(&keys, &next, &buckets, key);
            if (found >= 0) mapped_values[@intCast(found)] = value else {
                if (size >= MAX_ENTRIES) return -1;
                free_count -= 1;
                const entry: usize = @intCast(free_slots[free_count]);
                keys[entry] = key; mapped_values[entry] = value;
                next[entry] = buckets[bucket]; buckets[bucket] = @intCast(entry); size += 1;
            }
        } else if (opcode == 1) {
            if (key < 0 or key > MAX_KEY or value != 0) return -1;
            const found = findEntry(&keys, &next, &buckets, key);
            if (found >= 0) { result_code = 1; returned_value = mapped_values[@intCast(found)]; }
        } else if (opcode == 2) {
            if (key < 0 or key > MAX_KEY or value != 0) return -1;
            const bucket: usize = @intCast(@rem(key, @as(i64, @intCast(BUCKET_COUNT))));
            var previous: i32 = -1;
            var entry = buckets[bucket];
            while (entry >= 0) {
                const index: usize = @intCast(entry);
                const following = next[index];
                if (keys[index] == key) {
                    if (previous < 0) buckets[bucket] = following
                    else next[@intCast(previous)] = following;
                    free_slots[free_count] = entry; free_count += 1; size -= 1; break;
                }
                previous = entry; entry = following;
            }
        } else if (opcode == 3) {
            if (key < 0 or key > MAX_KEY or value != 0) return -1;
            result_code = @intFromBool(findEntry(&keys, &next, &buckets, key) >= 0);
        } else if (opcode == 4) {
            if (key != 0 or value != 0) return -1;
            buckets = @splat(-1); next = @splat(-1);
            for (0..MAX_ENTRIES) |index| free_slots[index] = @intCast(index);
            free_count = MAX_ENTRIES; size = 0;
        } else return -1;

        hash = hashByte(hash, @intCast(opcode));
        hash = hashByte(hash, result_code);
        if (opcode == 1 and result_code == 1) hash = hashI32(hash, returned_value);
    }
    return @intCast(hash & RESULT_MASK);
}
