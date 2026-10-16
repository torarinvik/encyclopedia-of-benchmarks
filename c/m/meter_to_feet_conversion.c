/* Two source-ordered feet/meters conversions over scaled integer inputs. */
#include <stddef.h>
#include <stdint.h>
#define INVALID_RESULT (-1.0e300)
double meter_to_feet_conversion(const int64_t *v, size_t n) {
    if (!v || n != 2) return INVALID_RESULT;
    const int64_t op=v[0], units=v[1];
    if ((op != 0 && op != 1) || units < -1000000000LL || units > 1000000000LL) return INVALID_RESULT;
    const double value=(double)units/1000.0;
    if (op == 0) return value*0.3048;
    return value/0.3048;
}
