#include <math.h>
#include <stdint.h>

#define MAX_ABS_VALUE INT64_C(1000000)

int64_t finding_number_of_digits_in_a_number_using_log(int64_t value)
{
    if (value < -MAX_ABS_VALUE || value > MAX_ABS_VALUE) return -1;
    if (value == 0) return 0;
    const double magnitude = fabs((double)value);
    return (int64_t)floor(log10(magnitude) + 1.0);
}
