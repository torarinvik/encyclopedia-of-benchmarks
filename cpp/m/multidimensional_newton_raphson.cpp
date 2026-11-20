#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kMinCoordinate = 900;
constexpr std::int64_t kMaxCoordinate = 1500;
constexpr std::int64_t kMaxUpdates = 8;

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}

std::int64_t round_nano(double value) {
    const double magnitude = value < 0.0 ? -value : value;
    const auto rounded = static_cast<std::int64_t>(
        std::floor(magnitude * 1'000'000'000.0 + 0.5));
    return value < 0.0 ? -rounded : rounded;
}
}

extern "C" std::int64_t multidimensional_newton_raphson(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 1U || length > 4U) return -1;
    if (length != 3U) return -1;
    const auto x_milli = input[0];
    const auto y_milli = input[1];
    const auto updates = input[2];
    if (x_milli < kMinCoordinate || x_milli > kMaxCoordinate
            || y_milli < kMinCoordinate || y_milli > kMaxCoordinate
            || updates < 1 || updates > kMaxUpdates) return -1;
    if (output == nullptr || capacity < 16U) return -2;

    double x = static_cast<double>(x_milli) / 1000.0;
    double y = static_cast<double>(y_milli) / 1000.0;
    for (std::int64_t step = 0; step < updates; ++step) {
        const double f1 = x * x + y - 3.0;
        const double f2 = x + y * y - 3.0;
        const double determinant = 4.0 * x * y - 1.0;
        const double dx = (2.0 * y * f1 - f2) / determinant;
        const double dy = (2.0 * x * f2 - f1) / determinant;
        x -= dx;
        y -= dy;
    }
    store_i64_le(output, 0, round_nano(x));
    store_i64_le(output, 8, round_nano(y));
    return 16;
}
