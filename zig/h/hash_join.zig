const MAX_ROWS: usize = 8;
const HASH_CAPACITY: usize = 17;
const MAX_INPUT: usize = 19;
const MAX_OUTPUT: usize = 64;

fn bucketFor(key: i64) usize {
    var remainder = @rem(key, 17);
    if (remainder < 0) remainder += 17;
    return @intCast(remainder);
}

export fn hash_join(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT) return -1;
    const values = input.?[0..length];
    if (values[0] < 0 or values[0] > 8 or values[1] < 0 or values[1] > 8) return -1;
    const left_count: usize = @intCast(values[0]);
    const right_count: usize = @intCast(values[1]);
    if (length != 2 + left_count + right_count) return -1;

    const build_left = left_count < right_count;
    const build_count = if (build_left) left_count else right_count;
    const probe_count = if (build_left) right_count else left_count;
    const build_offset = if (build_left) 2 else 2 + left_count;
    const probe_offset = if (build_left) 2 + left_count else 2;
    var keys: [HASH_CAPACITY]i64 = @splat(0);
    var occupied: [HASH_CAPACITY]bool = @splat(false);
    var heads: [HASH_CAPACITY]i32 = @splat(-1);
    var tails: [HASH_CAPACITY]i32 = @splat(-1);
    var next_row: [MAX_ROWS]i32 = @splat(-1);
    var staged: [MAX_OUTPUT]u8 = @splat(0);

    for (0..build_count) |row| {
        const key = values[build_offset + row];
        var slot = bucketFor(key);
        while (occupied[slot] and keys[slot] != key) slot = (slot + 1) % HASH_CAPACITY;
        if (!occupied[slot]) { occupied[slot] = true; keys[slot] = key; }
        if (tails[slot] < 0) heads[slot] = @intCast(row)
        else next_row[@intCast(tails[slot])] = @intCast(row);
        tails[slot] = @intCast(row);
    }

    var match_count: usize = 0;
    for (0..probe_count) |probe_row| {
        const key = values[probe_offset + probe_row];
        var slot = bucketFor(key);
        while (occupied[slot] and keys[slot] != key) slot = (slot + 1) % HASH_CAPACITY;
        if (!occupied[slot]) continue;
        var build_row = heads[slot];
        while (build_row >= 0) {
            const build_id: usize = @intCast(build_row);
            const left_id = if (build_left) build_id else probe_row;
            const right_id = if (build_left) probe_row else build_id;
            staged[match_count] = @intCast((left_id << 4) | right_id);
            match_count += 1;
            build_row = next_row[build_id];
        }
    }
    if (output == null or capacity < match_count) return -2;
    const destination = output.?;
    for (0..match_count) |i| destination[i] = staged[i];
    return @intCast(match_count);
}
