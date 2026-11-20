#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_INPUT_LENGTH = 18;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255u);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t continued_fraction_convergents(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const auto count_value = input[0];
    if (count_value < 1 || count_value > 16 || input[1] < -1000 || input[1] > 1000) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != count + 1) return -1;
    for (std::size_t i = 2; i < length; ++i)
        if (input[i] < 1 || input[i] > 8) return -1;
    const auto required = 16 * count;
    if (output == nullptr || capacity < required) return -2;

    std::int64_t p_two_back = 0, p_one_back = 1;
    std::int64_t q_two_back = 1, q_one_back = 0;
    for (std::size_t i = 0; i < count; ++i) {
        const auto p = input[i + 1] * p_one_back + p_two_back;
        const auto q = input[i + 1] * q_one_back + q_two_back;
        store_i64_le(output, 16 * i, p);
        store_i64_le(output, 16 * i + 8, q);
        p_two_back = p_one_back; p_one_back = p;
        q_two_back = q_one_back; q_one_back = q;
    }
    return static_cast<std::int64_t>(required);
}
