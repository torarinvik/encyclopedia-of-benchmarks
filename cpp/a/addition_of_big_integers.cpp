#include <cstddef>
#include <cstdint>

namespace {
struct DecimalOperand {
    std::size_t digit_start;
    std::size_t digit_count;
    bool negative;
};

bool parse_operand(const std::int64_t *input, std::size_t start,
                   std::size_t text_length, DecimalOperand &operand) {
    if (text_length == 0 || text_length > 33) return false;
    const bool negative = input[start] == 45;
    const std::size_t digit_start = start + (negative ? 1 : 0);
    const std::size_t digit_count = text_length - (negative ? 1 : 0);
    if (digit_count == 0 || digit_count > 32) return false;
    for (std::size_t i = 0; i < digit_count; ++i) {
        const std::int64_t byte = input[digit_start + i];
        if (byte < 48 || byte > 57 || (i == 0 && digit_count > 1 && byte == 48))
            return false;
    }
    if (negative && digit_count == 1 && input[digit_start] == 48) return false;
    operand = {digit_start, digit_count, negative};
    return true;
}

int compare_magnitude(const std::int64_t *input, DecimalOperand a,
                      DecimalOperand b) {
    if (a.digit_count != b.digit_count)
        return a.digit_count > b.digit_count ? 1 : -1;
    for (std::size_t i = 0; i < a.digit_count; ++i) {
        const auto da = input[a.digit_start + i];
        const auto db = input[b.digit_start + i];
        if (da != db) return da > db ? 1 : -1;
    }
    return 0;
}
}  // namespace

extern "C" std::int64_t addition_of_big_integers(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) {
    if (input == nullptr || length < 4 || length > 68) return -1;
    const auto raw_a = input[0], raw_b = input[1];
    if (raw_a < 1 || raw_a > 33 || raw_b < 1 || raw_b > 33) return -1;
    const auto len_a = static_cast<std::size_t>(raw_a);
    const auto len_b = static_cast<std::size_t>(raw_b);
    if (length != 2 + len_a + len_b) return -1;
    DecimalOperand a{}, b{};
    if (!parse_operand(input, 2, len_a, a) ||
        !parse_operand(input, 2 + len_a, len_b, b)) return -1;

    std::uint8_t reversed[33]{};
    std::size_t digits = 0;
    bool negative = false;
    if (a.negative == b.negative) {
        negative = a.negative;
        const auto width = a.digit_count > b.digit_count ? a.digit_count : b.digit_count;
        int carry = 0;
        for (std::size_t offset = 0; offset < width; ++offset) {
            const int da = offset < a.digit_count
                ? static_cast<int>(input[a.digit_start + a.digit_count - 1 - offset] - 48) : 0;
            const int db = offset < b.digit_count
                ? static_cast<int>(input[b.digit_start + b.digit_count - 1 - offset] - 48) : 0;
            const int total = da + db + carry;
            reversed[digits++] = static_cast<std::uint8_t>(total % 10);
            carry = total / 10;
        }
        if (carry != 0) reversed[digits++] = static_cast<std::uint8_t>(carry);
    } else {
        const int order = compare_magnitude(input, a, b);
        if (order == 0) {
            reversed[0] = 0;
            digits = 1;
        } else {
            const auto larger = order > 0 ? a : b;
            const auto smaller = order > 0 ? b : a;
            negative = larger.negative;
            int borrow = 0;
            for (std::size_t offset = 0; offset < larger.digit_count; ++offset) {
                const int da = static_cast<int>(input[larger.digit_start + larger.digit_count - 1 - offset] - 48);
                const int db = offset < smaller.digit_count
                    ? static_cast<int>(input[smaller.digit_start + smaller.digit_count - 1 - offset] - 48) : 0;
                const int digit = da - db - borrow;
                borrow = digit < 0;
                reversed[digits++] = static_cast<std::uint8_t>(digit < 0 ? digit + 10 : digit);
            }
            while (digits > 1 && reversed[digits - 1] == 0) --digits;
        }
    }

    const auto output_length = digits + (negative ? 1 : 0);
    if (output == nullptr || capacity < output_length) return -2;
    std::size_t cursor = 0;
    if (negative) output[cursor++] = 45;
    for (std::size_t i = 0; i < digits; ++i)
        output[cursor++] = static_cast<std::uint8_t>(48 + reversed[digits - 1 - i]);
    return static_cast<std::int64_t>(output_length);
}
