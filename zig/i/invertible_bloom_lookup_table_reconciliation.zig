const SET_LIMIT: usize = 8;
const KEY_LIMIT: i64 = 63;
const CELL_COUNT: usize = 48;
const MAX_PEELS: usize = 16;
const MAX_INPUT: usize = 18;

fn checksum(key: i64) i64 { return key * key + 3 * key + 7; }

fn location(key: i64, part: usize) usize {
    const x: usize = @intCast(key);
    if (part == 0) return x % 16;
    if (part == 1) return 16 + ((3 * x + 5) % 16);
    return 32 + ((5 * x + 9) % 16);
}

fn writeI64Le(output: [*c]u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[word * 8 + byte] = @truncate(bits >> @intCast(8 * byte));
}

pub export fn invertible_bloom_lookup_table_reconciliation(
    input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize,
) i64 {
    if (input == null or length < 2 or length > MAX_INPUT + 1) return -1;
    const a_raw = input[0];
    const b_raw = input[1];
    if (a_raw < 0 or a_raw > SET_LIMIT or b_raw < 0 or b_raw > SET_LIMIT) return -1;
    const a_count: usize = @intCast(a_raw);
    const b_count: usize = @intCast(b_raw);
    if (length != 2 + a_count + b_count) return -1;
    for (0..2) |side| {
        const count = if (side == 0) a_count else b_count;
        const start = if (side == 0) 2 else 2 + a_count;
        var previous: i64 = -1;
        for (0..count) |i| {
            const key = input[start + i];
            if (key < 0 or key > KEY_LIMIT or key <= previous) return -1;
            previous = key;
        }
    }

    var counts: [CELL_COUNT]i64 = @splat(0);
    var sums: [CELL_COUNT]i64 = @splat(0);
    var checks: [CELL_COUNT]i64 = @splat(0);
    for (0..2) |side| {
        const count = if (side == 0) a_count else b_count;
        const start = if (side == 0) 2 else 2 + a_count;
        const sign: i64 = if (side == 0) 1 else -1;
        for (0..count) |i| {
            const key = input[start + i];
            for (0..3) |part| {
                const slot = location(key, part);
                counts[slot] += sign;
                sums[slot] += sign * key;
                checks[slot] += sign * checksum(key);
            }
        }
    }

    var positive: [MAX_PEELS]i64 = @splat(0);
    var negative: [MAX_PEELS]i64 = @splat(0);
    var positive_count: usize = 0;
    var negative_count: usize = 0;
    var repeated = false;
    for (0..MAX_PEELS) |_| {
        var zero = true;
        for (0..CELL_COUNT) |i| {
            if (counts[i] != 0 or sums[i] != 0 or checks[i] != 0) { zero = false; break; }
        }
        if (zero) break;
        var found = false;
        var selected_sign: i64 = 0;
        var key: i64 = 0;
        for (0..CELL_COUNT) |i| {
            if (counts[i] != 1 and counts[i] != -1) continue;
            const sign = counts[i];
            const candidate = sign * sums[i];
            if (candidate < 0 or candidate > KEY_LIMIT or checks[i] != sign * checksum(candidate)) continue;
            selected_sign = sign;
            key = candidate;
            found = true;
            break;
        }
        if (!found) break;
        for (0..positive_count) |i| if (positive[i] == key) { repeated = true; };
        for (0..negative_count) |i| if (negative[i] == key) { repeated = true; };
        if (repeated) break;
        if (selected_sign > 0) { positive[positive_count] = key; positive_count += 1; }
        else { negative[negative_count] = key; negative_count += 1; }
        for (0..3) |part| {
            const slot = location(key, part);
            counts[slot] -= selected_sign;
            sums[slot] -= selected_sign * key;
            checks[slot] -= selected_sign * checksum(key);
        }
    }

    var zero = true;
    for (0..CELL_COUNT) |i| if (counts[i] != 0 or sums[i] != 0 or checks[i] != 0) { zero = false; };
    for (1..positive_count) |i| {
        const value = positive[i];
        var j = i;
        while (j > 0 and positive[j - 1] > value) { positive[j] = positive[j - 1]; j -= 1; }
        positive[j] = value;
    }
    for (1..negative_count) |i| {
        const value = negative[i];
        var j = i;
        while (j > 0 and negative[j - 1] > value) { negative[j] = negative[j - 1]; j -= 1; }
        negative[j] = value;
    }

    var staged: [3 + 2 * MAX_PEELS]i64 = @splat(0);
    var words: usize = 0;
    staged[words] = if (!repeated and zero) 1 else 0;
    words += 1;
    staged[words] = @intCast(positive_count);
    words += 1;
    staged[words] = @intCast(negative_count);
    words += 1;
    for (0..positive_count) |i| { staged[words] = positive[i]; words += 1; }
    for (0..negative_count) |i| { staged[words] = negative[i]; words += 1; }
    const required = words * 8;
    if (output == null or capacity < required) return -2;
    for (0..words) |i| writeI64Le(output, i, staged[i]);
    return @intCast(required);
}
