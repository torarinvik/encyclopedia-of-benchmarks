/* Equivalent capacitance for series and parallel connections. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

double capacitor_equivalence(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > 33) return INVALID_RESULT;
    const int64_t operation = values[0];
    if (operation != 0 && operation != 1) return INVALID_RESULT;
    double accumulated = 0.0;
    for (size_t index = 1; index < length; ++index) {
        const int64_t capacitor = values[index];
        if (capacitor < (operation == 0 ? 0 : 1) || capacitor > 1000) return INVALID_RESULT;
        if (operation == 0) accumulated += (double)capacitor;
        else accumulated += 1.0 / (double)capacitor;
    }
    return operation == 0 ? accumulated : 1.0 / accumulated;
}
