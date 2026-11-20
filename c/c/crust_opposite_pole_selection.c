#include <stddef.h>
#include <stdint.h>

#define MAX_SAMPLES 8
#define MAX_CELL_VERTICES 8
#define MAX_INPUT 226
#define COORD_LIMIT 16

static void store_i64_le(uint8_t *out, size_t word, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[word * 8 + b] = (uint8_t)(bits >> (8 * b));
}

static int same_point(const int64_t a[3], const int64_t b[3]) {
    return a[0] == b[0] && a[1] == b[1] && a[2] == b[2];
}

int64_t crust_opposite_pole_selection(const int64_t *input, size_t length,
                                      uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT) return -1;
    const int64_t n_value = input[0];
    if (n_value < 1 || n_value > MAX_SAMPLES) return -1;
    const size_t n = (size_t)n_value;
    size_t offset = 1;
    int64_t samples[MAX_SAMPLES][3] = {{0}};
    int64_t answer[MAX_SAMPLES][2] = {{0}};

    for (size_t row = 0; row < n; ++row) {
        if (offset + 4 > length) return -1;
        int64_t sample[3] = {input[offset], input[offset + 1], input[offset + 2]};
        const int64_t count_value = input[offset + 3];
        offset += 4;
        if (count_value < 1 || count_value > MAX_CELL_VERTICES) return -1;
        const size_t count = (size_t)count_value;
        for (size_t axis = 0; axis < 3; ++axis)
            if (sample[axis] < -COORD_LIMIT || sample[axis] > COORD_LIMIT) return -1;
        for (size_t previous = 0; previous < row; ++previous)
            if (same_point(sample, samples[previous])) return -1;
        for (size_t axis = 0; axis < 3; ++axis) samples[row][axis] = sample[axis];
        if (offset + 3 * count > length) return -1;

        int64_t cell[MAX_CELL_VERTICES][3] = {{0}};
        for (size_t vertex = 0; vertex < count; ++vertex) {
            for (size_t axis = 0; axis < 3; ++axis) {
                const int64_t coordinate = input[offset++];
                if (coordinate < -COORD_LIMIT || coordinate > COORD_LIMIT) return -1;
                cell[vertex][axis] = coordinate;
            }
            if (same_point(sample, cell[vertex])) return -1;
            for (size_t previous = 0; previous < vertex; ++previous)
                if (same_point(cell[vertex], cell[previous])) return -1;
        }

        size_t positive = 0;
        int64_t positive_distance = -1;
        for (size_t vertex = 0; vertex < count; ++vertex) {
            int64_t distance = 0;
            for (size_t axis = 0; axis < 3; ++axis) {
                const int64_t delta = cell[vertex][axis] - sample[axis];
                distance += delta * delta;
            }
            if (distance > positive_distance) {
                positive_distance = distance;
                positive = vertex;
            }
        }
        int64_t forward[3];
        for (size_t axis = 0; axis < 3; ++axis)
            forward[axis] = cell[positive][axis] - sample[axis];
        int64_t negative = -1, negative_distance = -1;
        for (size_t vertex = 0; vertex < count; ++vertex) {
            int64_t distance = 0, projection = 0;
            for (size_t axis = 0; axis < 3; ++axis) {
                const int64_t delta = cell[vertex][axis] - sample[axis];
                distance += delta * delta;
                projection += delta * forward[axis];
            }
            if (projection < 0 && distance > negative_distance) {
                negative_distance = distance;
                negative = (int64_t)vertex;
            }
        }
        answer[row][0] = (int64_t)positive;
        answer[row][1] = negative;
    }
    if (offset != length) return -1;
    const size_t output_bytes = 8 * (1 + 2 * n);
    if (output == NULL || capacity < output_bytes) return -2;
    store_i64_le(output, 0, n_value);
    size_t word = 1;
    for (size_t row = 0; row < n; ++row) {
        store_i64_le(output, word++, answer[row][0]);
        store_i64_le(output, word++, answer[row][1]);
    }
    return (int64_t)output_bytes;
}
