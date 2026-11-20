const SLOTS: usize = 16;
const FEATURES: usize = 3;
const MAX_OPERATIONS: usize = 64;
const BASE_WORDS: usize = 1 + SLOTS * FEATURES + SLOTS;
const MAX_VALID_WORDS: usize = BASE_WORDS + 2 * MAX_OPERATIONS;

fn storeHash(output: [*c]u8, offset: usize, value: u64) void {
    for (0..8) |byte| {
        const shift: u6 = @intCast(byte * 8);
        output[offset + byte] = @intCast((value >> shift) & 255);
    }
}

pub export fn zobrist_position_hash_trace(
    input: [*c]const i64,
    length: usize,
    output: [*c]u8,
    capacity: usize,
) i64 {
    if (input == null or length < BASE_WORDS or length > MAX_VALID_WORDS + 1) return -1;
    const count_value = input[0];
    if (count_value < 0 or count_value > @as(i64, @intCast(MAX_OPERATIONS))) return -1;
    const count: usize = @intCast(count_value);
    if (length != BASE_WORDS + 2 * count) return -1;

    for (0..SLOTS * FEATURES) |index| {
        if (input[1 + index] < 0) return -1;
    }
    const state_start = 1 + SLOTS * FEATURES;
    for (0..SLOTS) |slot| {
        const feature = input[state_start + slot];
        if (feature < 0 or feature > @as(i64, @intCast(FEATURES))) return -1;
    }
    const edits_start = state_start + SLOTS;
    for (0..count) |edit| {
        const slot = input[edits_start + 2 * edit];
        const feature = input[edits_start + 2 * edit + 1];
        if (slot < 0 or slot >= @as(i64, @intCast(SLOTS)) or feature < 0 or
            feature > @as(i64, @intCast(FEATURES))) return -1;
    }

    const required = 8 * (count + 1);
    if (output == null or capacity < required) return -2;

    var board: [SLOTS]u8 = @splat(0);
    var hash: u64 = 0;
    for (0..SLOTS) |slot| {
        const feature: u8 = @intCast(input[state_start + slot]);
        board[slot] = feature;
        if (feature != 0) {
            const feature_index: usize = @intCast(feature);
            hash ^= @intCast(input[1 + slot * FEATURES + feature_index - 1]);
        }
    }
    storeHash(output, 0, hash);
    for (0..count) |edit| {
        const slot: usize = @intCast(input[edits_start + 2 * edit]);
        const next: u8 = @intCast(input[edits_start + 2 * edit + 1]);
        const previous = board[slot];
        if (previous != 0) hash ^= @intCast(input[1 + slot * FEATURES + @as(usize, previous) - 1]);
        if (next != 0) hash ^= @intCast(input[1 + slot * FEATURES + @as(usize, next) - 1]);
        board[slot] = next;
        storeHash(output, 8 * (edit + 1), hash);
    }
    return @intCast(required);
}
