/* Shell sort using the pinned Python 1.3 gap shrink factor. */
#include <cstddef>
#include <cstdint>

extern "C" void shrink_shell_sort(std::int64_t *values, std::size_t length) noexcept
{
    std::size_t gap = length;
    while (gap > 1) {
        gap = static_cast<std::size_t>(static_cast<double>(gap) / 1.3);
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
