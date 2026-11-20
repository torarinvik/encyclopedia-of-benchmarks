const SLOTS: usize = 16;
const H: usize = 4;
const MAX_OPS: usize = 32;
const MAX_WORDS: usize = 1 + 3 * MAX_OPS;

fn distance(from: usize, to: usize) usize {
    return (to + SLOTS - from) % SLOTS;
}

fn contains(keys: []const i16, hops: []const u8, key: i16, home: usize) bool {
    for (0..H) |offset| {
        if ((hops[home] & (@as(u8, 1) << @intCast(offset))) != 0 and
            keys[(home + offset) % SLOTS] == key) return true;
    }
    return false;
}

fn insert(keys: []i16, homes: []u8, hops: []u8, key: i16, home: usize) u8 {
    if (contains(keys, hops, key, home)) return 2;
    var hole: ?usize = null;
    for (0..SLOTS) |step| {
        const slot = (home + step) % SLOTS;
        if (keys[slot] < 0) {
            hole = slot;
            break;
        }
    }
    if (hole == null) return 0;
    var empty = hole.?;
    var reach = distance(home, empty);
    while (reach >= H) {
        var shifted = false;
        var back = H - 1;
        while (back > 0) : (back -= 1) {
            const bucket = (empty + SLOTS - back) % SLOTS;
            const new_offset = distance(bucket, empty);
            if (distance(home, bucket) >= reach) continue;
            for (0..new_offset) |old_offset| {
                if ((hops[bucket] & (@as(u8, 1) << @intCast(old_offset))) == 0) continue;
                const old_slot = (bucket + old_offset) % SLOTS;
                if (keys[old_slot] < 0 or homes[old_slot] != bucket or
                    distance(home, old_slot) >= reach) continue;
                keys[empty] = keys[old_slot];
                homes[empty] = homes[old_slot];
                keys[old_slot] = -1;
                homes[old_slot] = 0;
                hops[bucket] ^= @as(u8, 1) << @intCast(old_offset);
                hops[bucket] |= @as(u8, 1) << @intCast(new_offset);
                empty = old_slot;
                reach = distance(home, empty);
                shifted = true;
                break;
            }
            if (shifted) break;
        }
        if (!shifted) return 0;
    }
    keys[empty] = key;
    homes[empty] = @intCast(home);
    hops[home] |= @as(u8, 1) << @intCast(reach);
    return 1;
}

pub export fn hash_map_hopscotch_hashing(
    input: [*c]const i64,
    length: usize,
    output: [*c]u8,
    capacity: usize,
) i64 {
    if (input == null or length < 1 or length > MAX_WORDS) return -1;
    const count_value = input[0];
    if (count_value < 0 or count_value > MAX_OPS) return -1;
    const count: usize = @intCast(count_value);
    if (length != 1 + 3 * count) return -1;

    var known_home: [64]i8 = @splat(-1);
    for (0..count) |op| {
        const opcode = input[1 + 3 * op];
        const key = input[2 + 3 * op];
        const home = input[3 + 3 * op];
        if ((opcode != 1 and opcode != 2) or key < 0 or key >= 64 or home < 0 or home >= SLOTS)
            return -1;
        const key_index: usize = @intCast(key);
        if (known_home[key_index] >= 0 and known_home[key_index] != home) return -1;
        known_home[key_index] = @intCast(home);
    }

    const required = count + 2 * SLOTS;
    if (output == null or capacity < required) return -2;
    var keys: [SLOTS]i16 = @splat(-1);
    var homes: [SLOTS]u8 = @splat(0);
    var hops: [SLOTS]u8 = @splat(0);
    var statuses: [MAX_OPS]u8 = @splat(0);
    for (0..count) |op| {
        const opcode = input[1 + 3 * op];
        const key: i16 = @intCast(input[2 + 3 * op]);
        const home: usize = @intCast(input[3 + 3 * op]);
        statuses[op] = if (opcode == 1)
            insert(keys[0..], homes[0..], hops[0..], key, home)
        else
            @intFromBool(contains(keys[0..], hops[0..], key, home));
    }

    for (0..count) |op| output[op] = statuses[op];
    for (0..SLOTS) |slot| {
        output[count + slot] = if (keys[slot] < 0) 0 else @intCast(keys[slot] + 1);
        output[count + SLOTS + slot] = hops[slot];
    }
    return @intCast(required);
}
