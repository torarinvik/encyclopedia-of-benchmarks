#include <stddef.h>
#include <stdint.h>

#define MAX_OPERATIONS 32
#define MAX_INPUT_LENGTH 98
#define INVALID_RESULT (-1)
#define OUTPUT_ERROR (-2)

static size_t find_key(const int64_t *keys, size_t count, int64_t key) {
    for (size_t i = 0; i < count; ++i) if (keys[i] == key) return i;
    return count;
}

static void swap_items(int64_t *keys, int64_t *priorities, size_t a, size_t b) {
    int64_t value = keys[a]; keys[a] = keys[b]; keys[b] = value;
    value = priorities[a]; priorities[a] = priorities[b]; priorities[b] = value;
}

static void shift_up(int64_t *keys, int64_t *priorities, size_t index) {
    while (index > 0) {
        const size_t parent = (index - 1) / 2;
        if (priorities[parent] <= priorities[index]) break;
        swap_items(keys, priorities, parent, index);
        index = parent;
    }
}

static void shift_down(int64_t *keys, int64_t *priorities, size_t count, size_t index) {
    while (2 * index + 1 < count) {
        const size_t left = 2 * index + 1, right = left + 1;
        size_t child;
        if (priorities[left] < priorities[index] &&
            (right >= count || priorities[left] < priorities[right])) child = left;
        else if (right < count && priorities[right] < priorities[index]) child = right;
        else break;
        swap_items(keys, priorities, index, child);
        index = child;
    }
}

int64_t key_priority_queue(const int64_t *input, size_t length,
                           uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    if (input[0] < 0 || input[0] > MAX_OPERATIONS) return INVALID_RESULT;
    const size_t operation_count = (size_t)input[0];
    int64_t keys[MAX_OPERATIONS], priorities[MAX_OPERATIONS], answers[MAX_OPERATIONS];
    size_t heap_size = 0, answer_count = 0, position = 1;

    for (size_t operation_index = 0; operation_index < operation_count; ++operation_index) {
        if (position >= length) return INVALID_RESULT;
        const int64_t operation = input[position];
        if (operation == 0 || operation == 1) {
            if (position + 2 >= length) return INVALID_RESULT;
            const int64_t key = input[position + 1], priority = input[position + 2];
            if (key < -1000000000LL || key > 1000000000LL ||
                priority < -1000000000LL || priority > 1000000000LL) return INVALID_RESULT;
            position += 3;
            const size_t found = find_key(keys, heap_size, key);
            if (operation == 0) {
                if (found != heap_size) return INVALID_RESULT;
                keys[heap_size] = key; priorities[heap_size] = priority;
                shift_up(keys, priorities, heap_size++);
            } else if (found == heap_size) {
                keys[heap_size] = key; priorities[heap_size] = priority;
                shift_up(keys, priorities, heap_size++);
            } else {
                priorities[found] = priority;
                if (found > 0 && priorities[(found - 1) / 2] > priority) {
                    shift_up(keys, priorities, found);
                } else {
                    const size_t left = 2 * found + 1, right = left + 1;
                    if ((left < heap_size && priorities[left] < priority) ||
                        (right < heap_size && priorities[right] < priority))
                        shift_down(keys, priorities, heap_size, found);
                }
            }
        } else if (operation == 2) {
            ++position;
            if (heap_size == 0) return INVALID_RESULT;
            swap_items(keys, priorities, 0, heap_size - 1);
            answers[answer_count++] = keys[--heap_size];
            if (heap_size > 0) shift_down(keys, priorities, heap_size, 0);
        } else if (operation == 3) {
            if (position + 1 >= length) return INVALID_RESULT;
            const int64_t key = input[position + 1];
            if (key < -1000000000LL || key > 1000000000LL) return INVALID_RESULT;
            position += 2;
            answers[answer_count++] = find_key(keys, heap_size, key) != heap_size;
        } else if (operation == 4) {
            ++position;
            answers[answer_count++] = heap_size == 0;
        } else return INVALID_RESULT;
    }
    if (position != length) return INVALID_RESULT;
    const size_t output_length = answer_count * sizeof(int64_t);
    if (output == NULL || output_capacity < output_length) return OUTPUT_ERROR;
    for (size_t i = 0; i < answer_count; ++i) {
        const uint64_t bits = (uint64_t)answers[i];
        for (size_t b = 0; b < 8; ++b) output[8 * i + b] = (uint8_t)(bits >> (8 * b));
    }
    return (int64_t)output_length;
}
