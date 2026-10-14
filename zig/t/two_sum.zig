/// One-pass two-sum with portable open addressing and first-pair ordering.
const MAX_VALUES: usize = 256;
const TABLE_SIZE: usize = 512;

fn hashSlot(key: i64, capacity: usize) usize {
    const prime: i64 = 2_147_483_647;
    const normalized = @mod(key, prime);
    const mixed = @mod(normalized * 48_271, prime);
    return @as(usize, @intCast(mixed)) % capacity;
}

export fn two_sum(input_values: [*]const i64, length: usize) i64 {
    if (length == 0 or length > MAX_VALUES + 1) return -2;
    for (0..length) |index| {
        if (input_values[index] < -2_147_483_648 or input_values[index] > 2_147_483_647) return -2;
    }
    const target = input_values[0];
    const value_count = length - 1;
    var capacity: usize = 1;
    while (capacity < value_count * 2) capacity *= 2;
    var keys: [TABLE_SIZE]i64 = @splat(0);
    var first_indices: [TABLE_SIZE]usize = @splat(0);
    var occupied: [TABLE_SIZE]bool = @splat(false);

    for (0..value_count) |index| {
        const current = input_values[index + 1];
        const complement = target - current;
        var slot = hashSlot(complement, capacity);
        while (occupied[slot] and keys[slot] != complement) slot = (slot + 1) % capacity;
        if (occupied[slot]) return @intCast(first_indices[slot] * 256 + index);

        slot = hashSlot(current, capacity);
        while (occupied[slot] and keys[slot] != current) slot = (slot + 1) % capacity;
        if (!occupied[slot]) {
            occupied[slot] = true;
            keys[slot] = current;
            first_indices[slot] = index;
        }
    }
    return -1;
}
