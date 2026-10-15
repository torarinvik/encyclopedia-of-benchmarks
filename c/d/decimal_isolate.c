#include <stdint.h>

double decimal_isolate(double input)
{
    if (!(input > 0.0 && input <= 999999.0)) return -1.0;
    const double scaled_value = input * 10000.0;
    const int64_t scaled = (int64_t)scaled_value;
    if ((double)scaled != scaled_value || (double)scaled / 10000.0 != input ||
        scaled % 625 != 0 || scaled % 10000 == 0) return -1.0;
    return (double)(scaled % 10000) / 10000.0;
}
