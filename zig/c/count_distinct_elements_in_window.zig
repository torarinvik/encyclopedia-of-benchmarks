const HASH_CAPACITY: usize = 512;

fn hashSlot(value: i32) usize {
    const bits: u32 = @bitCast(value);
    const mixed = @as(u64, bits) * 2_654_435_761;
    return @intCast(@as(u32, @truncate(mixed)) >> 23);
}

fn findSlot(keys: *const [HASH_CAPACITY]i32, occupied: *const [HASH_CAPACITY]bool, value: i32) usize {
    var slot = hashSlot(value);
    for (0..HASH_CAPACITY) |_| {
        if (!occupied[slot] or keys[slot] == value) return slot;
        slot = (slot + 1) % HASH_CAPACITY;
    }
    return 0;
}

fn putI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn count_distinct_elements_in_window(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 3 or input[0] < 1 or input[0] > 256) return -1;
    const n: usize = @intCast(input[0]);
    if (input[1] < 1 or input[1] > @as(i64, @intCast(n)) or length != n + 2) return -1;
    const k: usize = @intCast(input[1]);
    const out_n = n - k + 1;
    const values = input[2..][0..n];
    for (values) |value| if (value < -2_147_483_648 or value > 2_147_483_647) return -1;
    if (output == null or capacity < out_n * 8) return -2;

    var keys: [HASH_CAPACITY]i32 = @splat(0);
    var counts: [HASH_CAPACITY]i32 = @splat(0);
    var occupied: [HASH_CAPACITY]bool = @splat(false);
    var distinct: i64 = 0;
    for (0..k) |i| {
        const value: i32 = @intCast(values[i]);
        const slot = findSlot(&keys, &occupied, value);
        if (!occupied[slot]) { keys[slot] = value; occupied[slot] = true; counts[slot] = 0; }
        if (counts[slot] == 0) distinct += 1;
        counts[slot] += 1;
    }
    putI64Le(output, 0, distinct);
    for (k..n) |i| {
        const incoming: i32 = @intCast(values[i]);
        var slot = findSlot(&keys, &occupied, incoming);
        if (!occupied[slot]) { keys[slot] = incoming; occupied[slot] = true; counts[slot] = 0; }
        if (counts[slot] == 0) distinct += 1;
        counts[slot] += 1;
        const outgoing: i32 = @intCast(values[i - k]);
        slot = findSlot(&keys, &occupied, outgoing);
        counts[slot] -= 1;
        if (counts[slot] == 0) distinct -= 1;
        putI64Le(output, (i - k + 1) * 8, distinct);
    }
    return @intCast(out_n * 8);
}
