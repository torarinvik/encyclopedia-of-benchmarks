/// Group cubes by sorted decimal digits and return the first cube in the target group.
const TABLE_SIZE: usize = 16_384;
const MAX_BASE: usize = 8_384;
const SIGNATURE_LENGTH_FACTOR: i64 = 4_503_599_627_370_496;

fn digitSignature(cube: i64) i64 {
    var counts = [_]i64{0} ** 10;
    var length: i64 = 0;
    var remaining = cube;
    while (remaining > 0) {
        counts[@intCast(@mod(remaining, 10))] += 1;
        length += 1;
        remaining = @divTrunc(remaining, 10);
    }
    if (length == 0) {
        counts[0] = 1;
        length = 1;
    }
    var sorted_digits: i64 = 0;
    for (counts, 0..) |count, digit| {
        var occurrence: i64 = 0;
        while (occurrence < count) : (occurrence += 1) {
            sorted_digits = sorted_digits * 16 + @as(i64, @intCast(digit));
        }
    }
    return length * SIGNATURE_LENGTH_FACTOR + sorted_digits;
}

fn signatureSlot(key: i64) usize {
    const size: i64 = @intCast(TABLE_SIZE);
    const hash = (key % size + (key / size % size) * 31 +
        (key / (size * size) % size) * 17 +
        (key / (size * size * size) % size) * 7) % size;
    return @intCast(hash);
}

pub export fn problem62(target_count: i64) i64 {
    if (target_count < 1 or target_count > 5) return -1;
    var keys: [TABLE_SIZE]i64 = @splat(0);
    var first_cubes: [TABLE_SIZE]i64 = @splat(0);
    var counts: [TABLE_SIZE]i64 = @splat(0);
    for (0..MAX_BASE + 1) |base| {
        const base_i64: i64 = @intCast(base);
        const cube = base_i64 * base_i64 * base_i64;
        const key = digitSignature(cube);
        var slot = signatureSlot(key);
        while (keys[slot] != 0 and keys[slot] != key) {
            slot = (slot + 1) % TABLE_SIZE;
        }
        if (keys[slot] == 0) {
            keys[slot] = key;
            first_cubes[slot] = cube;
        }
        counts[slot] += 1;
        if (counts[slot] == target_count) return first_cubes[slot];
    }
    return -1;
}
