/// Count three-array occurrences and emit keys with total count exactly three.
const ARRAY_COUNT: usize = 3;
const MAX_ARRAY_LENGTH: usize = 64;
const MAX_INPUT_LENGTH: usize = ARRAY_COUNT * (MAX_ARRAY_LENGTH + 1);
const MAX_OCCURRENCES: usize = ARRAY_COUNT * MAX_ARRAY_LENGTH;
const TABLE_SIZE: usize = 257;

fn addOccurrence(
    value: i64,
    keys: *[TABLE_SIZE]i64,
    counts: *[TABLE_SIZE]usize,
    occupied: *[TABLE_SIZE]bool,
    order: *[MAX_OCCURRENCES]usize,
    order_length: *usize,
) void {
    var remainder = @rem(value, @as(i64, TABLE_SIZE));
    if (remainder < 0) remainder += @as(i64, TABLE_SIZE);
    var slot: usize = @intCast(remainder);
    while (occupied[slot] and keys[slot] != value) slot = (slot + 1) % TABLE_SIZE;
    if (!occupied[slot]) {
        occupied[slot] = true;
        keys[slot] = value;
        counts[slot] = 0;
        order[order_length.*] = slot;
        order_length.* += 1;
    }
    counts[slot] += 1;
}

fn storeI32Le(output: [*]u8, position: usize, value: i64) void {
    const bits: u32 = @bitCast(@as(i32, @intCast(value)));
    for (0..4) |byte|
        output[position + byte] = @truncate(bits >> @as(u5, @intCast(byte * 8)));
}

export fn arrays_intersection(raw_input: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < ARRAY_COUNT or length > MAX_INPUT_LENGTH) return -1;
    const input = raw_input[0..length];
    var starts: [ARRAY_COUNT]usize = undefined;
    var sizes: [ARRAY_COUNT]usize = undefined;
    var position: usize = 0;
    for (0..ARRAY_COUNT) |array| {
        if (position >= length or input[position] < 0 or input[position] > MAX_ARRAY_LENGTH) return -1;
        const size: usize = @intCast(input[position]);
        position += 1;
        if (size > length - position) return -1;
        starts[array] = position;
        sizes[array] = size;
        for (input[position .. position + size]) |value| {
            if (value < -2147483648 or value > 2147483647) return -1;
        }
        position += size;
    }
    if (position != length) return -1;

    var keys: [TABLE_SIZE]i64 = @splat(0);
    var counts: [TABLE_SIZE]usize = @splat(0);
    var occupied: [TABLE_SIZE]bool = @splat(false);
    var order: [MAX_OCCURRENCES]usize = undefined;
    var order_length: usize = 0;
    for (0..ARRAY_COUNT) |array| {
        for (0..sizes[array]) |index| {
            addOccurrence(input[starts[array] + index], &keys, &counts, &occupied, &order, &order_length);
        }
    }

    var match_count: usize = 0;
    for (order[0..order_length]) |slot| {
        if (counts[slot] == ARRAY_COUNT) match_count += 1;
    }
    const required = match_count * 4;
    if (output_capacity < required) return -2;
    var written: usize = 0;
    for (order[0..order_length]) |slot| {
        if (counts[slot] == ARRAY_COUNT) {
            storeI32Le(output, written * 4, keys[slot]);
            written += 1;
        }
    }
    return @intCast(written);
}
