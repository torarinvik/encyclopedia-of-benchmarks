#include <stddef.h>
#include <stdint.h>

#define MAX_POINTS 32
#define MAX_DIMENSION 4
#define MAX_CENTERS 8
#define MAX_INPUT_LENGTH 140

static int64_t squared_distance(const int64_t *coordinates, size_t dimension,
                                size_t row, size_t center) {
    int64_t distance = 0;
    for (size_t axis = 0; axis < dimension; ++axis) {
        const int64_t difference = coordinates[row * dimension + axis]
                                 - coordinates[center * dimension + axis];
        distance += difference * difference;
    }
    return distance;
}

static int row_is_selected(const int64_t *centers, size_t count, int64_t row) {
    for (size_t index = 0; index < count; ++index)
        if (centers[index] == row) return 1;
    return 0;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t kmeans_plus_plus_seeding(const int64_t *input, size_t length,
                                 uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t point_count_value = input[0];
    const int64_t dimension_value = input[1];
    const int64_t center_count_value = input[2];
    const int64_t first_row = input[3];
    if (point_count_value < 1 || point_count_value > MAX_POINTS
        || dimension_value < 1 || dimension_value > MAX_DIMENSION
        || center_count_value < 1 || center_count_value > MAX_CENTERS
        || center_count_value > point_count_value
        || first_row < 0 || first_row >= point_count_value) return -1;

    const size_t point_count = (size_t)point_count_value;
    const size_t dimension = (size_t)dimension_value;
    const size_t center_count = (size_t)center_count_value;
    const size_t coordinate_count = point_count * dimension;
    const size_t draw_offset = 4 + coordinate_count;
    if (length != draw_offset + center_count - 1) return -1;

    int64_t coordinates[MAX_POINTS * MAX_DIMENSION];
    for (size_t index = 0; index < coordinate_count; ++index) {
        const int64_t coordinate = input[4 + index];
        if (coordinate < -16 || coordinate > 16) return -1;
        coordinates[index] = coordinate;
    }

    int64_t centers[MAX_CENTERS] = {0};
    int64_t nearest[MAX_POINTS] = {0};
    centers[0] = first_row;
    for (size_t row = 0; row < point_count; ++row)
        nearest[row] = squared_distance(coordinates, dimension, row, (size_t)first_row);

    for (size_t step = 0; step + 1 < center_count; ++step) {
        const int64_t draw = input[draw_offset + step];
        int64_t total_weight = 0;
        for (size_t row = 0; row < point_count; ++row) total_weight += nearest[row];

        int64_t chosen = -1;
        if (total_weight == 0) {
            if (draw != 0) return -1;
            for (size_t row = 0; row < point_count; ++row) {
                if (!row_is_selected(centers, step + 1, (int64_t)row)) {
                    chosen = (int64_t)row;
                    break;
                }
            }
        } else {
            if (draw < 0 || draw >= total_weight) return -1;
            int64_t cumulative = 0;
            for (size_t row = 0; row < point_count; ++row) {
                cumulative += nearest[row];
                if (cumulative > draw) {
                    chosen = (int64_t)row;
                    break;
                }
            }
        }
        if (chosen < 0) return -1;
        centers[step + 1] = chosen;
        for (size_t row = 0; row < point_count; ++row) {
            const int64_t distance = squared_distance(coordinates, dimension,
                                                       row, (size_t)chosen);
            if (distance < nearest[row]) nearest[row] = distance;
        }
    }

    const size_t output_bytes = center_count * 8;
    if (output == NULL || output_capacity < output_bytes) return -2;
    for (size_t index = 0; index < center_count; ++index)
        store_i64_le(output, index * 8, centers[index]);
    return (int64_t)output_bytes;
}
