#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t next_palindromic_number(const std::int64_t *values,
                                                  std::size_t length) noexcept {
    constexpr std::int64_t maximum_input = INT64_C(9999999999999999);
    if (values == nullptr || length != 1) return -1;
    const std::int64_t number = values[0];
    if (number < 0 || number > maximum_input) return -1;

    std::array<std::uint8_t, 17> digits{};
    std::int64_t remaining = number;
    std::size_t count = 0;
    do {
        digits[count++] = static_cast<std::uint8_t>(remaining % 10);
        remaining /= 10;
    } while (remaining > 0);
    for (std::size_t left = 0; left < count / 2; ++left) {
        const std::size_t right = count - 1 - left;
        const auto swap = digits[left];
        digits[left] = digits[right];
        digits[right] = swap;
    }

    for (std::size_t left = 0; left < count / 2; ++left)
        digits[count - 1 - left] = digits[left];
    std::int64_t candidate = 0;
    for (std::size_t i = 0; i < count; ++i) candidate = candidate * 10 + digits[i];
    if (candidate > number) return candidate;

    const std::size_t prefix_length = (count + 1) / 2;
    std::size_t position = prefix_length;
    while (position > 0 && digits[position - 1] == 9) {
        digits[position - 1] = 0;
        --position;
    }
    if (position == 0) {
        std::int64_t power = 1;
        for (std::size_t i = 0; i < count; ++i) power *= 10;
        return power + 1;
    }
    ++digits[position - 1];
    for (std::size_t left = 0; left < count / 2; ++left)
        digits[count - 1 - left] = digits[left];
    candidate = 0;
    for (std::size_t i = 0; i < count; ++i) candidate = candidate * 10 + digits[i];
    return candidate;
}
