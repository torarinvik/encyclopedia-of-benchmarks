const MAX_ITEMS: usize = 64;
const MAX_TRIPLETS: usize = 2048;
const HASH_CAPACITY: usize = 128;
const BYTES_PER_TRIPLET: usize = 12;

fn hashSlot(value: i64) usize { return @intCast(@mod((value + 100_000) * 37, 128)); }

fn seenContains(keys: *const [HASH_CAPACITY]i64, occupied: *const [HASH_CAPACITY]bool, value: i64) bool {
    var slot = hashSlot(value);
    for (0..HASH_CAPACITY) |_| {
        if (!occupied[slot]) return false;
        if (keys[slot] == value) return true;
        slot = (slot + 1) % HASH_CAPACITY;
    }
    return false;
}

fn seenAdd(keys: *[HASH_CAPACITY]i64, occupied: *[HASH_CAPACITY]bool, value: i64) void {
    var slot = hashSlot(value);
    for (0..HASH_CAPACITY) |_| {
        if (!occupied[slot]) { keys[slot] = value; occupied[slot] = true; return; }
        if (keys[slot] == value) return;
        slot = (slot + 1) % HASH_CAPACITY;
    }
}

fn alreadyOutput(triples: *const [MAX_TRIPLETS * 3]i64, count: usize, a: i64, b: i64, c: i64) bool {
    for (0..count) |i| if (triples[i * 3] == a and triples[i * 3 + 1] == b and triples[i * 3 + 2] == c) return true;
    return false;
}

fn writeI32Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u32 = @bitCast(@as(i32, @intCast(value)));
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn find_triplets_with_0_sum_hashing(input: [*c]const i64, length: usize, output: [*c]u8, output_capacity: usize) i64 {
    if (length > MAX_ITEMS or (length > 0 and input == null)) return -1;
    for (0..length) |i| if (input[i] < -100_000 or input[i] > 100_000) return -1;
    var triples: [MAX_TRIPLETS * 3]i64 = @splat(0);
    var count: usize = 0;
    for (0..length) |i| {
        if (i + 2 >= length) break;
        var keys: [HASH_CAPACITY]i64 = @splat(0);
        var occupied: [HASH_CAPACITY]bool = @splat(false);
        for (i + 1..length) |j| {
            const other = input[j];
            const required = -input[i] - other;
            if (required >= -100_000 and required <= 100_000 and seenContains(&keys, &occupied, required)) {
                var a = input[i];
                var b = other;
                var c = required;
                if (a > b) { const t = a; a = b; b = t; }
                if (b > c) { const t = b; b = c; c = t; }
                if (a > b) { const t = a; a = b; b = t; }
                if (!alreadyOutput(&triples, count, a, b, c) and count < MAX_TRIPLETS) {
                    triples[count * 3] = a; triples[count * 3 + 1] = b; triples[count * 3 + 2] = c;
                    count += 1;
                }
            }
            seenAdd(&keys, &occupied, other);
        }
    }
    if (count == 0) return 0;
    const needed = count * BYTES_PER_TRIPLET;
    if (output == null or output_capacity < needed) return -2;
    for (0..count * 3) |i| writeI32Le(output, i * 4, triples[i]);
    return @intCast(count);
}
