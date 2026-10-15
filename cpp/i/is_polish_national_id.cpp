#include <cstddef>
#include <cstdint>

extern "C" std::int64_t is_polish_national_id(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length != 11) return -1;
    std::int64_t number = 0;
    for (std::size_t index = 0; index < length; ++index) {
        if (input[index] < '0' || input[index] > '9') return -1;
        number = number * 10 + input[index] - '0';
    }
    if (number < INT64_C(10100000) || number > INT64_C(99923199999)) return 0;
    const auto month = (input[2] - '0') * 10 + input[3] - '0';
    const bool valid_month = (month >= 1 && month <= 12) || (month >= 21 && month <= 32) ||
                             (month >= 41 && month <= 52) || (month >= 61 && month <= 72) ||
                             (month >= 81 && month <= 92);
    if (!valid_month) return 0;
    const auto day = (input[4] - '0') * 10 + input[5] - '0';
    if (day < 1 || day > 31) return 0;
    constexpr std::int64_t weights[4] = {1, 3, 7, 9};
    std::int64_t subtotal = 0;
    for (std::size_t index = 0; index < 10; ++index) {
        subtotal += ((input[index] - '0') * weights[index % 4]) % 10;
    }
    const auto checksum = 10 - subtotal % 10;
    return checksum == number % 10 ? 1 : 0;
}
