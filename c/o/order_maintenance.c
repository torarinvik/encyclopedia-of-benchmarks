/* Bounded cyclic-label order maintenance; deletion is outside this profile. */
#include <stddef.h>
#include <stdint.h>

#define MAX_ELEMENTS 64
#define MAX_OPERATIONS 128
#define MAX_INPUT_LENGTH 387
#define LABEL_MODULUS INT64_C(2147483648)
#define LABEL_RING INT64_C(4294967296)

static int64_t label_width(int64_t left, int64_t right)
{
    int64_t difference = right - left;
    if (difference < 0) difference += LABEL_RING;
    if (difference == 0) return LABEL_MODULUS;
    return difference > LABEL_MODULUS ? difference - LABEL_MODULUS : difference;
}

static void insert_after(int anchor, int new_id, int64_t *labels,
                         int *previous, int *following)
{
    int successor = following[anchor];
    if (label_width(labels[anchor], labels[successor]) <= 1) {
        int middle = successor;
        int end = following[middle];
        int64_t required = 3;
        while (end != anchor &&
               label_width(labels[anchor], labels[end]) <=
                   4 * label_width(labels[anchor], labels[middle])) {
            ++required;
            end = following[end];
            if (end == anchor) break;
            ++required;
            end = following[end];
            middle = following[middle];
        }
        int64_t interval = end == anchor ? LABEL_MODULUS
                                         : label_width(labels[anchor], labels[end]);
        int64_t spacing = interval / required;
        int64_t value = labels[end];
        int cursor = end;
        for (;;) {
            if (cursor == 0) {
                value += LABEL_MODULUS;
                if (value >= LABEL_RING) value -= LABEL_RING;
            }
            cursor = previous[cursor];
            if (cursor == anchor) break;
            value -= spacing;
            if (value < 0) value += LABEL_RING;
            labels[cursor] = value;
        }
    }

    successor = following[anchor];
    labels[new_id] = labels[anchor] + label_width(labels[anchor], labels[successor]) / 2;
    if (labels[new_id] >= LABEL_RING) labels[new_id] -= LABEL_RING;
    previous[new_id] = anchor;
    following[new_id] = successor;
    following[anchor] = new_id;
    previous[successor] = new_id;
}

int64_t order_maintenance(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    int64_t raw_capacity = input[0], raw_operations = input[1];
    if (raw_capacity < 0 || raw_capacity > MAX_ELEMENTS ||
        raw_operations < 0 || raw_operations > MAX_OPERATIONS ||
        length != (size_t)(2 + 3 * raw_operations)) return -1;
    int capacity = (int)raw_capacity, operation_count = (int)raw_operations;

    int64_t labels[MAX_ELEMENTS + 1] = {0};
    int previous[MAX_ELEMENTS + 1] = {0}, following[MAX_ELEMENTS + 1] = {0};
    int inserted = 0;
    int64_t checksum = 0;
    for (int operation = 0; operation < operation_count; ++operation) {
        size_t offset = 2 + 3 * (size_t)operation;
        int64_t opcode = input[offset], first = input[offset + 1], second = input[offset + 2];
        if (opcode == 0) {
            if (inserted >= capacity || first < 0 || first > inserted || second != inserted + 1)
                return -1;
            ++inserted;
            insert_after((int)first, inserted, labels, previous, following);
        } else if (opcode == 1) {
            if (first < 1 || first > inserted || second < 1 || second > inserted) return -1;
            if (labels[first] < labels[second]) checksum += operation + 1;
        } else return -1;
    }
    return checksum;
}
