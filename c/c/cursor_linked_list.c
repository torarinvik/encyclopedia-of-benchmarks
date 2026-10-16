#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define CURSOR_SPACE_SIZE 100
#define MAX_OPERATIONS 64

static int find_value(const int64_t elements[CURSOR_SPACE_SIZE], const bool occupied[CURSOR_SPACE_SIZE],
                      const int64_t next[CURSOR_SPACE_SIZE], int64_t head, int64_t value,
                      int64_t *previous, int64_t *found) {
    *previous = -1;
    *found = head;
    while (*found != -1 && (!occupied[*found] || elements[*found] != value)) {
        *previous = *found;
        *found = next[*found];
    }
    return *found != -1;
}

static void free_node(int64_t elements[CURSOR_SPACE_SIZE], bool occupied[CURSOR_SPACE_SIZE],
                      int64_t next[CURSOR_SPACE_SIZE], int64_t index) {
    const int64_t old_free_head = next[0];
    occupied[index] = false;
    elements[index] = 0;
    next[index] = old_free_head;
    next[0] = index;
}

static int remove_value(int64_t elements[CURSOR_SPACE_SIZE], bool occupied[CURSOR_SPACE_SIZE],
                        int64_t next[CURSOR_SPACE_SIZE], int64_t *head, int64_t *count,
                        int64_t value) {
    int64_t previous, current;
    if (*head == -1 || !find_value(elements, occupied, next, *head, value, &previous, &current)) return 0;
    const int64_t successor = next[current];
    if (previous == -1) {
        free_node(elements, occupied, next, current);
        *head = successor;
    } else {
        next[previous] = successor;
        free_node(elements, occupied, next, current);
    }
    --*count;
    return 1;
}

static void put_i64(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t cursor_linked_list(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || input[0] < 0 || input[0] > MAX_OPERATIONS) return -1;
    const size_t operation_count = (size_t)input[0];
    if (length != 1 + 2 * operation_count) return -1;
    int64_t elements[CURSOR_SPACE_SIZE] = {0};
    int64_t next[CURSOR_SPACE_SIZE];
    bool occupied[CURSOR_SPACE_SIZE] = {false};
    for (size_t i = 0; i < CURSOR_SPACE_SIZE; ++i) next[i] = (int64_t)i + 1;
    next[CURSOR_SPACE_SIZE - 1] = 0;
    int64_t head = -1, count = 0;
    int64_t query_found[MAX_OPERATIONS] = {0}, query_values[MAX_OPERATIONS] = {0};
    size_t query_count = 0;

    for (size_t operation_index = 0; operation_index < operation_count; ++operation_index) {
        const int64_t operation = input[1 + 2 * operation_index];
        const int64_t argument = input[2 + 2 * operation_index];
        if (operation < 0 || operation > 4 || argument < INT32_MIN || argument > INT32_MAX) return -1;
        if (operation == 0) {
            const int64_t available = next[0];
            if (available == 0) return -1;
            next[0] = next[available];
            next[available] = -1;
            elements[available] = argument;
            occupied[available] = true;
            if (head == -1) head = available;
            else {
                int64_t tail = head;
                while (next[tail] != -1) tail = next[tail];
                next[tail] = available;
            }
            next[available] = -1;
            ++count;
        } else if (operation == 1) {
            if (!remove_value(elements, occupied, next, &head, &count, argument)) return -1;
        } else if (operation == 2) {
            if (argument < 0 || argument >= count) return -1;
            int64_t cursor = head;
            for (int64_t i = 0; i < argument; ++i) cursor = next[cursor];
            const int64_t value = elements[cursor];
            if (!remove_value(elements, occupied, next, &head, &count, value)) return -1;
        } else if (operation == 3) {
            if (argument >= 0 && argument < count) {
                int64_t cursor = head;
                for (int64_t i = 0; i < argument; ++i) cursor = next[cursor];
                query_found[query_count] = 1;
                query_values[query_count++] = elements[cursor];
            } else {
                query_found[query_count] = 0;
                query_values[query_count++] = 0;
            }
        } else {
            int64_t previous, found;
            if (find_value(elements, occupied, next, head, argument, &previous, &found)) {
                int64_t logical_index = 0, cursor = head;
                while (cursor != found) { cursor = next[cursor]; ++logical_index; }
                query_found[query_count] = 1;
                query_values[query_count++] = logical_index;
            } else {
                query_found[query_count] = 0;
                query_values[query_count++] = 0;
            }
        }
    }

    const size_t fields = 1 + 2 * query_count + 2 + 3 * CURSOR_SPACE_SIZE;
    const size_t required = fields * 8;
    if (output == NULL || capacity < required) return -2;
    size_t field = 0;
    put_i64(output, field++ * 8, (int64_t)query_count);
    for (size_t i = 0; i < query_count; ++i) {
        put_i64(output, field++ * 8, query_found[i]);
        put_i64(output, field++ * 8, query_values[i]);
    }
    put_i64(output, field++ * 8, head);
    put_i64(output, field++ * 8, count);
    for (size_t i = 0; i < CURSOR_SPACE_SIZE; ++i) {
        put_i64(output, field++ * 8, occupied[i] ? 1 : 0);
        put_i64(output, field++ * 8, elements[i]);
        put_i64(output, field++ * 8, next[i]);
    }
    return (int64_t)required;
}
