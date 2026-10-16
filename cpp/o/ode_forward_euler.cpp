#include <cstddef>
#include <cstdint>
#include <cstring>

static void store_f64_le(std::uint8_t *output, std::size_t offset, double value)
{
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}

extern "C" std::int64_t ode_forward_euler(const std::int64_t *values, std::size_t length,
        std::uint8_t *output, std::size_t output_capacity)
{
    if (values == nullptr || length != 4) return -1;
    if (values[0] < 1 || values[0] > 16 || values[1] < 1 || values[1] > 4 ||
        values[2] < -10 || values[2] > 10 || values[3] < -10 || values[3] > 10) return -1;
    if (output == nullptr || output_capacity < 16) return -2;
    const double dt = static_cast<double>(values[1]) / 4.0;
    double u = static_cast<double>(values[2]), v = static_cast<double>(values[3]);
    for (std::int64_t step = 0; step < values[0]; ++step) {
        const double old_u = u, old_v = v;
        u = old_u + dt * old_v;
        v = old_v - dt * old_u;
    }
    store_f64_le(output, 0, u);
    store_f64_le(output, 8, v);
    return 16;
}
