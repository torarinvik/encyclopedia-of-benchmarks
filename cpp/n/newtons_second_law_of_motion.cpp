// Newton's second law: net force equals mass times acceleration.
#include <cstddef>
#include <cstdint>

extern "C" double newtons_second_law_of_motion(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 2) return -1.0e300;
    const std::int64_t mass = values[0];
    const std::int64_t acceleration = values[1];
    if (mass < -1000 || mass > 1000 || acceleration < -1000 || acceleration > 1000)
        return -1.0e300;
    return static_cast<double>(mass) * static_cast<double>(acceleration);
}
