#include <stddef.h>
#include <stdint.h>

#define MAX_CAPACITY 32
#define MAX_INPUT_LENGTH 35
#define MAX_KEY INT64_C(1000000)

int64_t lcfs_hashing(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t capacity_value = input[0];
    const int64_t count_value = input[1];
    if (capacity_value < 1 || capacity_value > MAX_CAPACITY
            || count_value < 0 || count_value > capacity_value
            || length != (size_t)count_value + 2) return -1;

    const size_t capacity = (size_t)capacity_value;
    const size_t count = (size_t)count_value;
    for (size_t i = 0; i < count; ++i) {
        const int64_t key = input[i + 2];
        if (key < 0 || key > MAX_KEY) return -1;
        for (size_t j = 0; j < i; ++j) {
            if (input[j + 2] == key) return -1;
        }
    }

    int64_t table[MAX_CAPACITY];
    for (size_t i = 0; i < capacity; ++i) table[i] = -1;
    int64_t displacements = 0;
    for (size_t i = 0; i < count; ++i) {
        int64_t incoming = input[i + 2];
        size_t slot = (size_t)(incoming % capacity_value);
        size_t probes = 0;
        while (table[slot] != -1) {
            if (probes >= capacity) return -1;
            const int64_t resident = table[slot];
            table[slot] = incoming;
            incoming = resident;
            slot = (slot + 1) % capacity;
            ++probes;
            ++displacements;
        }
        table[slot] = incoming;
    }
    return displacements;
}
