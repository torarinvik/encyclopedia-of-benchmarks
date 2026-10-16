#include <math.h>
#include <stdint.h>

enum { MAX_N = 15 };

int64_t problem190(int64_t n)
{
    if (n < 0 || n > MAX_N) return -1;
    int64_t total = 0;
    for (int64_t m = 2; m <= n; ++m) {
        double x1 = 2.0 / (double)(m + 1);
        double product = 1.0;
        for (int64_t i = 1; i <= m; ++i) {
            double xi = (double)i * x1;
            product *= pow(xi, (double)i);
        }
        total += (int64_t)product;
    }
    return total;
}
