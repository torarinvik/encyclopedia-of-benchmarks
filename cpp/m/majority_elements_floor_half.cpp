#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t majority_elements_floor_half(const std::int64_t *input,
                                                      std::size_t length,
                                                      std::uint8_t *output,
                                                      std::size_t capacity) noexcept {
    constexpr std::size_t max_length = 256, table_size = 512;
    if (length > max_length || (length > 0 && input == nullptr)) return -1;
    std::array<std::int32_t, table_size> keys{};
    std::array<std::size_t, table_size> counts{};
    std::array<std::uint8_t, table_size> used{};
    std::array<std::size_t, max_length> order{};
    std::size_t unique_count = 0;
    for (std::size_t i = 0; i < length; ++i) {
        if (input[i] < INT32_MIN || input[i] > INT32_MAX) return -1;
        auto remainder = input[i] % static_cast<std::int64_t>(table_size);
        if (remainder < 0) remainder += table_size;
        auto slot = static_cast<std::size_t>(remainder);
        while (used[slot] && keys[slot] != input[i]) slot = (slot + 1) & (table_size - 1);
        if (!used[slot]) { used[slot] = 1; keys[slot] = static_cast<std::int32_t>(input[i]); counts[slot] = 1; order[unique_count++] = slot; }
        else ++counts[slot];
    }
    std::array<std::int32_t, max_length> result{};
    std::size_t result_count = 0;
    const auto threshold = length / 2;
    for (std::size_t i = 0; i < unique_count; ++i) {
        const auto slot = order[i];
        if (counts[slot] >= threshold) result[result_count++] = keys[slot];
    }
    for (std::size_t i = 1; i < result_count; ++i) {
        const auto value = result[i]; auto j = i;
        while (j > 0 && result[j - 1] > value) { result[j] = result[j - 1]; --j; }
        result[j] = value;
    }
    const auto required = result_count * 4;
    if (capacity < required || (required > 0 && output == nullptr)) return -2;
    std::size_t out = 0;
    for (std::size_t i = 0; i < result_count; ++i) {
        const auto bits = static_cast<std::uint32_t>(result[i]);
        for (std::size_t byte = 0; byte < 4; ++byte) output[out++] = static_cast<std::uint8_t>(bits >> (8 * byte));
    }
    return static_cast<std::int64_t>(result_count);
}
