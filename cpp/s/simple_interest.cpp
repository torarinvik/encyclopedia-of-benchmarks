#include <cstdint>

extern "C" double simple_interest(double principal, double daily_rate, double days) noexcept
{
    if (principal != principal || daily_rate != daily_rate || days != days ||
        !(principal > 0.0) || principal > 1'000'000.0 ||
        !(daily_rate >= 0.0) || daily_rate > 1.0 ||
        !(days > 0.0) || days > 3'650.0) return -1e300;
    return principal * daily_rate * days;
}
