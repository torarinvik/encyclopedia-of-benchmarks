#include <cstddef>
#include <cstdint>

namespace {
std::int64_t kaprekar_step(std::int64_t number) {
    std::int64_t d0 = number / 1000;
    std::int64_t d1 = (number / 100) % 10;
    std::int64_t d2 = (number / 10) % 10;
    std::int64_t d3 = number % 10;
    std::int64_t temp;

    if (d0 > d1) { temp = d0; d0 = d1; d1 = temp; }
    if (d2 > d3) { temp = d2; d2 = d3; d3 = temp; }
    if (d0 > d2) { temp = d0; d0 = d2; d2 = temp; }
    if (d1 > d3) { temp = d1; d1 = d3; d3 = temp; }
    if (d1 > d2) { temp = d1; d1 = d2; d2 = temp; }

    const std::int64_t ascending = d0 * 1000 + d1 * 100 + d2 * 10 + d3;
    const std::int64_t descending = d3 * 1000 + d2 * 100 + d1 * 10 + d0;
    return descending - ascending;
}
}

extern "C" std::int64_t kaprekar_constant(const std::int64_t* values, std::size_t length) {
    if (values == nullptr || length != 2) return -1;
    const std::int64_t number = values[0];
    const std::int64_t max_iterations = values[1];
    if (number < 0 || number > 9999 || max_iterations < 1 || max_iterations > 16) return -1;
    if (number == 6174) return 0;

    std::int64_t current = number;
    for (std::int64_t iteration = 1; iteration <= max_iterations; ++iteration) {
        current = kaprekar_step(current);
        if (current == 6174) return iteration;
        if (current == 0) return -1;
    }
    return -1;
}
