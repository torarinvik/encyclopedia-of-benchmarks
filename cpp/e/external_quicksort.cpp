/* Fixed-buffer endpoint quicksort with balanced reads and inward writes. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_length = 1024;
constexpr std::size_t buffer_size = 8;

void sort_buffer(std::int64_t *buffer, std::size_t length) noexcept
{
    for (std::size_t index = 1; index < length; ++index) {
        const auto value = buffer[index];
        auto position = index;
        while (position > 0 && value < buffer[position - 1]) {
            buffer[position] = buffer[position - 1];
            --position;
        }
        buffer[position] = value;
    }
}

void sort_range(std::int64_t *values, std::ptrdiff_t first, std::ptrdiff_t last) noexcept
{
    while (last > first) {
        auto read_low = first, write_low = first;
        auto read_high = last, write_high = last;
        std::int64_t buffer[buffer_size];
        std::size_t buffered = 0;
        bool have_max_lower = false, have_min_upper = false;
        std::int64_t max_lower = 0, min_upper = 0;
        auto lower_written_bound = first - 1;
        auto upper_written_bound = last + 1;

        while (read_high >= read_low) {
            std::int64_t incoming;
            if (read_low - write_low < write_high - read_high)
                incoming = values[read_low++];
            else
                incoming = values[read_high--];

            if (buffered < buffer_size) {
                buffer[buffered++] = incoming;
                sort_buffer(buffer, buffered);
            } else if (incoming > buffer[buffer_size - 1]) {
                if (have_min_upper && incoming > min_upper) upper_written_bound = write_high;
                else { min_upper = incoming; have_min_upper = true; }
                values[write_high--] = incoming;
            } else if (incoming < buffer[0]) {
                if (have_max_lower && incoming < max_lower) lower_written_bound = write_low;
                else { max_lower = incoming; have_max_lower = true; }
                values[write_low++] = incoming;
            } else if (write_low - first < last - write_high) {
                const auto outgoing = buffer[0];
                values[write_low++] = outgoing;
                max_lower = outgoing;
                have_max_lower = true;
                buffer[0] = incoming;
                sort_buffer(buffer, buffer_size);
            } else {
                const auto outgoing = buffer[buffer_size - 1];
                values[write_high--] = outgoing;
                min_upper = outgoing;
                have_min_upper = true;
                buffer[buffer_size - 1] = incoming;
                sort_buffer(buffer, buffer_size);
            }
        }

        while (buffered > 0) values[write_high--] = buffer[--buffered];
        if (lower_written_bound - first < last - upper_written_bound) {
            sort_range(values, first, lower_written_bound);
            first = upper_written_bound;
        } else {
            sort_range(values, upper_written_bound, last);
            last = lower_written_bound;
        }
    }
}
}

extern "C" void external_quicksort(std::int64_t *values, std::size_t length) noexcept
{
    if (length == 0 || length > max_length || values == nullptr) return;
    sort_range(values, 0, static_cast<std::ptrdiff_t>(length) - 1);
}
