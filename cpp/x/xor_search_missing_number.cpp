#include <cstddef>
#include <cstdint>

extern "C" std::int64_t xor_search_missing_number(const std::int64_t *input, std::size_t length) noexcept {
    constexpr std::int64_t max_n = 255;
    constexpr std::size_t max_input_length = 257;
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    const std::int64_t n_value = input[0];
    if (n_value < 0 || n_value > max_n || length != static_cast<std::size_t>(n_value + 1)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    bool seen[256]{};
    std::int64_t result = n_value;
    for (std::size_t i = 0; i < n; ++i) {
        const std::int64_t value = input[i + 1];
        if (value < 0 || value > n_value || seen[static_cast<std::size_t>(value)]) return -1;
        seen[static_cast<std::size_t>(value)] = true;
        result ^= static_cast<std::int64_t>(i) ^ value;
    }
    return result;
}
