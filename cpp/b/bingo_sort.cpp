#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_values = 1024; }

extern "C" void bingo_sort(std::int64_t *values, std::size_t length)
{
    if (length > max_values || length < 2) return;
    std::int64_t bingo = values[0];
    for (std::size_t index = 1; index < length; ++index) {
        if (values[index] < bingo) bingo = values[index];
    }
    std::size_t next_position = 0;
    while (next_position < length) {
        bool has_next = false;
        std::int64_t next_bingo = 0;
        for (std::size_t index = next_position; index < length; ++index) {
            if (values[index] == bingo) {
                const std::int64_t temporary = values[index];
                values[index] = values[next_position];
                values[next_position] = temporary;
                ++next_position;
            } else if (!has_next || values[index] < next_bingo) {
                next_bingo = values[index];
                has_next = true;
            }
        }
        if (next_position == length) break;
        bingo = next_bingo;
    }
}
