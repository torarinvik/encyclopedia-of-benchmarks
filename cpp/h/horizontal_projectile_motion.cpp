#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr double GRAVITY = 9.80665;
constexpr std::int64_t OUTPUT_BYTES = 24;

std::int64_t round_cents(double value)
{
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    const int exponent = static_cast<int>((bits >> 52) & 2047U);
    if (exponent == 0) return 0;
    const std::uint64_t mantissa = (std::uint64_t{1} << 52) | (bits & 4503599627370495ULL);
    const std::uint64_t product = mantissa * 25U;
    const int right_shift = 1073 - exponent;
    if (right_shift >= 59) return 0;
    std::uint64_t rounded = product >> right_shift;
    const std::uint64_t divisor = std::uint64_t{1} << right_shift;
    const std::uint64_t remainder = product & (divisor - 1U);
    const std::uint64_t halfway = divisor >> 1;
    if (remainder > halfway || (remainder == halfway && (rounded & 1U))) ++rounded;
    return (bits >> 63) ? -static_cast<std::int64_t>(rounded)
                        : static_cast<std::int64_t>(rounded);
}

void store_f64_le(std::uint8_t *output, std::size_t offset, double value)
{
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}  // namespace

extern "C" std::int64_t horizontal_projectile_motion(const std::int64_t *values,
        std::size_t length, std::uint8_t *output, std::size_t output_capacity)
{
    if (values == nullptr || length != 2) return -1;
    const std::int64_t velocity_milli = values[0], angle_millidegrees = values[1];
    if (velocity_milli < 0 || velocity_milli > 100000 ||
        angle_millidegrees < 1000 || angle_millidegrees > 90000) return -1;
    if (output == nullptr || output_capacity < static_cast<std::size_t>(OUTPUT_BYTES)) return -2;

    const double velocity = static_cast<double>(velocity_milli) / 1000.0;
    const double angle = static_cast<double>(angle_millidegrees) / 1000.0;
    constexpr double pi_over_180 = 3.14159265358979323846264338327950288 / 180.0;
    const double velocity_squared = velocity * velocity;
    const double distance_raw = velocity_squared * std::sin((2.0 * angle) * pi_over_180) / GRAVITY;
    const double angle_sine = std::sin(angle * pi_over_180);
    const double sine_squared = angle_sine * angle_sine;
    const double height_raw = velocity_squared * sine_squared / (2.0 * GRAVITY);
    const double time_raw = (2.0 * velocity) * angle_sine / GRAVITY;
    const double distance = static_cast<double>(round_cents(distance_raw)) / 100.0;
    const double height = static_cast<double>(round_cents(height_raw)) / 100.0;
    const double flight_time = static_cast<double>(round_cents(time_raw)) / 100.0;
    store_f64_le(output, 0, distance);
    store_f64_le(output, 8, height);
    store_f64_le(output, 16, flight_time);
    return OUTPUT_BYTES;
}
