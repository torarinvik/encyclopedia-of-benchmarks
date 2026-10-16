/* Bounded port of the pinned Java Library Sort gap-insertion routine. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_items = 256;
constexpr std::size_t max_capacity = 2 * max_items;

std::size_t find_insertion_index(const std::array<std::int64_t, max_capacity> &data,
                                 const std::array<bool, max_capacity> &occupied,
                                 std::size_t capacity, std::int64_t value) noexcept
{
    std::size_t low = 0;
    std::size_t high = capacity;
    while (low < high) {
        const std::size_t middle = low + (high - low) / 2;
        std::int64_t probe = INT32_MAX;
        for (std::size_t index = middle; index < capacity; ++index) {
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

void insert_at_end(std::array<std::int64_t, max_capacity> &data,
                   std::array<bool, max_capacity> &occupied,
                   std::size_t capacity, std::int64_t value) noexcept
{
    const std::size_t last = capacity - 1;
    std::ptrdiff_t left = static_cast<std::ptrdiff_t>(last) - 1;
    while (left >= 0 && occupied[static_cast<std::size_t>(left)]) --left;
    if (left < 0) return;
    for (std::size_t index = static_cast<std::size_t>(left); index < last; ++index) {
        data[index] = data[index + 1];
    }
    occupied[static_cast<std::size_t>(left)] = true;
    data[last] = value;
}

void insert_value(std::array<std::int64_t, max_capacity> &data,
                  std::array<bool, max_capacity> &occupied,
                  std::size_t capacity, std::int64_t value) noexcept
{
    const std::size_t position = find_insertion_index(data, occupied, capacity, value);
    if (position >= capacity) {
        insert_at_end(data, occupied, capacity, value);
        return;
    }
    if (!occupied[position]) {
        data[position] = value;
        occupied[position] = true;
        return;
    }

    std::size_t right = position;
    while (right < capacity && occupied[right]) ++right;
    std::ptrdiff_t left = static_cast<std::ptrdiff_t>(position) - 1;
    while (left >= 0 && occupied[static_cast<std::size_t>(left)]) --left;
    const bool can_go_right = right < capacity;
    const bool can_go_left = left >= 0;
    if (can_go_right && (!can_go_left ||
        right - position <= position - static_cast<std::size_t>(left))) {
        for (std::size_t index = right; index > position; --index) {
            data[index] = data[index - 1];
        }
        occupied[right] = true;
        data[position] = value;
    } else if (can_go_left) {
        const std::size_t gap = static_cast<std::size_t>(left);
        for (std::size_t index = gap; index + 1 < position; ++index) {
            data[index] = data[index + 1];
        }
        occupied[gap] = true;
        data[position - 1] = value;
    }
}
} // namespace

extern "C" void library_sort(std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length < 2 || length > max_items) return;
    const std::size_t capacity = 2 * length;
    std::array<std::int64_t, max_capacity> data{};
    std::array<std::int64_t, max_items> temporary{};
    std::array<bool, max_capacity> occupied{};
    std::size_t filled = 1;
    std::size_t next = 1;
    std::size_t round = 0;
    const std::size_t middle = capacity / 2;
    data[middle] = values[0];
    occupied[middle] = true;

    while (next < length) {
        std::size_t batch = std::size_t{1} << round;
        if (batch > length - next) batch = length - next;
        for (std::size_t index = 0; index < batch; ++index) {
            insert_value(data, occupied, capacity, values[next + index]);
            ++filled;
        }
        next += batch;
        ++round;
        if (next < length) {
            std::size_t at = 0;
            for (std::size_t index = 0; index < capacity; ++index) {
                if (occupied[index]) temporary[at++] = data[index];
            }
            occupied.fill(false);
            for (std::size_t index = 0; index < filled; ++index) {
                const std::size_t slot = index * capacity / filled;
                data[slot] = temporary[index];
                occupied[slot] = true;
            }
        }
    }

    std::size_t output = 0;
    for (std::size_t index = 0; index < capacity; ++index) {
        if (occupied[index]) values[output++] = data[index];
    }
}
