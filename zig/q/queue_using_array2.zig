const MAX_Q: usize = 256;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_Q;
const VALUE_LIMIT: i64 = 1_000_000;
const VALUE_OFFSET: i64 = 1_000_001;
const HASH_MULTIPLIER: i64 = 1_000_003;
const HASH_MODULUS: i64 = 1_000_000_007;

export fn queue_using_array2(packed: ?[*]const i64, length: usize) i64 {
    if (length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input = packed orelse return -1;
    const qv = input[0];
    if (qv < 0 or qv > @as(i64, @intCast(MAX_Q)) or length != 1 + @as(usize, @intCast(qv)) * 2) return -1;
    const q: usize = @intCast(qv);
    for (0..q) |i| {
        const op = input[1 + i * 2];
        const value = input[2 + i * 2];
        if (op == 1) { if (value < -VALUE_LIMIT or value > VALUE_LIMIT) return -1; }
        else if (op == 2 or op == 3) { if (value != 0) return -1; }
        else return -1;
    }

    var values: [10]i64 = @splat(0);
    var count: usize = 0;
    var hash: i64 = 0;
    for (0..q) |i| {
        const op = input[1 + i * 2];
        const value = input[2 + i * 2];
        if (op == 1) {
            if (count < 10) { values[count] = value; count += 1; }
        } else if (op == 2 and count > 0) {
            for (1..count) |j| values[j - 1] = values[j];
            count -= 1;
        }

        hash = @mod(hash * HASH_MULTIPLIER + op, HASH_MODULUS);
        hash = @mod(hash * HASH_MULTIPLIER + @as(i64, @intCast(count)), HASH_MODULUS);
        for (0..count) |j| {
            hash = @mod(hash * HASH_MULTIPLIER + values[j] + VALUE_OFFSET, HASH_MODULUS);
        }
    }
    return hash;
}
