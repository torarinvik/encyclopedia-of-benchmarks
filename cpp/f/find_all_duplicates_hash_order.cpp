#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t find_all_duplicates_hash_order(const std::int64_t *input,
                                                        std::size_t length,
                                                        std::uint8_t *output,
                                                        std::size_t capacity) noexcept {
    constexpr std::size_t max_length = 1024, table_size = 2048;
    if (length > max_length || (length > 0 && input == nullptr)) return -1;
    std::array<std::int64_t, table_size> keys{}, counts{};
    std::array<std::uint8_t, table_size> used{};
    std::array<std::size_t, max_length> insertion_order{};
    std::size_t unique_count = 0;
    for (std::size_t i = 0; i < length; ++i) {
        auto remainder = input[i] % static_cast<std::int64_t>(table_size);
        if (remainder < 0) remainder += table_size;
        auto slot = static_cast<std::size_t>(remainder);
        while (used[slot] && keys[slot] != input[i]) slot = (slot + 1) & (table_size - 1);
        if (!used[slot]) { used[slot] = 1; keys[slot] = input[i]; counts[slot] = 1; insertion_order[unique_count++] = slot; }
        else ++counts[slot];
    }
    std::size_t duplicate_count = 0;
    for (std::size_t i = 0; i < unique_count; ++i) if (counts[insertion_order[i]] > 1) ++duplicate_count;
    const auto required = duplicate_count * sizeof(std::int64_t);
    if (capacity < required || (required > 0 && output == nullptr)) return -2;
    std::size_t out = 0;
    for (std::size_t i = 0; i < unique_count; ++i) {
        const auto slot = insertion_order[i];
        if (counts[slot] <= 1) continue;
        const auto bits = static_cast<std::uint64_t>(keys[slot]);
        for (std::size_t byte = 0; byte < 8; ++byte) output[out++] = static_cast<std::uint8_t>(bits >> (8 * byte));
    }
    return static_cast<std::int64_t>(duplicate_count);
}
