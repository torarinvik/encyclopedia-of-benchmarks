/* Independent portable implementation of TheAlgorithms/C shell sort. */
#include <cstddef>
#include <cstdint>

extern "C" void shell_sort(std::int64_t *values, std::size_t length) noexcept
{
    for (std::size_t gap = length / 2; gap > 0; gap /= 2) {
        for (std::size_t index = gap; index < length; ++index) {
            const std::int64_t key = values[index];
            std::size_t position = index;
            while (position >= gap && values[position - gap] > key) {
                values[position] = values[position - gap];
                position -= gap;
            }
            values[position] = key;
        }
    }
}
