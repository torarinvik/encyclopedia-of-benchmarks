const MAX_LENGTH: usize = 1024;
const TABLE_SIZE: usize = 2048;
const TABLE_SIZE_I64: i64 = 2048;

fn storeI64Le(output: []u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
    }
}

export fn find_all_duplicates_hash_order(
    input: ?[*]const i64,
    length: usize,
    output: ?[*]u8,
    output_capacity: usize,
) i64 {
    if (length > MAX_LENGTH or (length != 0 and input == null)) return -1;
    const values = if (length == 0) &[_]i64{} else input.?[0..length];
    var keys: [TABLE_SIZE]i64 = @splat(0);
    var counts: [TABLE_SIZE]u16 = @splat(0);
    var insertion_order: [MAX_LENGTH]usize = undefined;
    var unique_count: usize = 0;

    for (values) |value| {
        var signed_slot = @rem(value, TABLE_SIZE_I64);
        if (signed_slot < 0) signed_slot += TABLE_SIZE_I64;
        var slot: usize = @intCast(signed_slot);
        while (counts[slot] != 0 and keys[slot] != value) {
            slot = (slot + 1) % TABLE_SIZE;
        }
        if (counts[slot] == 0) {
            keys[slot] = value;
            counts[slot] = 1;
            insertion_order[unique_count] = slot;
            unique_count += 1;
        } else {
            counts[slot] += 1;
        }
    }

    var duplicate_count: usize = 0;
    for (insertion_order[0..unique_count]) |slot| {
        if (counts[slot] > 1) duplicate_count += 1;
    }
    if (duplicate_count == 0) return 0;
    const required_bytes = duplicate_count * 8;
    if (output == null or output_capacity < required_bytes) return -2;
    const result = output.?[0..output_capacity];

    var written: usize = 0;
    for (insertion_order[0..unique_count]) |slot| {
        if (counts[slot] > 1) {
            storeI64Le(result, written * 8, keys[slot]);
            written += 1;
        }
    }
    return @intCast(duplicate_count);
}
