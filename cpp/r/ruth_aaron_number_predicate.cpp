#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_n = 100000;
constexpr std::size_t max_parseable_length = 2;

std::int64_t factor_sum_with_repetitions(std::int64_t value) {
    std::int64_t sum = 0;
    for (std::int64_t candidate = 2; candidate <= value / candidate; ++candidate) {
        while (value % candidate == 0) {
            sum += candidate;
            value /= candidate;
        }
    }
    if (value > 1) sum += value;
    return sum;
}
}

extern "C" std::int64_t ruth_aaron_number_predicate(const std::int64_t *input,
                                                    std::size_t length) {
    if (input == nullptr || length < 1 || length > max_parseable_length) return -1;
    if (length != 1 || input[0] < 1 || input[0] > max_n) return -1;
    const std::int64_t value = input[0];
    return factor_sum_with_repetitions(value) == factor_sum_with_repetitions(value + 1) ? 1 : 0;
}
