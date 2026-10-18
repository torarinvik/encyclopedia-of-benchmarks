#include <stddef.h>
#include <stdint.h>

#define MAX_INITIAL_COUNT 16
#define MAX_INPUT_LENGTH 20
#define MAX_OUTPUT_WORDS 18

typedef struct {
    int32_t value;
    int32_t next;
} list_node;

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
    }
}

int64_t sorted_linked_list(const int64_t *input, size_t input_length,
                           uint8_t *output, size_t capacity) {
    if (input == NULL || input_length < 3 || input_length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_INITIAL_COUNT) return -1;
    const size_t count = (size_t)input[0];
    if (input_length != count + 3) return -1;

    list_node nodes[MAX_INITIAL_COUNT + 1];
    for (size_t index = 0; index < count; ++index) {
        const int64_t value = input[index + 1];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        if (index > 0 && input[index] >= value) return -1;
        nodes[index].value = (int32_t)value;
        nodes[index].next = index + 1 < count ? (int32_t)(index + 1) : -1;
    }
    const int64_t operation_value = input[count + 1];
    const int64_t key_value = input[count + 2];
    if (operation_value < 0 || operation_value > 2 ||
        key_value < INT32_MIN || key_value > INT32_MAX) return -1;
    const int operation = (int)operation_value;
    const int32_t key = (int32_t)key_value;
    int32_t head = count == 0 ? -1 : 0;
    int32_t tail = count == 0 ? -1 : (int32_t)(count - 1);

    if (operation == 0) {
        int32_t current = head;
        while (current >= 0) {
            if (nodes[current].value == key) return -1;
            current = nodes[current].next;
        }
    }

    int64_t staged[MAX_OUTPUT_WORDS] = {0};
    size_t word_count = 0;
    if (operation == 0) {
        const int32_t new_node = (int32_t)count;
        nodes[new_node].value = key;
        nodes[new_node].next = -1;
        if (head < 0) {
            head = new_node;
            tail = new_node;
        } else if (key < nodes[head].value) {
            nodes[new_node].next = head;
            head = new_node;
        } else if (key > nodes[tail].value) {
            nodes[tail].next = new_node;
            tail = new_node;
        } else {
            int32_t previous = head;
            while (nodes[previous].next >= 0 && nodes[nodes[previous].next].value < key) {
                previous = nodes[previous].next;
            }
            nodes[new_node].next = nodes[previous].next;
            nodes[previous].next = new_node;
            if (nodes[new_node].next < 0) tail = new_node;
        }
        staged[word_count++] = (int64_t)(count + 1);
        for (int32_t node = head; node >= 0; node = nodes[node].next) {
            staged[word_count++] = nodes[node].value;
        }
    } else if (operation == 1) {
        int found = 0;
        for (int32_t node = head; node >= 0; node = nodes[node].next) {
            if (nodes[node].value == key) { found = 1; break; }
        }
        staged[word_count++] = found;
    } else {
        int deleted = 0;
        if (head >= 0 && nodes[head].value == key) {
            head = nodes[head].next;
            if (head < 0) tail = -1;
            deleted = 1;
        } else {
            int32_t previous = head;
            while (previous >= 0 && nodes[previous].next >= 0) {
                const int32_t candidate = nodes[previous].next;
                if (nodes[candidate].value == key) {
                    nodes[previous].next = nodes[candidate].next;
                    if (tail == candidate) tail = previous;
                    deleted = 1;
                    break;
                }
                previous = candidate;
            }
        }
        staged[word_count++] = deleted;
        size_t remaining = 0;
        for (int32_t node = head; node >= 0; node = nodes[node].next) ++remaining;
        staged[word_count++] = (int64_t)remaining;
        for (int32_t node = head; node >= 0; node = nodes[node].next) {
            staged[word_count++] = nodes[node].value;
        }
    }

    const size_t output_bytes = word_count * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t index = 0; index < word_count; ++index) put_i64_le(output, index * 8, staged[index]);
    return (int64_t)output_bytes;
}
