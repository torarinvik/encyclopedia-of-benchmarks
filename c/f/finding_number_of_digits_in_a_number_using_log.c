#include <math.h>

#define MAX_ABS_VALUE 1000000.0
#define INVALID_RESULT (-1.0e300)

double finding_number_of_digits_in_a_number_using_log(double value)
{
    if (!(value >= -MAX_ABS_VALUE && value <= MAX_ABS_VALUE)) return INVALID_RESULT;
    if (value == 0.0) return 0.0;
    return floor(log10(fabs(value)) + 1.0);
}
