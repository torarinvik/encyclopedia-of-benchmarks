#include <stddef.h>
#include <stdint.h>

enum {
    MAX_MACHINES = 8,
    MAX_TASKS = 32,
    MAX_PARSEABLE_WORDS = 99
};

static int event_less(size_t left, size_t right, const int64_t finish[MAX_TASKS]) {
    if (finish[left] != finish[right]) return finish[left] < finish[right];
    return left < right;
}

static void heap_push(size_t heap[MAX_TASKS], size_t *heap_size, size_t task,
                      const int64_t finish[MAX_TASKS]) {
    size_t position = (*heap_size)++;
    while (position > 0u) {
        const size_t parent = (position - 1u) / 2u;
        if (!event_less(task, heap[parent], finish)) break;
        heap[position] = heap[parent];
        position = parent;
    }
    heap[position] = task;
}

static size_t heap_pop(size_t heap[MAX_TASKS], size_t *heap_size,
                       const int64_t finish[MAX_TASKS]) {
    const size_t minimum = heap[0];
    --*heap_size;
    if (*heap_size == 0u) return minimum;
    const size_t replacement = heap[*heap_size];
    size_t position = 0u;
    for (;;) {
        const size_t left = 2u * position + 1u;
        if (left >= *heap_size) break;
        const size_t right = left + 1u;
        size_t child = left;
        if (right < *heap_size && event_less(heap[right], heap[left], finish)) child = right;
        if (!event_less(heap[child], replacement, finish)) break;
        heap[position] = heap[child];
        position = child;
    }
    heap[position] = replacement;
    return minimum;
}

int64_t online_temporary_task_load_balancing(const int64_t *input, size_t length,
        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2u || length > MAX_PARSEABLE_WORDS) return -1;
    const int64_t machine_value = input[0];
    const int64_t task_value = input[1];
    if (machine_value < 1 || machine_value > MAX_MACHINES || task_value < 0 || task_value > MAX_TASKS) return -1;
    const size_t machine_count = (size_t)machine_value;
    const size_t task_count = (size_t)task_value;
    if (length != 2u + 3u * task_count) return -1;

    int64_t arrival[MAX_TASKS] = {0};
    int64_t weight[MAX_TASKS] = {0};
    int64_t finish[MAX_TASKS] = {0};
    size_t assigned[MAX_TASKS] = {0};
    int64_t loads[MAX_MACHINES] = {0};
    size_t heap[MAX_TASKS] = {0};
    size_t heap_size = 0u;
    int64_t staged[MAX_TASKS + 1u] = {0};
    int64_t previous_arrival = -1;

    for (size_t task = 0u; task < task_count; ++task) {
        const int64_t at = input[2u + 3u * task];
        const int64_t amount = input[3u + 3u * task];
        const int64_t duration = input[4u + 3u * task];
        if (at < 0 || at > 1000 || at < previous_arrival ||
            amount < 1 || amount > 1000 || duration < 1 || duration > 1000 ||
            at + duration > 2000) return -1;
        arrival[task] = at;
        weight[task] = amount;
        finish[task] = at + duration;
        previous_arrival = at;
    }

    int64_t peak = 0;
    for (size_t task = 0u; task < task_count; ++task) {
        while (heap_size > 0u && finish[heap[0]] <= arrival[task]) {
            const size_t expired = heap_pop(heap, &heap_size, finish);
            loads[assigned[expired]] -= weight[expired];
        }
        size_t machine = 0u;
        for (size_t candidate = 1u; candidate < machine_count; ++candidate)
            if (loads[candidate] < loads[machine]) machine = candidate;
        assigned[task] = machine;
        loads[machine] += weight[task];
        if (loads[machine] > peak) peak = loads[machine];
        heap_push(heap, &heap_size, task, finish);
    }

    staged[0] = peak;
    for (size_t task = 0u; task < task_count; ++task) staged[task + 1u] = (int64_t)assigned[task];
    const size_t output_words = task_count + 1u;
    const size_t output_bytes = 8u * output_words;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t word = 0u; word < output_words; ++word)
        for (size_t byte = 0u; byte < 8u; ++byte)
            output[8u * word + byte] = (uint8_t)(((uint64_t)staged[word] >> (8u * byte)) & 255u);
    return (int64_t)output_bytes;
}
