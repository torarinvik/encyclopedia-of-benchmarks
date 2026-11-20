/* Greedy minimum refueling stops using a bounded max-heap. */
#include <stddef.h>
#include <stdint.h>

static void heap_push(int64_t heap[8], size_t *length, int64_t value)
{
    size_t child = (*length)++;
    heap[child] = value;
    while (child > 0) {
        const size_t parent = (child - 1) / 2;
        if (heap[parent] >= heap[child]) break;
        const int64_t temporary = heap[parent];
        heap[parent] = heap[child];
        heap[child] = temporary;
        child = parent;
    }
}

static int64_t heap_pop(int64_t heap[8], size_t *length)
{
    const int64_t maximum = heap[0];
    --*length;
    if (*length == 0) return maximum;
    heap[0] = heap[*length];
    size_t parent = 0;
    for (;;) {
        const size_t left = 2 * parent + 1;
        const size_t right = left + 1;
        if (left >= *length) break;
        size_t child = left;
        if (right < *length && heap[right] > heap[left]) child = right;
        if (heap[parent] >= heap[child]) break;
        const int64_t temporary = heap[parent];
        heap[parent] = heap[child];
        heap[child] = temporary;
        parent = child;
    }
    return maximum;
}

int64_t minimum_refueling_stops_heap(const int64_t *input, size_t length)
{
    if (input == NULL || length < 3 || length > 20) return -2;
    const int64_t target = input[0];
    const int64_t start_fuel = input[1];
    const int64_t count_value = input[2];
    if (target < 1 || target > 2000 || start_fuel < 0 || start_fuel > 2000
        || count_value < 0 || count_value > 8) return -2;
    const size_t count = (size_t)count_value;
    if (length != 3 + 2 * count) return -2;
    int64_t previous = 0;
    for (size_t i = 0; i < count; ++i) {
        const int64_t position = input[3 + 2 * i];
        const int64_t fuel = input[4 + 2 * i];
        if (position <= previous || position >= target || fuel < 1 || fuel > 2000) return -2;
        previous = position;
    }

    int64_t heap[8] = {0};
    size_t heap_length = 0;
    size_t next_station = 0;
    int64_t reach = start_fuel;
    int64_t stops = 0;
    while (reach < target) {
        while (next_station < count && input[3 + 2 * next_station] <= reach) {
            heap_push(heap, &heap_length, input[4 + 2 * next_station]);
            ++next_station;
        }
        if (heap_length == 0) return -1;
        reach += heap_pop(heap, &heap_length);
        ++stops;
    }
    return stops;
}
