#include <math.h>

static int is_prime(long long value)
{
    if (value < 2) return 0;
    if (value < 4) return 1;
    if (value % 2 == 0 || value % 3 == 0) return 0;
    for (long long divisor = 5; divisor <= value / divisor; divisor += 6) {
        if (value % divisor == 0 || value % (divisor + 2) == 0) return 0;
    }
    return 1;
}

double problem58(double ratio)
{
    if (!(ratio >= 0.1 && ratio <= 0.6)) return -1.0;
    long long side = 3;
    long long prime_count = 3;
    while ((double)prime_count / (double)(2 * side - 1) >= ratio) {
        const long long square = side * side;
        const long long step = side + 1;
        if (is_prime(square + step)) ++prime_count;
        if (is_prime(square + 2 * step)) ++prime_count;
        if (is_prime(square + 3 * step)) ++prime_count;
        side += 2;
    }
    return (double)side;
}
