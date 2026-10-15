/* Floor for bounded finite binary64 inputs, correcting truncation below zero. */
#include <stdint.h>

double floor(double value)
{
    if (value < -1000000.0 || value > 1000000.0) {
        return -1.0;
    }
    int64_t result = (int64_t)value;
    if (value < (double)result) {
        --result;
    }
    return (double)result;
}
