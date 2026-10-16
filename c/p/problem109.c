#include <stdint.h>

int64_t problem109(int64_t limit)
{
    int64_t values[63], doubles[21];
    int value_count = 0, double_count = 0;
    for (int64_t score = 1; score <= 20; ++score) values[value_count++] = score;
    values[value_count++] = 25;
    for (int64_t score = 1; score <= 20; ++score) { doubles[double_count++] = 2 * score; values[value_count++] = 2 * score; }
    doubles[double_count++] = 50; values[value_count++] = 50;
    for (int64_t score = 1; score <= 20; ++score) values[value_count++] = 3 * score;
    values[value_count++] = 0;
    int64_t count = 0;
    for (int d = 0; d < double_count; ++d)
        for (int first = 0; first < value_count; ++first)
            for (int second = first; second < value_count; ++second)
                count += doubles[d] + values[first] + values[second] < limit;
    return count;
}
