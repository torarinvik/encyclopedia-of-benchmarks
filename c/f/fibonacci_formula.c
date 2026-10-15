/* Source-ordered Binet formula, rounded to float then truncated to int. */
#include <math.h>
#include <stdint.h>

int64_t fibonacci_formula(int64_t input)
{
    if (input < 0 || input > 35) return -1;
    unsigned int n = (unsigned int)input;
    float seq = (1 / sqrt(5) * pow(((1 + sqrt(5)) / 2), n + 1))
              - (1 / sqrt(5) * pow(((1 - sqrt(5)) / 2), n + 1));
    return (int32_t)seq;
}
