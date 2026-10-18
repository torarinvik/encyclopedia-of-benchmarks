module lww_element_set;

const usz MAX_OPERATIONS = 24;
const usz MAX_KEYS = 24;
const usz MAP_COUNT = 4;
const usz MAX_PARSEABLE_INPUT_LENGTH = 98;
const long I32_MIN = -2147483648;
const long I32_MAX = 2147483647;

fn long lww_element_set(long* input, usz input_length) @export("lww_element_set") {
    if (input == null || input_length < 1 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1L;
    long operation_count_value = input[0];
    if (operation_count_value < 0 || operation_count_value > (long)MAX_OPERATIONS) return -1L;
    usz operation_count = (usz)operation_count_value;
    if (input_length != 1 + 4 * operation_count) return -1L;

    long[MAP_COUNT * MAX_KEYS] keys = zeroed;
    long[MAP_COUNT * MAX_KEYS] timestamps = zeroed;
    usz[MAP_COUNT] map_counts = zeroed;
    long lookup_mask = 0;
    usz lookup_index = 0;

    for (usz operation = 0; operation < operation_count; operation++) {
        usz offset = 1 + 4 * operation;
        long opcode = input[offset];
        long first = input[offset + 1];
        long second = input[offset + 2];
        long third = input[offset + 3];
        if (opcode == 0 || opcode == 1) {
            if (first < 0 || first > 1 || second < I32_MIN || second > I32_MAX ||
                third < I32_MIN || third > I32_MAX) return -1L;
            usz map_index = (usz)first * 2 + (opcode == 1 ? 1 : 0);
            usz base = map_index * MAX_KEYS;
            usz position = 0;
            while (position < map_counts[map_index] && keys[base + position] != second) position++;
            if (position == map_counts[map_index]) {
                if (map_counts[map_index] >= MAX_KEYS) return -1L;
                keys[base + position] = second;
                map_counts[map_index]++;
            }
            timestamps[base + position] = third;
        } else if (opcode == 2) {
            if (first < 0 || first > 1 || second < I32_MIN || second > I32_MAX || third != 0) return -1L;
            usz add_map = (usz)first * 2;
            usz add_base = add_map * MAX_KEYS;
            usz remove_map = add_map + 1;
            usz remove_base = remove_map * MAX_KEYS;
            usz add_position = 0;
            usz remove_position = 0;
            while (add_position < map_counts[add_map] && keys[add_base + add_position] != second) add_position++;
            while (remove_position < map_counts[remove_map] && keys[remove_base + remove_position] != second) remove_position++;
            if (add_position < map_counts[add_map] &&
                (remove_position == map_counts[remove_map] ||
                 timestamps[add_base + add_position] > timestamps[remove_base + remove_position])) {
                lookup_mask |= 1L << lookup_index;
            }
            lookup_index++;
        } else if (opcode == 3) {
            if (first < 0 || first > 1 || second < 0 || second > 1 || third != 0) return -1L;
            if (first != second) {
                for (usz kind = 0; kind < 2; kind++) {
                    usz target_map = (usz)first * 2 + kind;
                    usz source_map = (usz)second * 2 + kind;
                    usz target_base = target_map * MAX_KEYS;
                    usz source_base = source_map * MAX_KEYS;
                    for (usz source_position = 0; source_position < map_counts[source_map]; source_position++) {
                        long key = keys[source_base + source_position];
                        long timestamp = timestamps[source_base + source_position];
                        usz target_position = 0;
                        while (target_position < map_counts[target_map] && keys[target_base + target_position] != key)
                            target_position++;
                        if (target_position == map_counts[target_map]) {
                            if (map_counts[target_map] >= MAX_KEYS) return -1L;
                            keys[target_base + target_position] = key;
                            timestamps[target_base + target_position] = timestamp;
                            map_counts[target_map]++;
                        } else if (timestamp >= timestamps[target_base + target_position]) {
                            timestamps[target_base + target_position] = timestamp;
                        }
                    }
                }
            }
        } else {
            return -1L;
        }
    }
    return lookup_mask;
}
