// XOR a consecutive signed 32-bit range using portable zero-extended bit patterns.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_values = 1024;
constexpr std::int64_t invalid_result = -2'147'483'649;
std::uint64_t encode_i32(std::int64_t value) noexcept {
    return static_cast<std::uint64_t>(value < 0 ? value + 4'294'967'296 : value);
}
}

extern "C" std::int64_t missing_number_in_range(const std::int64_t *values,
                                                 std::size_t length) noexcept {
    if (values == nullptr || length < 2 || length > max_values) return invalid_result;
    auto low = values[0];
    auto high = values[0];
    for (std::size_t i = 0; i < length; ++i) {
        if (values[i] < INT32_MIN || values[i] > INT32_MAX) return invalid_result;
        if (values[i] < low) low = values[i];
        if (values[i] > high) high = values[i];
    }
    if (high - low != static_cast<std::int64_t>(length)) return invalid_result;
    bool seen[max_values + 1]{};
    std::uint64_t actual = 0;
    for (std::size_t i = 0; i < length; ++i) {
        const auto slot = static_cast<std::size_t>(values[i] - low);
        if (seen[slot]) return invalid_result;
        seen[slot] = true;
        actual ^= encode_i32(values[i]);
    }
    std::uint64_t expected = 0;
    for (auto value = low; value <= high; ++value) expected ^= encode_i32(value);
    const auto result = expected ^ actual;
    return result <= INT32_MAX ? static_cast<std::int64_t>(result)
                               : static_cast<std::int64_t>(result) - 4'294'967'296;
}
