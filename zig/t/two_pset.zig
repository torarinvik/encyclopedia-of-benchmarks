const MAX_Q: usize = 256;
const MAX_INPUT_LENGTH: usize = 1 + 4 * MAX_Q;
const HASH_MULTIPLIER: i64 = 1_000_003;
const HASH_MODULUS: i64 = 1_000_000_007;

export fn two_pset(packed: ?[*]const i64, length: usize) i64 {
    if (length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input = packed orelse return -1;
    const qv = input[0];
    if (qv < 0 or qv > @as(i64, @intCast(MAX_Q)) or length != 1 + @as(usize, @intCast(qv)) * 4) return -1;
    const q: usize = @intCast(qv);
    for (0..q) |i| {
        const op = input[1 + i * 4];
        const set_id = input[2 + i * 4];
        const value = input[3 + i * 4];
        const other_id = input[4 + i * 4];
        if (op >= 0 and op <= 2) {
            if (set_id < 0 or set_id > 1 or value < 0 or value > 63 or other_id != 0) return -1;
        } else if (op == 3 or op == 4) {
            if (set_id < 0 or set_id > 1 or value != 0 or other_id < 0 or other_id > 1) return -1;
        } else return -1;
    }

    var additions: [128]i64 = @splat(0);
    var tombstones: [128]i64 = @splat(0);
    var digest: i64 = 0;
    for (0..q) |i| {
        const op = input[1 + i * 4];
        const set_id = @as(usize, @intCast(input[2 + i * 4]));
        const value = input[3 + i * 4];
        const other_id = @as(usize, @intCast(input[4 + i * 4]));
        const base = set_id * 64;
        var operation_result: i64 = 0;
        if (op == 0) {
            additions[base + @as(usize, @intCast(value))] = 1;
        } else if (op == 1) {
            const index = base + @as(usize, @intCast(value));
            if (additions[index] != 0 and tombstones[index] == 0) tombstones[index] = 1;
        } else if (op == 2) {
            const index = base + @as(usize, @intCast(value));
            if (additions[index] != 0 and tombstones[index] == 0) operation_result = 1;
        } else if (op == 3) {
            const other_base = other_id * 64;
            var subset = true;
            for (0..64) |e| {
                if ((additions[base + e] != 0 and additions[other_base + e] == 0) or
                    (tombstones[base + e] != 0 and tombstones[other_base + e] == 0)) subset = false;
            }
            if (subset) operation_result = 1;
        } else {
            const other_base = other_id * 64;
            for (0..64) |e| {
                if (additions[base + e] != 0 or additions[other_base + e] != 0) additions[base + e] = 1;
                if (tombstones[base + e] != 0 or tombstones[other_base + e] != 0) tombstones[base + e] = 1;
            }
        }
        digest = @mod(digest * HASH_MULTIPLIER + op, HASH_MODULUS);
        digest = @mod(digest * HASH_MULTIPLIER + operation_result, HASH_MODULUS);
    }

    for (0..2) |set_id| {
        const base = set_id * 64;
        for (0..64) |e| digest = @mod(digest * HASH_MULTIPLIER + additions[base + e], HASH_MODULUS);
        for (0..64) |e| digest = @mod(digest * HASH_MULTIPLIER + tombstones[base + e], HASH_MODULUS);
    }
    return digest;
}
