/* Bottom-up minimum-square-count dynamic programming, bounded to 4096. */
#include <cstdint>
#include <limits>

extern "C" std::int64_t minimum_squares_to_represent_a_number(std::int64_t input) noexcept
{
    if (input < 0 || input > 4096) return -1;
    if (input == 0) return 1;

    std::int64_t answers[4097];
    for (std::int64_t index = 0; index <= input; ++index) answers[index] = -1;
    answers[0] = 0;
    for (std::int64_t value = 1; value <= input; ++value) {
        std::int64_t best = std::numeric_limits<std::int64_t>::max();
        for (std::int64_t root = 1; root <= value / root; ++root) {
            const std::int64_t candidate = 1 + answers[value - root * root];
            if (candidate < best) best = candidate;
        }
        answers[value] = best;
    }
    return answers[input];
}
