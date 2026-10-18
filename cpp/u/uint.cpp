#include <cstddef>
#include <cstdint>
#include <vector>

namespace {
constexpr std::size_t max_digits = 64;
constexpr std::size_t max_output_digits = 1664;
constexpr std::int64_t invalid_result = -1;
constexpr std::int64_t output_error = -2;
using Big = std::vector<std::uint32_t>;

void trim(Big &value) {
    while (!value.empty() && value.back() == 0) value.pop_back();
}

Big from_small(std::uint32_t value, std::uint32_t base) {
    Big result;
    while (value != 0) {
        result.push_back(value % base);
        value /= base;
    }
    return result;
}

void add(Big &left, const Big &right, std::uint32_t base) {
    std::size_t index = 0;
    std::uint64_t carry = 0;
    while (index < right.size() || carry != 0) {
        const std::uint64_t sum = carry + (index < left.size() ? left[index] : 0) +
                                  (index < right.size() ? right[index] : 0);
        if (index == left.size()) left.push_back(0);
        left[index] = static_cast<std::uint32_t>(sum % base);
        carry = sum / base;
        ++index;
    }
    if (left.size() < right.size()) left.resize(right.size(), 0);
}

Big multiply(const Big &left, const Big &right, std::uint32_t base) {
    if (left.empty() || right.empty()) return {};
    Big result(left.size() + right.size(), 0);
    for (std::size_t i = 0; i < left.size(); ++i) {
        std::uint64_t carry = 0;
        for (std::size_t j = 0; j < right.size(); ++j) {
            const std::size_t at = i + j;
            const std::uint64_t product = static_cast<std::uint64_t>(left[i]) * right[j] + result[at] + carry;
            result[at] = static_cast<std::uint32_t>(product % base);
            carry = product / base;
        }
        std::size_t at = i + right.size();
        while (carry != 0) {
            const std::uint64_t sum = result[at] + carry;
            result[at] = static_cast<std::uint32_t>(sum % base);
            carry = sum / base;
            ++at;
            if (at > result.size()) result.resize(at, 0);
        }
    }
    trim(result);
    return result;
}

Big power(Big factor, std::size_t exponent, std::uint32_t base) {
    Big result = from_small(1, base);
    while (exponent > 0) {
        if ((exponent & 1u) != 0) result = multiply(result, factor, base);
        exponent >>= 1;
        if (exponent > 0) factor = multiply(factor, factor, base);
    }
    return result;
}

Big convert_base(const std::uint32_t *digits, std::size_t length,
                 std::uint32_t source_base, std::uint32_t target_base) {
    if (length == 0) return {};
    if (source_base == target_base) return Big(digits, digits + length);
    if (length == 1) return from_small(digits[0], target_base);
    const std::size_t middle = length / 2;
    Big low = convert_base(digits, middle, source_base, target_base);
    Big high = convert_base(digits + middle, length - middle, source_base, target_base);
    const Big scale = power(from_small(source_base, target_base), middle, target_base);
    add(low, multiply(high, scale, target_base), target_base);
    return low;
}
}  // namespace

extern "C" std::int64_t uint_convert_base(const std::int64_t *input, std::size_t length,
                                          std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length < 3 || length > max_digits + 4) return invalid_result;
    const std::int64_t source_value = input[0], target_value = input[1], count_value = input[2];
    if (source_value < 2 || source_value > (INT64_C(1) << 26) ||
        target_value < 2 || target_value > (INT64_C(1) << 26) ||
        count_value < 0 || count_value > static_cast<std::int64_t>(max_digits) ||
        length != static_cast<std::size_t>(count_value) + 3) return invalid_result;
    const auto source_base = static_cast<std::uint32_t>(source_value);
    const auto target_base = static_cast<std::uint32_t>(target_value);
    const auto count = static_cast<std::size_t>(count_value);
    std::uint32_t source_digits[max_digits];
    for (std::size_t i = 0; i < count; ++i) {
        if (input[i + 3] < 0 || input[i + 3] >= source_value) return invalid_result;
        source_digits[i] = static_cast<std::uint32_t>(input[i + 3]);
    }
    if (count > 0 && source_digits[count - 1] == 0) return invalid_result;
    const Big result = convert_base(source_digits, count, source_base, target_base);
    if (result.size() > max_output_digits) return invalid_result;
    const std::size_t bytes = result.size() * 4;
    if (output == nullptr || output_capacity < bytes) return output_error;
    for (std::size_t i = 0; i < result.size(); ++i)
        for (std::size_t byte = 0; byte < 4; ++byte)
            output[i * 4 + byte] = static_cast<std::uint8_t>(result[i] >> (byte * 8));
    return static_cast<std::int64_t>(bytes);
}
