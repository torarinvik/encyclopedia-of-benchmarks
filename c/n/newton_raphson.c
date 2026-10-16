#include <stddef.h>
#include <stdint.h>
#define INVALID_RESULT (-1.0e300)
double newton_raphson(const int64_t *values, size_t length) {
    if (values == NULL || length != 2) return INVALID_RESULT;
    int64_t radicand=values[0], quarters=values[1];
    if (radicand<2 || radicand>4 || quarters<4 || quarters>8) return INVALID_RESULT;
    double x=(double)quarters/4.0;
    for (int i=0;i<8;i++) x=0.5*(x+(double)radicand/x);
    return x;
}
