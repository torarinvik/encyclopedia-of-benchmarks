// Count adjacent nonempty-row device pairs in a fixed-width binary bank.
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_dimension = 64; }

extern "C" std::int64_t number_of_laser_beams(const std::int64_t *input,
    std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_dimension * max_dimension + 2) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_dimension) ||
        input[1] < 1 || input[1] > static_cast<std::int64_t>(max_dimension)) return -1;
    const auto rows = static_cast<std::size_t>(input[0]);
    const auto columns = static_cast<std::size_t>(input[1]);
    if (length != rows * columns + 2) return -1;

    std::int64_t previous_devices = 0, beams = 0;
    for (std::size_t row = 0; row < rows; ++row) {
        std::int64_t devices = 0;
        for (std::size_t column = 0; column < columns; ++column) {
            const auto cell = input[2 + row * columns + column];
            if (cell != 48 && cell != 49) return -1;
            if (cell == 49) ++devices;
        }
        if (devices != 0) {
            beams += devices * previous_devices;
            previous_devices = devices;
        }
    }
    return beams;
}
