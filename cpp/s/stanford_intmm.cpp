/* Port the fixed-size integer matrix multiplication from Stanford IntMM. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t ROWSIZE = 40;
constexpr std::size_t CELL_COUNT = ROWSIZE * ROWSIZE;
constexpr std::int64_t MAX_PASSES = 10;

std::size_t decimal_width(std::int32_t value)
{
    std::uint32_t magnitude = value < 0 ? static_cast<std::uint32_t>(-static_cast<std::int64_t>(value))
                                        : static_cast<std::uint32_t>(value);
    std::size_t width = value < 0 ? 1 : 0;
    do { ++width; magnitude /= 10; } while (magnitude != 0);
    return width;
}

std::size_t write_decimal(std::int32_t value, std::uint8_t *output, std::size_t position)
{
    std::uint32_t magnitude = value < 0 ? static_cast<std::uint32_t>(-static_cast<std::int64_t>(value))
                                        : static_cast<std::uint32_t>(value);
    std::uint8_t reversed[10];
    std::size_t count = 0;
    if (value < 0) output[position++] = static_cast<std::uint8_t>('-');
    do {
        reversed[count++] = static_cast<std::uint8_t>('0' + magnitude % 10);
        magnitude /= 10;
    } while (magnitude != 0);
    while (count > 0) output[position++] = reversed[--count];
    return position;
}
}

extern "C" std::int64_t stanford_intmm(std::int64_t pass_count, std::uint8_t *output,
                                         std::size_t output_capacity) noexcept
{
    if (pass_count < 1 || pass_count > MAX_PASSES) return -1;

    std::int32_t a[CELL_COUNT], b[CELL_COUNT], product[CELL_COUNT];
    std::int32_t diagonal[MAX_PASSES];
    for (std::int64_t pass = 0; pass < pass_count; ++pass) {
        std::uint32_t seed = 74755;
        for (std::size_t index = 0; index < CELL_COUNT; ++index) {
            seed = (seed * 1309u + 13849u) & 65535u;
            a[index] = static_cast<std::int32_t>(seed % 120u) - 60;
        }
        for (std::size_t index = 0; index < CELL_COUNT; ++index) {
            seed = (seed * 1309u + 13849u) & 65535u;
            b[index] = static_cast<std::int32_t>(seed % 120u) - 60;
        }

        for (std::size_t row = 0; row < ROWSIZE; ++row) {
            for (std::size_t column = 0; column < ROWSIZE; ++column) {
                std::int32_t sum = 0;
                for (std::size_t inner = 0; inner < ROWSIZE; ++inner)
                    sum += a[row * ROWSIZE + inner] * b[inner * ROWSIZE + column];
                product[row * ROWSIZE + column] = sum;
            }
        }
        diagonal[pass] = product[static_cast<std::size_t>(pass) * ROWSIZE + static_cast<std::size_t>(pass)];
    }

    std::size_t required = 0;
    for (std::int64_t pass = 0; pass < pass_count; ++pass)
        required += decimal_width(diagonal[pass]) + 1;
    if (output == nullptr || output_capacity < required) return -2;

    std::size_t position = 0;
    for (std::int64_t pass = 0; pass < pass_count; ++pass) {
        position = write_decimal(diagonal[pass], output, position);
        output[position++] = static_cast<std::uint8_t>('\n');
    }
    return static_cast<std::int64_t>(position);
}
