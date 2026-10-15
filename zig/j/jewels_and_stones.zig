const MAX_JEWELS_LENGTH: usize = 127;
const MAX_STONES_LENGTH: usize = 4096;
const MAX_PACKED_LENGTH: usize = 4225;

/// Count stones whose ASCII byte appears in the unique-jewel set.
export fn jewels_and_stones(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_PACKED_LENGTH) return -1;
    if (input[0] < 0 or input[0] > MAX_JEWELS_LENGTH or
        input[1] < 0 or input[1] > MAX_STONES_LENGTH) return -1;
    const jewel_count: usize = @intCast(input[0]);
    const stone_count: usize = @intCast(input[1]);
    if (length != 2 + jewel_count + stone_count) return -1;
    var counts: [128]i64 = @splat(0);
    for (0..jewel_count) |index| {
        const value = input[2 + index];
        if (value < 1 or value > 127) return -1;
        const slot: usize = @intCast(value);
        if (counts[slot] != 0) return -1;
        counts[slot] = 1;
    }
    var total: i64 = 0;
    const stone_start = 2 + jewel_count;
    for (0..stone_count) |index| {
        const value = input[stone_start + index];
        if (value < 1 or value > 127) return -1;
        total += counts[@intCast(value)];
    }
    return total;
}
