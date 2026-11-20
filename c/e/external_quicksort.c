/* Fixed-buffer endpoint quicksort with balanced reads and inward writes. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 1024
#define BUFFER_SIZE 8

static void sort_buffer(int64_t *buffer, size_t length)
{
    for (size_t index = 1; index < length; ++index) {
        const int64_t value = buffer[index];
        size_t position = index;
        while (position > 0 && value < buffer[position - 1]) {
            buffer[position] = buffer[position - 1];
            --position;
        }
        buffer[position] = value;
    }
}

static void sort_range(int64_t *values, ptrdiff_t first, ptrdiff_t last)
{
    while (last > first) {
        ptrdiff_t read_low = first, write_low = first;
        ptrdiff_t read_high = last, write_high = last;
        int64_t buffer[BUFFER_SIZE];
        size_t buffered = 0;
        bool have_max_lower = false, have_min_upper = false;
        int64_t max_lower = 0, min_upper = 0;
        ptrdiff_t lower_written_bound = first - 1;
        ptrdiff_t upper_written_bound = last + 1;

        while (read_high >= read_low) {
            int64_t incoming;
            if (read_low - write_low < write_high - read_high) {
                incoming = values[read_low++];
            } else {
                incoming = values[read_high--];
            }

            if (buffered < BUFFER_SIZE) {
                buffer[buffered++] = incoming;
                sort_buffer(buffer, buffered);
            } else if (incoming > buffer[BUFFER_SIZE - 1]) {
                if (have_min_upper && incoming > min_upper)
                    upper_written_bound = write_high;
                else {
                    min_upper = incoming;
                    have_min_upper = true;
                }
                values[write_high--] = incoming;
            } else if (incoming < buffer[0]) {
                if (have_max_lower && incoming < max_lower)
                    lower_written_bound = write_low;
                else {
                    max_lower = incoming;
                    have_max_lower = true;
                }
                values[write_low++] = incoming;
            } else if (write_low - first < last - write_high) {
                const int64_t outgoing = buffer[0];
                values[write_low++] = outgoing;
                max_lower = outgoing;
                have_max_lower = true;
                buffer[0] = incoming;
                sort_buffer(buffer, BUFFER_SIZE);
            } else {
                const int64_t outgoing = buffer[BUFFER_SIZE - 1];
                values[write_high--] = outgoing;
                min_upper = outgoing;
                have_min_upper = true;
                buffer[BUFFER_SIZE - 1] = incoming;
                sort_buffer(buffer, BUFFER_SIZE);
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

void external_quicksort(int64_t *values, size_t length)
{
    if (length == 0 || length > MAX_LENGTH || values == NULL) return;
    sort_range(values, 0, (ptrdiff_t)length - 1);
}
