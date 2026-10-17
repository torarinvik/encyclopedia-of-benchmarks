#include <cstddef>
#include <cstdint>

extern "C" std::int64_t euler_problem_6(const std::int64_t *input, std::size_t length)
{
    if (input == nullptr || length < 1 || length > 2 || length != 1 || input[0] < 1 || input[0] > 100) return -1;
    std::int64_t sum = 0;
    std::int64_t sum_of_squares = 0;
    for (std::int64_t value = 1; value <= input[0]; ++value) {
        sum += value;
        sum_of_squares += value * value;
    }
    return sum * sum - sum_of_squares;
}
