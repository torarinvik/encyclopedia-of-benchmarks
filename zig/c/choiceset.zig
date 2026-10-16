const max_operations: usize = 1024;
const max_elements: usize = 256;
const hash_capacity: usize = 512;
const max_key: i64 = 1_000_000_000;

const Slot = struct { index: usize, found: bool };

fn hashSlot(value: i32) usize {
    const bits: u32 = @bitCast(value);
    const mixed = @as(u64, bits) * 2_654_435_761;
    return @intCast(@as(u32, @truncate(mixed)) >> 23);
}

fn findSlot(keys: *const [hash_capacity]i32, states: *const [hash_capacity]u8, value: i32) Slot {
    var slot = hashSlot(value);
    var deleted = hash_capacity;
    for (0..hash_capacity) |_| {
        if (states[slot] == 0) return .{ .index = if (deleted < hash_capacity) deleted else slot, .found = false };
        if (states[slot] == 2) {
            if (deleted == hash_capacity) deleted = slot;
        } else if (keys[slot] == value) return .{ .index = slot, .found = true };
        slot = (slot + 1) % hash_capacity;
    }
    return .{ .index = deleted, .found = false };
}

export fn choiceset(values: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (values == null or length < 1 or values[0] < 0 or values[0] > max_operations) return -1;
    const input = values[0..length];
    const operation_count: usize = @intCast(input[0]);
    if (length != 1 + 2 * operation_count) return -1;
    const output_bytes = operation_count * 8;

    var elements: [max_elements]i32 = @splat(0);
    var map_keys: [hash_capacity]i32 = @splat(0);
    var map_indices: [hash_capacity]usize = @splat(0);
    var states: [hash_capacity]u8 = @splat(0);
    var results: [max_operations]i64 = @splat(0);
    var element_count: usize = 0;

    for (0..operation_count) |operation_index| {
        const operation = input[1 + 2 * operation_index];
        const argument = input[2 + 2 * operation_index];
        if (operation >= 1 and operation <= 3) {
            if (argument < -max_key or argument > max_key) return -1;
            const key: i32 = @intCast(argument);
            const entry = findSlot(&map_keys, &states, key);
            if (operation == 1) {
                if (entry.found) results[operation_index] = 0 else {
                    if (element_count == max_elements or entry.index >= hash_capacity) return -1;
                    elements[element_count] = key;
                    map_keys[entry.index] = key;
                    map_indices[entry.index] = element_count;
                    states[entry.index] = 1;
                    element_count += 1;
                    results[operation_index] = 1;
                }
            } else if (operation == 2) {
                results[operation_index] = if (entry.found) 1 else 0;
            } else if (!entry.found) {
                results[operation_index] = 0;
            } else {
                const index = map_indices[entry.index];
                const last = element_count - 1;
                if (index != last) {
                    const moved = elements[last];
                    const moved_entry = findSlot(&map_keys, &states, moved);
                    if (!moved_entry.found) return -1;
                    elements[index] = moved;
                    map_indices[moved_entry.index] = index;
                }
                element_count -= 1;
                states[entry.index] = 2;
                results[operation_index] = 1;
            }
        } else if (operation == 4) {
            if (argument < 1 or @as(u64, @intCast(argument)) > element_count) return -1;
            results[operation_index] = elements[@intCast(argument - 1)];
        } else return -1;
    }
    if (capacity < output_bytes or (output_bytes > 0 and output == null)) return -2;
    for (0..operation_count) |index| {
        const bits: u64 = @bitCast(results[index]);
        for (0..8) |byte| output[index * 8 + byte] = @truncate(bits >> @intCast(byte * 8));
    }
    return @intCast(output_bytes);
}
