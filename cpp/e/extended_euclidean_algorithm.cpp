/* Iterative extended Euclid for positive signed-32-bit inputs. */
#include <cstddef>
#include <cstdint>
#include <limits>

static std::size_t store_i32(std::int64_t value, std::uint8_t *output, std::size_t position) noexcept
{
    std::uint32_t bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte) {
        output[position++] = static_cast<std::uint8_t>(bits & UINT32_C(255));
        bits >>= 8;
    }
    return position;
}

extern "C" std::int64_t extended_euclidean_algorithm(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (length != 2 || input[0] < 1 || input[0] > std::numeric_limits<std::int32_t>::max() ||
        input[1] < 1 || input[1] > std::numeric_limits<std::int32_t>::max()) return -1;
    if (output_capacity < 12) return -2;

    std::int64_t old_r = input[0], remainder = input[1];
    std::int64_t old_x = 1, x = 0, old_y = 0, y = 1;
    while (remainder != 0) {
        const std::int64_t quotient = old_r / remainder;
        const std::int64_t next_r = old_r - quotient * remainder;
        old_r = remainder;
        remainder = next_r;
        const std::int64_t next_x = old_x - quotient * x;
        old_x = x;
        x = next_x;
        const std::int64_t next_y = old_y - quotient * y;
        old_y = y;
        y = next_y;
    }
    if (old_r > std::numeric_limits<std::int32_t>::max() ||
        old_x < std::numeric_limits<std::int32_t>::min() || old_x > std::numeric_limits<std::int32_t>::max() ||
        old_y < std::numeric_limits<std::int32_t>::min() || old_y > std::numeric_limits<std::int32_t>::max()) return -1;
    std::size_t written = 0;
    written = store_i32(old_r, output, written);
    written = store_i32(old_x, output, written);
    written = store_i32(old_y, output, written);
    return written == 12 ? 3 : -1;
}
