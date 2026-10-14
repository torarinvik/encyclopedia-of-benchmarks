#include <cstddef>
#include <cstdint>

static std::size_t emit_hanoi(std::size_t disks, std::uint8_t source, std::uint8_t destination,
                              std::uint8_t auxiliary, std::uint8_t *output, std::size_t position) noexcept
{
    if (disks == 0) return position;
    position = emit_hanoi(disks - 1, source, auxiliary, destination, output, position);
    output[position] = source;
    output[position + 1] = destination;
    return emit_hanoi(disks - 1, auxiliary, destination, source, output, position + 2);
}

extern "C" std::int64_t tower_of_hanoi(const std::int64_t *values, std::size_t length,
                                        std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (values == nullptr || length != 4 || values[0] < 0 || values[0] > 12) return -1;
    for (std::size_t index = 1; index < 4; ++index)
        if (values[index] < 0 || values[index] > 2) return -1;
    if (values[1] == values[2] || values[1] == values[3] || values[2] == values[3]) return -1;
    const auto disks = static_cast<std::size_t>(values[0]);
    const auto move_count = (std::size_t{1} << disks) - 1;
    const auto required = move_count * 2;
    if (output_capacity < required || (required != 0 && output == nullptr)) return -2;
    emit_hanoi(disks, static_cast<std::uint8_t>(values[1]), static_cast<std::uint8_t>(values[2]),
               static_cast<std::uint8_t>(values[3]), output, 0);
    return static_cast<std::int64_t>(move_count);
}
