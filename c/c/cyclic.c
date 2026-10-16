#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 64
#define MAX_OPERATIONS 64
#define MAX_RECORD_FIELDS 5000

static void rotate_list(const int64_t *next, const int64_t *previous, int64_t *head,
                        int64_t size, int64_t places) {
    if (size == 0) return;
    places %= size;
    if (places < 0) places += size;
    if (places > size / 2) {
        places = size - places;
        for (int64_t i = 0; i < places; ++i) *head = previous[*head];
    } else {
        for (int64_t i = 0; i < places; ++i) *head = next[*head];
    }
}

static int delete_head(int64_t *values, int64_t *next, int64_t *previous,
                       int64_t *head, int64_t *size) {
    if (*size == 0) return 0;
    const int64_t current = *head;
    if (*size == 1) {
        *head = -1;
    } else {
        const int64_t successor = next[current], predecessor = previous[current];
        next[predecessor] = successor;
        previous[successor] = predecessor;
        *head = successor;
    }
    values[current] = 0;
    --*size;
    return 1;
}

static void add_record(int64_t *records, size_t *field_count, int64_t value) {
    records[(*field_count)++] = value;
}

static void put_i64(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t cyclic(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || input[0] < 0 || input[0] > MAX_OPERATIONS) return -1;
    const size_t operation_count = (size_t)input[0];
    if (length != 1 + 2 * operation_count) return -1;
    int64_t values[MAX_NODES] = {0}, next[MAX_NODES] = {0}, previous[MAX_NODES] = {0};
    int64_t head = -1, size = 0, allocated = 0;
    int64_t records[MAX_RECORD_FIELDS];
    size_t record_fields = 0, query_count = 0;

    for (size_t index = 0; index < operation_count; ++index) {
        const int64_t operation = input[1 + 2 * index], argument = input[2 + 2 * index];
        if (operation < 0 || operation > 5) return -1;
        if (operation == 0) {
            if (argument < INT32_MIN || argument > INT32_MAX || allocated >= MAX_NODES) return -1;
            const int64_t node = allocated++;
            values[node] = argument;
            if (size == 0) {
                head = node; next[node] = node; previous[node] = node;
            } else {
                const int64_t tail = previous[head];
                previous[node] = tail; next[node] = head;
                next[tail] = node; previous[head] = node;
            }
            ++size;
        } else if (operation == 1) {
            if (argument < -1000000 || argument > 1000000) return -1;
            rotate_list(next, previous, &head, size, argument);
        } else if (operation == 2) {
            if (argument != 0) return -1;
            const int64_t deleted = delete_head(values, next, previous, &head, &size);
            add_record(records, &record_fields, (int64_t)index);
            add_record(records, &record_fields, operation);
            add_record(records, &record_fields, 1);
            add_record(records, &record_fields, deleted);
            ++query_count;
        } else if (operation == 3) {
            if (argument != 0) return -1;
            add_record(records, &record_fields, (int64_t)index);
            add_record(records, &record_fields, operation);
            add_record(records, &record_fields, size);
            int64_t cursor = head;
            for (int64_t i = 0; i < size; ++i) { add_record(records, &record_fields, values[cursor]); cursor = next[cursor]; }
            ++query_count;
        } else if (operation == 4) {
            if (argument < -1000000 || argument > 1000000 || size == 0) return -1;
            while (size > 1) {
                rotate_list(next, previous, &head, size, argument);
                (void)delete_head(values, next, previous, &head, &size);
                rotate_list(next, previous, &head, size, -1);
            }
            const int64_t winner = values[head];
            while (delete_head(values, next, previous, &head, &size)) {}
            add_record(records, &record_fields, (int64_t)index);
            add_record(records, &record_fields, operation);
            add_record(records, &record_fields, 1);
            add_record(records, &record_fields, winner);
            ++query_count;
        } else {
            if (argument != 0) return -1;
            while (delete_head(values, next, previous, &head, &size)) {}
        }
    }

    const size_t fields = 1 + record_fields + 1 + (size_t)size;
    const size_t required = fields * 8;
    if (output == NULL || capacity < required) return -2;
    size_t field = 0;
    put_i64(output, field++ * 8, (int64_t)query_count);
    for (size_t i = 0; i < record_fields; ++i) put_i64(output, field++ * 8, records[i]);
    put_i64(output, field++ * 8, size);
    int64_t cursor = head;
    for (int64_t i = 0; i < size; ++i) { put_i64(output, field++ * 8, values[cursor]); cursor = next[cursor]; }
    return (int64_t)required;
}
