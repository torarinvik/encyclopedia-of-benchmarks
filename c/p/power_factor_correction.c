/* Shunt capacitor or inductor sizing for power-factor correction. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>
#define INVALID_RESULT (-1.0e300)
static double reactive_difference(double power, double current, double expected) {
    const double old_q = (power / current) * sin(acos(current));
    const double new_q = (power / expected) * sin(acos(expected));
    return old_q - new_q;
}
double power_factor_correction(const int64_t *v, size_t n) {
    if (!v || n != 6) return INVALID_RESULT;
    const int64_t op=v[0], voltage=v[1], frequency=v[2], power=v[3], cb=v[4], eb=v[5];
    if ((op != 0 && op != 1) || voltage < 1 || voltage > 1000 || frequency < 1 || frequency > 1000 || power < -1000000 || power > 1000000 || cb < -10000 || cb > 10000 || eb < -10000 || eb > 10000 || cb == 0 || eb == 0 || (op == 1 && cb == eb)) return INVALID_RESULT;
    const double current=(double)cb/10000.0, expected=(double)eb/10000.0, p=(double)power, f=(double)frequency, voltage_d=(double)voltage;
    const double dq=reactive_difference(p,current,expected);
    if (op == 0) return dq/(2.0*3.14159265358979323846*f*(voltage_d*voltage_d));
    return (voltage_d*voltage_d)/(2.0*3.14159265358979323846*f*dq);
}
