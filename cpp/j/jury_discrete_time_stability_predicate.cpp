#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kMaximumDegree = 4;
constexpr std::size_t kMaximumParseableLength = 7;
}

extern "C" std::int64_t jury_discrete_time_stability_predicate(
    const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 1U || length > kMaximumParseableLength) return -1;
    const auto degree = input[0];
    if (degree < 1 || degree > kMaximumDegree || length != static_cast<std::size_t>(degree) + 2U) return -1;

    std::int64_t coefficients[5] = {};
    for (std::int64_t index = 0; index <= degree; ++index) {
        const auto value = input[static_cast<std::size_t>(index) + 1U];
        if (value < -9 || value > 9 || (index == 0 && value == 0)) return -1;
        coefficients[index] = value;
    }
    if (coefficients[0] < 0) {
        for (std::int64_t index = 0; index <= degree; ++index) coefficients[index] = -coefficients[index];
    }

    std::int64_t at_one = 0;
    std::int64_t at_minus_one = 0;
    for (std::int64_t index = 0; index <= degree; ++index) {
        at_one += coefficients[index];
        at_minus_one += ((degree - index) % 2 == 0) ? coefficients[index] : -coefficients[index];
    }
    if (at_one <= 0 || ((degree % 2 == 0) ? at_minus_one <= 0 : at_minus_one >= 0)) return 0;

    std::int64_t row[5] = {};
    std::int64_t reduced[5] = {};
    for (std::int64_t index = 0; index <= degree; ++index) row[index] = coefficients[index];
    for (std::int64_t current_degree = degree; current_degree >= 1; --current_degree) {
        const auto trailing = row[current_degree];
        const auto trailing_magnitude = trailing < 0 ? -trailing : trailing;
        if (row[0] <= trailing_magnitude) return 0;
        if (current_degree == 1) break;
        for (std::int64_t index = 0; index < current_degree; ++index) {
            reduced[index] = row[0] * row[index] - trailing * row[current_degree - index];
        }
        for (std::int64_t index = 0; index < current_degree; ++index) row[index] = reduced[index];
    }
    return 1;
}
