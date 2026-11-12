#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kModulus = 998244353;
constexpr int kMaxOrder = 8;
constexpr int kMaxTerms = 2 * kMaxOrder;
constexpr std::size_t kMaxInputValues = 1 + kMaxTerms + 1;

std::int64_t normalize(std::int64_t value) {
    value %= kModulus;
    return value < 0 ? value + kModulus : value;
}

std::int64_t multiply(std::int64_t left, std::int64_t right) {
    return (left * right) % kModulus;
}

std::int64_t power(std::int64_t base, std::int64_t exponent) {
    std::int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = multiply(result, base);
        base = multiply(base, base);
        exponent >>= 1;
    }
    return result;
}

void store_i64_le(std::uint8_t *output, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

int infer_recurrence(const std::array<std::int64_t, kMaxTerms> &sequence,
                     int term_count,
                     std::array<std::int64_t, kMaxTerms + 1> &coefficients) {
    std::array<std::int64_t, kMaxTerms + 1> current{};
    std::array<std::int64_t, kMaxTerms + 1> previous{};
    std::array<std::int64_t, kMaxTerms + 1> old{};
    int current_length = 0;
    int previous_length = 0;
    int last_index = -1;
    std::int64_t last_discrepancy = 0;

    for (int index = 0; index < term_count; ++index) {
        std::int64_t predicted = 0;
        for (int lag = 0; lag < current_length && lag < index; ++lag)
            predicted = normalize(predicted + multiply(sequence[index - lag - 1], current[lag]));
        const auto discrepancy = normalize(sequence[index] - predicted);
        if (discrepancy == 0) continue;

        if (last_index < 0) {
            last_index = index;
            last_discrepancy = discrepancy;
            current_length = index + 1;
            for (int lag = 0; lag < current_length; ++lag) current[lag] = 0;
            continue;
        }

        for (int lag = 0; lag < current_length; ++lag) old[lag] = current[lag];
        const int old_length = current_length;
        const auto scale = multiply(discrepancy,
                                    power(last_discrepancy, kModulus - 2));
        const int shift = index - last_index;
        const int needed_length = previous_length + shift;
        if (current_length < needed_length) {
            for (int lag = current_length; lag < needed_length; ++lag) current[lag] = 0;
            current_length = needed_length;
        }
        current[shift - 1] = normalize(current[shift - 1] + scale);
        for (int lag = 0; lag < previous_length; ++lag)
            current[shift + lag] = normalize(
                current[shift + lag] - multiply(scale, previous[lag]));

        if (old_length - index < previous_length - last_index) {
            for (int lag = 0; lag < old_length; ++lag) previous[lag] = old[lag];
            previous_length = old_length;
            last_index = index;
            last_discrepancy = discrepancy;
        }
    }

    for (int lag = 0; lag < current_length; ++lag) coefficients[lag] = current[lag];
    return current_length;
}
}

extern "C" std::int64_t berlekamp_massey(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > kMaxInputValues) return -1;
    const auto bound_value = input[0];
    if (bound_value < 1 || bound_value > kMaxOrder) return -1;
    const int bound = static_cast<int>(bound_value);
    const int term_count = 2 * bound;
    if (length != static_cast<std::size_t>(1 + term_count)) return -1;

    std::array<std::int64_t, kMaxTerms> sequence{};
    for (int index = 0; index < term_count; ++index) {
        const auto value = input[1 + index];
        if (value < 0 || value >= kModulus) return -1;
        sequence[index] = value;
    }

    std::array<std::int64_t, kMaxTerms + 1> coefficients{};
    const int order = infer_recurrence(sequence, term_count, coefficients);
    if (order > bound) return -1;
    const auto output_bytes = 8 * static_cast<std::size_t>(order + 1);
    if (output == nullptr || capacity < output_bytes) return -2;
    store_i64_le(output, order);
    for (int lag = 0; lag < order; ++lag)
        store_i64_le(output + 8 * static_cast<std::size_t>(lag + 1), coefficients[lag]);
    return static_cast<std::int64_t>(output_bytes);
}
