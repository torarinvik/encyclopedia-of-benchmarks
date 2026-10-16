/* Bounded port of the pinned Java Library Sort gap-insertion routine. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_ITEMS = 256, MAX_CAPACITY = 512 };

static size_t find_insertion_index(const int64_t *data, const bool *occupied,
                                   size_t capacity, int64_t value)
{
    size_t low = 0;
    size_t high = capacity;
    while (low < high) {
        const size_t middle = low + (high - low) / 2;
        int64_t probe = INT32_MAX;
        for (size_t index = middle; index < capacity; ++index) {
            if (occupied[index]) {
                probe = data[index];
                break;
            }
        }
        if (probe != INT32_MAX && probe <= value) low = middle + 1;
        else high = middle;
    }
    return low;
}

static void insert_at_end(int64_t *data, bool *occupied, size_t capacity,
                          int64_t value)
{
    const size_t last = capacity - 1;
    ptrdiff_t left = (ptrdiff_t)last - 1;
    while (left >= 0 && occupied[(size_t)left]) --left;
    if (left < 0) return;
    for (size_t index = (size_t)left; index < last; ++index) {
        data[index] = data[index + 1];
    }
    occupied[(size_t)left] = true;
    data[last] = value;
}

static void insert_value(int64_t *data, bool *occupied, size_t capacity,
                         int64_t value)
{
    const size_t position = find_insertion_index(data, occupied, capacity, value);
    if (position >= capacity) {
        insert_at_end(data, occupied, capacity, value);
        return;
    }
    if (!occupied[position]) {
        data[position] = value;
        occupied[position] = true;
        return;
    }

    size_t right = position;
    while (right < capacity && occupied[right]) ++right;
    ptrdiff_t left = (ptrdiff_t)position - 1;
    while (left >= 0 && occupied[(size_t)left]) --left;
    const bool can_go_right = right < capacity;
    const bool can_go_left = left >= 0;
    if (can_go_right && (!can_go_left ||
        right - position <= position - (size_t)left)) {
        for (size_t index = right; index > position; --index) {
            data[index] = data[index - 1];
        }
        occupied[right] = true;
        data[position] = value;
    } else if (can_go_left) {
        const size_t gap = (size_t)left;
        for (size_t index = gap; index + 1 < position; ++index) {
            data[index] = data[index + 1];
        }
        occupied[gap] = true;
        data[position - 1] = value;
    }
}

void library_sort(int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > MAX_ITEMS) return;
    const size_t capacity = 2 * length;
    int64_t data[MAX_CAPACITY];
    int64_t temporary[MAX_ITEMS];
    bool occupied[MAX_CAPACITY] = { false };
    size_t filled = 1;
    size_t next = 1;
    size_t round = 0;
    const size_t middle = capacity / 2;
    data[middle] = values[0];
    occupied[middle] = true;

    while (next < length) {
        size_t batch = (size_t)1 << round;
        if (batch > length - next) batch = length - next;
        for (size_t index = 0; index < batch; ++index) {
            insert_value(data, occupied, capacity, values[next + index]);
            ++filled;
        }
        next += batch;
        ++round;
        if (next < length) {
            size_t at = 0;
            for (size_t index = 0; index < capacity; ++index) {
                if (occupied[index]) temporary[at++] = data[index];
            }
            for (size_t index = 0; index < capacity; ++index) occupied[index] = false;
            for (size_t index = 0; index < filled; ++index) {
                const size_t slot = index * capacity / filled;
                data[slot] = temporary[index];
                occupied[slot] = true;
            }
        }
    }

    size_t output = 0;
    for (size_t index = 0; index < capacity; ++index) {
        if (occupied[index]) values[output++] = data[index];
    }
}
