#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_dimension = 8;
constexpr std::size_t max_input_length = 65;
constexpr std::int64_t invalid_result = INT64_MIN;

unsigned bit_count(unsigned value) {
    unsigned count = 0;
    while (value != 0) {
        count += value & 1U;
        value >>= 1U;
    }
    return count;
}
}

extern "C" std::int64_t ryser_permanent(const std::int64_t* input,
                                         std::size_t length) {
    if (input == nullptr || length < 1 || length > max_input_length) return invalid_result;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_dimension)) return invalid_result;
    const unsigned n = static_cast<unsigned>(input[0]);
    if (length != 1 + n * n) return invalid_result;

    for (unsigned index = 0; index < n * n; ++index) {
        if (input[1 + index] < -4 || input[1 + index] > 4) return invalid_result;
    }

    std::int64_t row_sums[max_dimension]{};
    std::int64_t total = 0;
    unsigned previous_gray = 0;
    const unsigned subset_count = 1U << n;
    for (unsigned ordinal = 0; ordinal < subset_count; ++ordinal) {
        const unsigned gray = ordinal ^ (ordinal >> 1U);
        if (ordinal != 0) {
            const unsigned changed = gray ^ previous_gray;
            unsigned column = 0;
            while (((changed >> column) & 1U) == 0U) ++column;
            const std::int64_t direction = (gray & changed) != 0 ? 1 : -1;
            for (unsigned row = 0; row < n; ++row) {
                row_sums[row] += direction * input[1 + row * n + column];
            }
        }

        std::int64_t product = 1;
        for (unsigned row = 0; row < n; ++row) product *= row_sums[row];
        if (((n + bit_count(gray)) & 1U) != 0U) product = -product;
        total += product;
        previous_gray = gray;
    }
    return total;
}
