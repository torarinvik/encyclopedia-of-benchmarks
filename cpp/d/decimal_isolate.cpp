#include <cstdint>

extern "C" double decimal_isolate(double input) noexcept
{
    if (!(input > 0.0 && input <= 999999.0)) return -1.0;
    const double scaled_value = input * 10000.0;
    const auto scaled = static_cast<std::int64_t>(scaled_value);
    if (static_cast<double>(scaled) != scaled_value ||
        static_cast<double>(scaled) / 10000.0 != input ||
        scaled % 625 != 0 || scaled % 10000 == 0) return -1.0;
    return static_cast<double>(scaled % 10000) / 10000.0;
}
