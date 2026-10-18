/* Collision-free integer-set membership for the shared hash-table contract. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t table_capacity = 17;
constexpr std::int64_t max_insert_count = 8;
constexpr std::int64_t max_query_count = 8;
constexpr std::int64_t max_key = 1000;
constexpr std::size_t max_parseable_length = 19;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
} // namespace

extern "C" std::int64_t hash_table(const std::int64_t *values, std::size_t length,
                                   std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (values == nullptr || length < 2 || length > max_parseable_length) return -1;
    const auto raw_insert_count = values[0];
    if (raw_insert_count < 0 || raw_insert_count > max_insert_count) return -1;
    const auto insert_count = static_cast<std::size_t>(raw_insert_count);
    const auto query_count_index = 1 + insert_count;
    if (query_count_index >= length) return -1;
    const auto raw_query_count = values[query_count_index];
    if (raw_query_count < 1 || raw_query_count > max_query_count) return -1;
    const auto query_count = static_cast<std::size_t>(raw_query_count);
    const auto query_start = query_count_index + 1;
    const auto total_keys = insert_count + query_count;
    if (length != query_start + query_count) return -1;

    for (std::size_t index = 0; index < total_keys; ++index) {
        const auto position = index < insert_count ? 1 + index : query_start + index - insert_count;
        const auto key = values[position];
        if (key < 1 || key > max_key) return -1;
        for (std::size_t prior = 0; prior < index; ++prior) {
            const auto prior_position = prior < insert_count ? 1 + prior : query_start + prior - insert_count;
            const auto other = values[prior_position];
            const bool same_group = (index < insert_count) == (prior < insert_count);
            if (key == other) {
                if (same_group) return -1;
            } else if (key % static_cast<std::int64_t>(table_capacity) ==
                           other % static_cast<std::int64_t>(table_capacity) ||
                       key % 3000 == other % 3000) {
                return -1;
            }
        }
    }

    std::array<std::int64_t, table_capacity> table{};
    for (std::size_t index = 0; index < insert_count; ++index) {
        const auto key = values[1 + index];
        table[static_cast<std::size_t>(key % static_cast<std::int64_t>(table_capacity))] = key;
    }

    const auto output_bytes = 8 * query_count;
    if (output == nullptr || output_capacity < output_bytes) return -2;
    for (std::size_t index = 0; index < query_count; ++index) {
        const auto query = values[query_start + index];
        const std::int64_t found =
            table[static_cast<std::size_t>(query % static_cast<std::int64_t>(table_capacity))] == query ? 1 : 0;
        store_i64_le(output, 8 * index, found);
    }
    return static_cast<std::int64_t>(output_bytes);
}
