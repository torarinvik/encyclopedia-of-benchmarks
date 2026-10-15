#include <cstddef>
#include <cstdint>

namespace {
constexpr char check_letters[] = "TRWAGMYFPDXBNJZSQVHLCKE";
}

extern "C" std::int64_t is_spain_national_id(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || (length != 9 && length != 10)) return -1;
    for (std::size_t index = 0; index < length; ++index) {
        if (input[index] < 0 || input[index] > 127) return -1;
    }
    if (length == 10 && input[8] != '-') return -1;
    std::int64_t number = 0;
    for (std::size_t index = 0; index < 8; ++index) {
        if (input[index] < '0' || input[index] > '9') return -1;
        number = number * 10 + input[index] - '0';
    }
    auto letter = input[length - 1];
    if (letter >= 'a' && letter <= 'z') letter -= 'a' - 'A';
    if (letter < 'A' || letter > 'Z') return -1;
    return letter == check_letters[number % 23] ? 1 : 0;
}
