/* Convert between SI and binary prefixes using the pinned Python exponents. */
#include <math.h>

static int si_exponent(double code)
{
    if (code == 0.0) return 24;
    if (code == 1.0) return 21;
    if (code == 2.0) return 18;
    if (code == 3.0) return 15;
    if (code == 4.0) return 12;
    if (code == 5.0) return 9;
    if (code == 6.0) return 6;
    if (code == 7.0) return 3;
    if (code == 8.0) return 2;
    if (code == 9.0) return 1;
    if (code == 10.0) return -1;
    if (code == 11.0) return -2;
    if (code == 12.0) return -3;
    if (code == 13.0) return -6;
    if (code == 14.0) return -9;
    if (code == 15.0) return -12;
    if (code == 16.0) return -15;
    if (code == 17.0) return -18;
    if (code == 18.0) return -21;
    if (code == 19.0) return -24;
    return 1000;
}

static int binary_exponent(double code)
{
    if (code == 20.0) return 8;
    if (code == 21.0) return 7;
    if (code == 22.0) return 6;
    if (code == 23.0) return 5;
    if (code == 24.0) return 4;
    if (code == 25.0) return 3;
    if (code == 26.0) return 2;
    if (code == 27.0) return 1;
    return 1000;
}

double prefix_conversions(double known_amount, double known_code, double unknown_code)
{
    if (!isfinite(known_amount) || known_amount < -1000000.0 || known_amount > 1000000.0) return -1e300;
    const int known_si = si_exponent(known_code);
    const int unknown_si = si_exponent(unknown_code);
    if (known_si != 1000 && unknown_si != 1000)
        return known_amount * pow(10.0, (double)(known_si - unknown_si));
    const int known_binary = binary_exponent(known_code);
    const int unknown_binary = binary_exponent(unknown_code);
    if (known_binary != 1000 && unknown_binary != 1000)
        return known_amount * pow(2.0, (double)((known_binary - unknown_binary) * 10));
    return -1e300;
}
