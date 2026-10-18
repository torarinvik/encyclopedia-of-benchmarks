/* Replay bounded add/remove/lookup/merge traces on two LWW set replicas. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxOperations = 24;
constexpr std::size_t kMaxKeys = 24;
constexpr std::size_t kMapCount = 4;
constexpr std::size_t kMaxParseableInputLength = 1 + 4 * kMaxOperations + 1;
constexpr std::int64_t kI32Min = -2'147'483'648LL;
constexpr std::int64_t kI32Max = 2'147'483'647LL;
}

extern "C" std::int64_t lww_element_set(const std::int64_t *input, std::size_t input_length)
{
    if (input == nullptr || input_length < 1 || input_length > kMaxParseableInputLength) return -1;
    const std::int64_t operation_count_value = input[0];
    if (operation_count_value < 0 || operation_count_value > static_cast<std::int64_t>(kMaxOperations)) return -1;
    const std::size_t operation_count = static_cast<std::size_t>(operation_count_value);
    if (input_length != 1 + 4 * operation_count) return -1;

    std::array<std::int64_t, kMapCount * kMaxKeys> keys{};
    std::array<std::int64_t, kMapCount * kMaxKeys> timestamps{};
    std::array<std::size_t, kMapCount> map_counts{};
    std::int64_t lookup_mask = 0;
    std::size_t lookup_index = 0;

    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const std::size_t offset = 1 + 4 * operation;
        const std::int64_t opcode = input[offset];
        const std::int64_t first = input[offset + 1];
        const std::int64_t second = input[offset + 2];
        const std::int64_t third = input[offset + 3];

        if (opcode == 0 || opcode == 1) {
            if (first < 0 || first > 1 || second < kI32Min || second > kI32Max ||
                third < kI32Min || third > kI32Max) return -1;
            const std::size_t map_index = static_cast<std::size_t>(first) * 2 + (opcode == 1 ? 1u : 0u);
            const std::size_t base = map_index * kMaxKeys;
            std::size_t position = 0;
            while (position < map_counts[map_index] && keys[base + position] != second) ++position;
            if (position == map_counts[map_index]) {
                if (map_counts[map_index] >= kMaxKeys) return -1;
                keys[base + position] = second;
                ++map_counts[map_index];
            }
            timestamps[base + position] = third;
        } else if (opcode == 2) {
            if (first < 0 || first > 1 || second < kI32Min || second > kI32Max || third != 0) return -1;
            const std::size_t add_map = static_cast<std::size_t>(first) * 2;
            const std::size_t add_base = add_map * kMaxKeys;
            const std::size_t remove_map = add_map + 1;
            const std::size_t remove_base = remove_map * kMaxKeys;
            std::size_t add_position = 0;
            std::size_t remove_position = 0;
            while (add_position < map_counts[add_map] && keys[add_base + add_position] != second) ++add_position;
            while (remove_position < map_counts[remove_map] && keys[remove_base + remove_position] != second) ++remove_position;
            if (add_position < map_counts[add_map] &&
                (remove_position == map_counts[remove_map] ||
                 timestamps[add_base + add_position] > timestamps[remove_base + remove_position])) {
                lookup_mask |= std::int64_t{1} << lookup_index;
            }
            ++lookup_index;
        } else if (opcode == 3) {
            if (first < 0 || first > 1 || second < 0 || second > 1 || third != 0) return -1;
            if (first != second) {
                for (std::size_t kind = 0; kind < 2; ++kind) {
                    const std::size_t target_map = static_cast<std::size_t>(first) * 2 + kind;
                    const std::size_t source_map = static_cast<std::size_t>(second) * 2 + kind;
                    const std::size_t target_base = target_map * kMaxKeys;
                    const std::size_t source_base = source_map * kMaxKeys;
                    for (std::size_t source_position = 0; source_position < map_counts[source_map]; ++source_position) {
                        const std::int64_t key = keys[source_base + source_position];
                        const std::int64_t timestamp = timestamps[source_base + source_position];
                        std::size_t target_position = 0;
                        while (target_position < map_counts[target_map] && keys[target_base + target_position] != key)
                            ++target_position;
                        if (target_position == map_counts[target_map]) {
                            if (map_counts[target_map] >= kMaxKeys) return -1;
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
