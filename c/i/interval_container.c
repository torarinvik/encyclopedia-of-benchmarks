#include <stddef.h>
#include <stdint.h>

enum { MAX_OPERATIONS = 24, RECORD_WIDTH = 3, MAX_INPUT_VALUES = 73,
       MAX_INTERVALS = 25, DOMAIN_END = 32 };

typedef struct {
    int left;
    int right;
} interval;

static void add_interval(interval *items, int *count, int left, int right) {
    if (left == right) return;
    interval next[MAX_INTERVALS];
    int out = 0;
    int inserted = 0;
    for (int i = 0; i < *count; ++i) {
        interval current = items[i];
        if (current.right < left) {
            next[out++] = current;
        } else if (right < current.left) {
            if (!inserted) {
                next[out++] = (interval){left, right};
                inserted = 1;
            }
            next[out++] = current;
        } else {
            if (current.left < left) left = current.left;
            if (current.right > right) right = current.right;
        }
    }
    if (!inserted) next[out++] = (interval){left, right};
    for (int i = 0; i < out; ++i) items[i] = next[i];
    *count = out;
}

static void remove_interval(interval *items, int *count, int left, int right) {
    if (left == right) return;
    interval next[MAX_INTERVALS + 1];
    int out = 0;
    for (int i = 0; i < *count; ++i) {
        interval current = items[i];
        if (current.right <= left || current.left >= right) {
            next[out++] = current;
        } else {
            if (current.left < left)
                next[out++] = (interval){current.left, left};
            if (current.right > right)
                next[out++] = (interval){right, current.right};
        }
    }
    for (int i = 0; i < out; ++i) items[i] = next[i];
    *count = out;
}

static int covered_length(const interval *items, int count) {
    int total = 0;
    for (int i = 0; i < count; ++i) total += items[i].right - items[i].left;
    return total;
}

static int valid_input(const int64_t *input, size_t length, int *count) {
    if (input == NULL || length < 1 || length > MAX_INPUT_VALUES) return 0;
    if (input[0] < 0 || input[0] > MAX_OPERATIONS) return 0;
    *count = (int)input[0];
    if (length != 1 + (size_t)(*count) * RECORD_WIDTH) return 0;
    for (int i = 0; i < *count; ++i) {
        size_t offset = 1 + (size_t)i * RECORD_WIDTH;
        int64_t opcode = input[offset];
        int64_t left = input[offset + 1];
        int64_t right = input[offset + 2];
        if (opcode < 0 || opcode > 1 || left < 0 || right < left ||
            right > DOMAIN_END) return 0;
    }
    return 1;
}

int64_t interval_container(const int64_t *input, size_t length) {
    int operation_count = 0;
    if (!valid_input(input, length, &operation_count)) return -1;
    interval items[MAX_INTERVALS] = {{0, 0}};
    int count = 0;
    int64_t checksum = 0;
    for (int i = 0; i < operation_count; ++i) {
        size_t offset = 1 + (size_t)i * RECORD_WIDTH;
        int opcode = (int)input[offset];
        int left = (int)input[offset + 1];
        int right = (int)input[offset + 2];
        if (opcode == 0) add_interval(items, &count, left, right);
        else remove_interval(items, &count, left, right);
        checksum += (int64_t)(i + 1) * covered_length(items, count);
    }
    return checksum;
}
