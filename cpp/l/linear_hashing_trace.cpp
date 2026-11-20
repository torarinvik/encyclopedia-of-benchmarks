#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_operations = 63;
constexpr std::size_t max_buckets = 32;

std::size_t bucket_index(std::int64_t key, std::size_t level, std::size_t split) {
    const std::size_t base = std::size_t{1} << level;
    auto remainder = key % static_cast<std::int64_t>(base);
    if (remainder < 0) remainder += static_cast<std::int64_t>(base);
    std::size_t index = static_cast<std::size_t>(remainder);
    if (index < split) {
        remainder = key % static_cast<std::int64_t>(base << 1);
        if (remainder < 0) remainder += static_cast<std::int64_t>(base << 1);
        index = static_cast<std::size_t>(remainder);
    }
    return index;
}
}

extern "C" std::int64_t linear_hashing_trace(const std::int64_t *values,
                                               std::size_t length) {
    if (values == nullptr || length < 1 || length > 128) return -1;
    const std::int64_t operation_count = values[0];
    if (operation_count < 0 || operation_count > static_cast<std::int64_t>(max_operations)
        || length != static_cast<std::size_t>(1 + 2 * operation_count)) return -1;

    std::array<std::int32_t, max_buckets> heads;
    heads.fill(-1);
    std::array<std::int64_t, max_operations> keys{};
    std::array<std::int32_t, max_operations> links{};
    std::size_t level = 1;
    std::size_t split = 0;
    std::size_t live_count = 0;
    std::size_t allocated = 0;
    std::int64_t result = 0;

    for (std::size_t operation = 0; operation < static_cast<std::size_t>(operation_count); ++operation) {
        const auto opcode = values[1 + 2 * operation];
        const auto key = values[2 + 2 * operation];
        if (opcode < 0 || opcode > 2 || key < -1024 || key > 1023) return -1;
        const auto bucket = bucket_index(key, level, split);
        std::int32_t previous = -1;
        std::int32_t node = heads[bucket];
        while (node != -1 && keys[static_cast<std::size_t>(node)] != key) {
            previous = node;
            node = links[static_cast<std::size_t>(node)];
        }
        const bool found = node != -1;
        std::int64_t succeeded = 0;

        if (opcode == 0 && !found) {
            node = static_cast<std::int32_t>(allocated++);
            keys[static_cast<std::size_t>(node)] = key;
            links[static_cast<std::size_t>(node)] = heads[bucket];
            heads[bucket] = node;
            ++live_count;
            succeeded = 1;

            const auto base = std::size_t{1} << level;
            const auto bucket_count = base + split;
            if (bucket_count < max_buckets && live_count > 2 * bucket_count) {
                const auto old_bucket = split;
                const auto new_bucket = base + split;
                auto current = heads[old_bucket];
                heads[old_bucket] = -1;
                while (current != -1) {
                    const auto following = links[static_cast<std::size_t>(current)];
                    auto remainder = keys[static_cast<std::size_t>(current)]
                                   % static_cast<std::int64_t>(base << 1);
                    if (remainder < 0) remainder += static_cast<std::int64_t>(base << 1);
                    if (static_cast<std::size_t>(remainder) == new_bucket) {
                        links[static_cast<std::size_t>(current)] = heads[new_bucket];
                        heads[new_bucket] = current;
                    } else {
                        links[static_cast<std::size_t>(current)] = heads[old_bucket];
                        heads[old_bucket] = current;
                    }
                    current = following;
                }
                ++split;
                if (split == base) {
                    ++level;
                    split = 0;
                }
            }
        } else if (opcode == 1 && found) {
            if (previous == -1) heads[bucket] = links[static_cast<std::size_t>(node)];
            else links[static_cast<std::size_t>(previous)] = links[static_cast<std::size_t>(node)];
            --live_count;
            succeeded = 1;
        } else if (opcode == 2 && found) {
            succeeded = 1;
        }
        result = (result << 1) | succeeded;
    }
    return result;
}
