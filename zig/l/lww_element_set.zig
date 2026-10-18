const MAX_OPERATIONS: usize = 24;
const MAX_KEYS: usize = 24;
const MAP_COUNT: usize = 4;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 1 + 4 * MAX_OPERATIONS + 1;
const I32_MIN: i64 = -2_147_483_648;
const I32_MAX: i64 = 2_147_483_647;

export fn lww_element_set(input: [*c]const i64, input_length: usize) i64 {
    if (input == null or input_length < 1 or input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const operation_count_value = input[0];
    if (operation_count_value < 0 or operation_count_value > MAX_OPERATIONS) return -1;
    const operation_count: usize = @intCast(operation_count_value);
    if (input_length != 1 + 4 * operation_count) return -1;

    var keys: [MAP_COUNT * MAX_KEYS]i64 = @splat(0);
    var timestamps: [MAP_COUNT * MAX_KEYS]i64 = @splat(0);
    var map_counts: [MAP_COUNT]usize = @splat(0);
    var lookup_mask: i64 = 0;
    var lookup_index: usize = 0;

    for (0..operation_count) |operation| {
        const offset = 1 + 4 * operation;
        const opcode = input[offset];
        const first = input[offset + 1];
        const second = input[offset + 2];
        const third = input[offset + 3];
        if (opcode == 0 or opcode == 1) {
            if (first < 0 or first > 1 or second < I32_MIN or second > I32_MAX or
                third < I32_MIN or third > I32_MAX) return -1;
            const map_index: usize = @intCast(first * 2 + (if (opcode == 1) @as(i64, 1) else 0));
            const base = map_index * MAX_KEYS;
            var position: usize = 0;
            while (position < map_counts[map_index] and keys[base + position] != second) : (position += 1) {}
            if (position == map_counts[map_index]) {
                if (map_counts[map_index] >= MAX_KEYS) return -1;
                keys[base + position] = second;
                map_counts[map_index] += 1;
            }
            timestamps[base + position] = third;
        } else if (opcode == 2) {
            if (first < 0 or first > 1 or second < I32_MIN or second > I32_MAX or third != 0) return -1;
            const add_map: usize = @intCast(first * 2);
            const add_base = add_map * MAX_KEYS;
            const remove_map = add_map + 1;
            const remove_base = remove_map * MAX_KEYS;
            var add_position: usize = 0;
            var remove_position: usize = 0;
            while (add_position < map_counts[add_map] and keys[add_base + add_position] != second) : (add_position += 1) {}
            while (remove_position < map_counts[remove_map] and keys[remove_base + remove_position] != second) : (remove_position += 1) {}
            if (add_position < map_counts[add_map] and
                (remove_position == map_counts[remove_map] or
                 timestamps[add_base + add_position] > timestamps[remove_base + remove_position])) {
                lookup_mask |= @as(i64, 1) << @intCast(lookup_index);
            }
            lookup_index += 1;
        } else if (opcode == 3) {
            if (first < 0 or first > 1 or second < 0 or second > 1 or third != 0) return -1;
            if (first != second) {
                for (0..2) |kind| {
                    const target_map: usize = @intCast(first * 2 + @as(i64, @intCast(kind)));
                    const source_map: usize = @intCast(second * 2 + @as(i64, @intCast(kind)));
                    const target_base = target_map * MAX_KEYS;
                    const source_base = source_map * MAX_KEYS;
                    for (0..map_counts[source_map]) |source_position| {
                        const key = keys[source_base + source_position];
                        const timestamp = timestamps[source_base + source_position];
                        var target_position: usize = 0;
                        while (target_position < map_counts[target_map] and keys[target_base + target_position] != key) : (target_position += 1) {}
                        if (target_position == map_counts[target_map]) {
                            if (map_counts[target_map] >= MAX_KEYS) return -1;
                            keys[target_base + target_position] = key;
                            timestamps[target_base + target_position] = timestamp;
                            map_counts[target_map] += 1;
                        } else if (timestamp >= timestamps[target_base + target_position]) {
                            timestamps[target_base + target_position] = timestamp;
                        }
                    }
                }
            }
        } else {
            return -1;
        }
    }
    return lookup_mask;
}
