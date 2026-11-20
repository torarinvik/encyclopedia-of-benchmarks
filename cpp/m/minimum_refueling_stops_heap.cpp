/* Greedy minimum refueling stops using a bounded max-heap. */
#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t minimum_refueling_stops_heap(const std::int64_t *input,
                                                        std::size_t length) noexcept
{
    if (input == nullptr || length < 3 || length > 20) return -2;
    const auto target = input[0];
    const auto start_fuel = input[1];
    const auto count_value = input[2];
    if (target < 1 || target > 2000 || start_fuel < 0 || start_fuel > 2000
        || count_value < 0 || count_value > 8) return -2;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != 3 + 2 * count) return -2;
    std::int64_t previous = 0;
    for (std::size_t i = 0; i < count; ++i) {
        const auto position = input[3 + 2 * i];
        const auto fuel = input[4 + 2 * i];
        if (position <= previous || position >= target || fuel < 1 || fuel > 2000) return -2;
        previous = position;
    }

    std::array<std::int64_t, 8> heap{};
    std::size_t heap_length = 0;
    std::size_t next_station = 0;
    auto reach = start_fuel;
    std::int64_t stops = 0;
    while (reach < target) {
        while (next_station < count && input[3 + 2 * next_station] <= reach) {
            std::size_t child = heap_length++;
            heap[child] = input[4 + 2 * next_station];
            while (child > 0) {
                const std::size_t parent = (child - 1) / 2;
                if (heap[parent] >= heap[child]) break;
                const auto temporary = heap[parent];
                heap[parent] = heap[child];
                heap[child] = temporary;
                child = parent;
            }
            ++next_station;
        }
        if (heap_length == 0) return -1;
        const auto maximum = heap[0];
        --heap_length;
        if (heap_length > 0) {
            heap[0] = heap[heap_length];
            std::size_t parent = 0;
            for (;;) {
                const std::size_t left = 2 * parent + 1;
                const std::size_t right = left + 1;
                if (left >= heap_length) break;
                std::size_t child = left;
                if (right < heap_length && heap[right] > heap[left]) child = right;
                if (heap[parent] >= heap[child]) break;
                const auto temporary = heap[parent];
                heap[parent] = heap[child];
                heap[child] = temporary;
                parent = child;
            }
        }
        reach += maximum;
        ++stops;
    }
    return stops;
}
