#include <stddef.h>
#include <stdint.h>

int64_t euler_problem_6(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > 2 || length != 1 || input[0] < 1 || input[0] > 100) return -1;
    int64_t sum = 0, sum_of_squares = 0;
    for (int64_t value = 1; value <= input[0]; ++value) {
        sum += value;
        sum_of_squares += value * value;
    }
    return sum * sum - sum_of_squares;
}
