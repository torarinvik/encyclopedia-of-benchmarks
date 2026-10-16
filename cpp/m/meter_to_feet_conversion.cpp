#include <cstddef>
#include <cstdint>
extern "C" double meter_to_feet_conversion(const std::int64_t* v, std::size_t n) noexcept {
    if (!v || n != 2) return -1.0e300;
    const auto op=v[0], units=v[1];
    if ((op != 0 && op != 1) || units < -1000000000LL || units > 1000000000LL) return -1.0e300;
    const double value=static_cast<double>(units)/1000.0;
    if (op == 0) return value*0.3048;
    return value/0.3048;
}
