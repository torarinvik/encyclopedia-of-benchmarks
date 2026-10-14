/* Stable strand sort using caller-provided temporary storage. */
#include <cstddef>
#include <cstdint>

extern "C" void strand_sort(std::int64_t *values, std::int64_t *scratch, std::size_t length) noexcept
{
    if (length < 2) return;
    std::size_t remaining = length;
    std::size_t result_length = 0;
    while (remaining > 0) {
        std::size_t strand_length = 0;
        std::size_t remaining_write = 0;
        for (std::size_t read = 0; read < remaining; ++read) {
            const std::int64_t value = values[read];
            if (strand_length == 0 || value >= scratch[strand_length - 1]) {
                scratch[strand_length++] = value;
            } else {
                values[remaining_write++] = value;
            }
        }
        const std::size_t old_start = length - result_length;
        const std::size_t new_start = old_start - strand_length;
        for (std::size_t index = 0; index < result_length; ++index) {
            values[new_start + index] = values[old_start + index];
        }
        std::size_t left = result_length;
        std::size_t right = strand_length;
        std::size_t destination = length;
        while (left > 0 && right > 0) {
            if (values[new_start + left - 1] > scratch[right - 1]) {
                values[--destination] = values[new_start + --left];
            } else {
                values[--destination] = scratch[--right];
            }
        }
        while (right > 0) values[--destination] = scratch[--right];
        remaining = remaining_write;
        result_length += strand_length;
    }
}
