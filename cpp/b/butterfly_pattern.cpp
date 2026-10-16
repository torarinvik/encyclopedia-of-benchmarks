#include <cstddef>
#include <cstdint>

namespace {
std::size_t write_run(std::uint8_t *output, std::size_t position, std::uint8_t byte,
                      std::size_t count) noexcept
{
    for (std::size_t index = 0; index < count; ++index) output[position++] = byte;
    return position;
}
}

extern "C" std::int64_t butterfly_pattern(std::int64_t n, std::uint8_t *output,
                                            std::size_t capacity) noexcept
{
    if (n < 1 || n > 45) return -1;
    const auto side = static_cast<std::size_t>(n);
    const auto width = 2 * side - 1;
    const auto required = width * width + 2 * side - 2;
    if (output == nullptr || capacity < required) return -2;

    std::size_t position = 0;
    for (std::size_t count = 1; count < side; ++count) {
        if (position != 0) output[position++] = '\n';
        position = write_run(output, position, '*', count);
        position = write_run(output, position, ' ', 2 * (side - count) - 1);
        position = write_run(output, position, '*', count);
    }
    if (position != 0) output[position++] = '\n';
    position = write_run(output, position, '*', width);
    for (std::size_t count = side - 1; count > 0; --count) {
        output[position++] = '\n';
        position = write_run(output, position, '*', count);
        position = write_run(output, position, ' ', 2 * (side - count) - 1);
        position = write_run(output, position, '*', count);
    }
    return static_cast<std::int64_t>(position);
}
