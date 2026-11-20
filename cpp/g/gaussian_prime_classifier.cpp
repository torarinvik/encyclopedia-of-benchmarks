#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kMaxCoordinate = 10'000;

bool rational_prime(std::int64_t value) {
    if (value < 2) return false;
    if (value % 2 == 0) return value == 2;
    for (std::int64_t divisor = 3; divisor <= value / divisor; divisor += 2) {
        if (value % divisor == 0) return false;
    }
    return true;
}
}

extern "C" std::int64_t gaussian_prime_classifier(const std::int64_t* input,
                                                   std::size_t length) {
    if (input == nullptr || length < 1 || length > 3) return -1;
    if (length != 2) return -1;
    const std::int64_t real = input[0];
    const std::int64_t imaginary = input[1];
    if (real < -kMaxCoordinate || real > kMaxCoordinate ||
        imaginary < -kMaxCoordinate || imaginary > kMaxCoordinate) return -1;
    if (real == 0 && imaginary == 0) return 0;
    if (real == 0 || imaginary == 0) {
        const std::int64_t axis = real == 0 ? imaginary : real;
        const std::int64_t rational = axis < 0 ? -axis : axis;
        return rational % 4 == 3 && rational_prime(rational) ? 1 : 0;
    }
    const std::int64_t norm = real * real + imaginary * imaginary;
    return rational_prime(norm) ? 1 : 0;
}
