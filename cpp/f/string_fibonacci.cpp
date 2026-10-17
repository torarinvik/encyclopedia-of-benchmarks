/* Decimal-string Fibonacci using the pinned manual-add recurrence. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 256;
constexpr std::size_t DECIMAL_CAPACITY = 80;

std::size_t add_decimal(const char *left, std::size_t left_length,
                        const char *right, std::size_t right_length,
                        char *result) noexcept
{
    char reversed[DECIMAL_CAPACITY];
    std::size_t length = 0;
    int carry = 0;
    while (left_length > 0 || right_length > 0 || carry != 0) {
        const int left_digit = left_length > 0 ? left[--left_length] - '0' : 0;
        const int right_digit = right_length > 0 ? right[--right_length] - '0' : 0;
        const int sum = left_digit + right_digit + carry;
        reversed[length++] = static_cast<char>('0' + sum % 10);
        carry = sum / 10;
    }
    for (std::size_t i = 0; i < length; ++i) result[i] = reversed[length - 1 - i];
    result[length] = '\0';
    return length;
}
}

extern "C" std::int64_t string_fibonacci(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept
{
    if (input == nullptr || length != 1) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(MAX_N)) return -1;

    char fib_minus_one[DECIMAL_CAPACITY] = "1";
    char fib_minus_two[DECIMAL_CAPACITY] = "0";
    std::size_t minus_one_length = 1;
    std::size_t minus_two_length = 1;
    for (std::size_t i = 0; i < static_cast<std::size_t>(input[0]); ++i) {
        char sum[DECIMAL_CAPACITY];
        const std::size_t sum_length = add_decimal(fib_minus_one, minus_one_length,
                                                   fib_minus_two, minus_two_length, sum);
        for (std::size_t j = 0; j < minus_one_length; ++j) fib_minus_two[j] = fib_minus_one[j];
        minus_two_length = minus_one_length;
        for (std::size_t j = 0; j < sum_length; ++j) fib_minus_one[j] = sum[j];
        fib_minus_one[sum_length] = '\0';
        minus_one_length = sum_length;
    }

    if (output == nullptr || capacity < minus_two_length) return -2;
    for (std::size_t i = 0; i < minus_two_length; ++i) output[i] = static_cast<std::uint8_t>(fib_minus_two[i]);
    return static_cast<std::int64_t>(minus_two_length);
}
