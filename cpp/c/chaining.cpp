#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t chaining(const std::int64_t *input, std::size_t length)
{
    if (input == nullptr || length < 2 || length > 260) return -1;
    const std::int64_t bucket_count_value = input[0];
    const std::int64_t operation_count_value = input[1];
    if (bucket_count_value < 1 || bucket_count_value > 127
            || operation_count_value < 0 || operation_count_value > 128) return -1;
    const auto bucket_count = static_cast<std::size_t>(bucket_count_value);
    const auto operation_count = static_cast<std::size_t>(operation_count_value);
    if (length != 2 + 2 * operation_count) return -1;

    std::array<std::int64_t, 127> heads{};
    std::array<std::int64_t, 128> keys{};
    std::array<std::int64_t, 128> next{};
    heads.fill(-1);
    std::size_t inserted = 0;
    std::size_t query_count = 0;
    std::uint64_t result = 0;
    for (std::size_t operation_index = 0; operation_index < operation_count; ++operation_index) {
        const std::int64_t operation = input[2 + 2 * operation_index];
        const std::int64_t key = input[3 + 2 * operation_index];
        if ((operation != 0 && operation != 1) || key < 0 || key > INT32_MAX) return -1;
        const auto bucket = static_cast<std::size_t>(key % bucket_count_value);
        if (operation == 0) {
            if (inserted >= keys.size()) return -1;
            keys[inserted] = key;
            next[inserted] = -1;
            if (heads[bucket] < 0) heads[bucket] = static_cast<std::int64_t>(inserted);
            else {
                auto node = heads[bucket];
                while (next[static_cast<std::size_t>(node)] >= 0)
                    node = next[static_cast<std::size_t>(node)];
                next[static_cast<std::size_t>(node)] = static_cast<std::int64_t>(inserted);
            }
            ++inserted;
        } else {
            if (query_count >= 63) return -1;
            auto node = heads[bucket];
            while (node >= 0 && keys[static_cast<std::size_t>(node)] != key)
                node = next[static_cast<std::size_t>(node)];
            if (node >= 0) result |= UINT64_C(1) << query_count;
            ++query_count;
        }
    }
    return static_cast<std::int64_t>(result);
}
