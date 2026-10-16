// Shunt capacitor or inductor sizing for power-factor correction.
#include <cmath>
#include <cstddef>
#include <cstdint>
extern "C" double power_factor_correction(const std::int64_t *v, std::size_t n) noexcept {
    if (!v || n != 6) return -1.0e300;
    const auto op=v[0], voltage=v[1], frequency=v[2], power=v[3], cb=v[4], eb=v[5];
    if ((op != 0 && op != 1) || voltage < 1 || voltage > 1000 || frequency < 1 || frequency > 1000 || power < -1000000 || power > 1000000 || cb < -10000 || cb > 10000 || eb < -10000 || eb > 10000 || cb == 0 || eb == 0 || (op == 1 && cb == eb)) return -1.0e300;
    const double c=static_cast<double>(cb)/10000.0, e=static_cast<double>(eb)/10000.0, p=static_cast<double>(power);
    const double dq=(p/c)*std::sin(std::acos(c))-(p/e)*std::sin(std::acos(e));
    constexpr double pi=3.14159265358979323846;
    if (op == 0) return dq/(2.0*pi*static_cast<double>(frequency)*static_cast<double>(voltage)*static_cast<double>(voltage));
    return static_cast<double>(voltage)*static_cast<double>(voltage)/(2.0*pi*static_cast<double>(frequency)*dq);
}
