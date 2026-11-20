#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double kInvalid = -1.0e300;
}

extern "C" double hickerson_almost_integer(const std::int64_t* values,
    std::size_t length) noexcept {
    if (values == nullptr || length != 1 || values[0] < 1 || values[0] > 17)
        return kInvalid;
    const double log_two = std::log(2.0);
    double value = 1.0 / (2.0 * log_two * log_two);
    for (std::int64_t n = 2; n <= values[0]; ++n)
        value = (static_cast<double>(n) / log_two) * value;
    return value;
}
