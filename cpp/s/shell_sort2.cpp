/* Shell sort using the Ciura gap sequence. */
#include <cstddef>
#include <cstdint>

extern "C" void shell_sort2(std::int64_t *values, std::size_t length) noexcept
{
    constexpr std::size_t gaps[] = {701, 301, 132, 57, 23, 10, 4, 1};
    for (const std::size_t gap : gaps) {
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
