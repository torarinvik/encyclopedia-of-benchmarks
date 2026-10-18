/* Replay bounded add/remove/lookup/merge traces on two LWW set replicas. */
#include <stddef.h>
#include <stdint.h>

#define MAX_OPERATIONS 24
#define MAX_KEYS 24
#define MAP_COUNT 4
#define MAX_PARSEABLE_INPUT_LENGTH (1 + 4 * MAX_OPERATIONS + 1)

int64_t lww_element_set(const int64_t *input, size_t input_length)
{
    if (input == NULL || input_length < 1 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;

    const int64_t operation_count_value = input[0];
    if (operation_count_value < 0 || operation_count_value > MAX_OPERATIONS) return -1;
    const size_t operation_count = (size_t)operation_count_value;
    if (input_length != 1 + 4 * operation_count) return -1;

    int64_t keys[MAP_COUNT * MAX_KEYS] = {0};
    int64_t timestamps[MAP_COUNT * MAX_KEYS] = {0};
    size_t map_counts[MAP_COUNT] = {0};
    int64_t lookup_mask = 0;
    size_t lookup_index = 0;

    for (size_t operation = 0; operation < operation_count; ++operation) {
        const size_t offset = 1 + 4 * operation;
        const int64_t opcode = input[offset];
        const int64_t first = input[offset + 1];
        const int64_t second = input[offset + 2];
        const int64_t third = input[offset + 3];

        if (opcode == 0 || opcode == 1) {
            if (first < 0 || first > 1 || second < INT32_MIN || second > INT32_MAX ||
                third < INT32_MIN || third > INT32_MAX) return -1;
            const size_t map_index = (size_t)first * 2 + (opcode == 1 ? 1u : 0u);
            const size_t base = map_index * MAX_KEYS;
            size_t position = 0;
            while (position < map_counts[map_index] && keys[base + position] != second) ++position;
            if (position == map_counts[map_index]) {
                if (map_counts[map_index] >= MAX_KEYS) return -1;
                keys[base + position] = second;
                ++map_counts[map_index];
            }
            timestamps[base + position] = third;
        } else if (opcode == 2) {
            if (first < 0 || first > 1 || second < INT32_MIN || second > INT32_MAX || third != 0)
                return -1;
            const size_t add_map = (size_t)first * 2;
            const size_t add_base = add_map * MAX_KEYS;
            const size_t remove_map = add_map + 1;
            const size_t remove_base = remove_map * MAX_KEYS;
            size_t add_position = 0;
            size_t remove_position = 0;
            while (add_position < map_counts[add_map] && keys[add_base + add_position] != second)
                ++add_position;
            while (remove_position < map_counts[remove_map] && keys[remove_base + remove_position] != second)
                ++remove_position;
            if (add_position < map_counts[add_map] &&
                (remove_position == map_counts[remove_map] ||
                 timestamps[add_base + add_position] > timestamps[remove_base + remove_position])) {
                lookup_mask |= INT64_C(1) << lookup_index;
            }
            ++lookup_index;
        } else if (opcode == 3) {
            if (first < 0 || first > 1 || second < 0 || second > 1 || third != 0) return -1;
            if (first != second) {
                for (size_t kind = 0; kind < 2; ++kind) {
                    const size_t target_map = (size_t)first * 2 + kind;
                    const size_t source_map = (size_t)second * 2 + kind;
                    const size_t target_base = target_map * MAX_KEYS;
                    const size_t source_base = source_map * MAX_KEYS;
                    for (size_t source_position = 0; source_position < map_counts[source_map]; ++source_position) {
                        const int64_t key = keys[source_base + source_position];
                        const int64_t timestamp = timestamps[source_base + source_position];
                        size_t target_position = 0;
                        while (target_position < map_counts[target_map] &&
                               keys[target_base + target_position] != key) ++target_position;
                        if (target_position == map_counts[target_map]) {
                            if (map_counts[target_map] >= MAX_KEYS) return -1;
                            keys[target_base + target_position] = key;
                            timestamps[target_base + target_position] = timestamp;
                            ++map_counts[target_map];
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
