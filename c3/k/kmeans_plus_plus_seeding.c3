module kmeans_plus_plus_seeding;

const long MAX_POINTS = 32;
const long MAX_DIMENSION = 4;
const long MAX_CENTERS = 8;
const usz MAX_INPUT_LENGTH = 140;

fn long squared_distance(long* coordinates, usz dimension, usz row, usz center) {
    long distance = 0;
    for (usz axis = 0; axis < dimension; axis++) {
        long difference = coordinates[row * dimension + axis]
                        - coordinates[center * dimension + axis];
        distance += difference * difference;
    }
    return distance;
}

fn bool row_is_selected(long* centers, usz count, long row) {
    for (usz index = 0; index < count; index++)
        if (centers[index] == row) return true;
    return false;
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++)
        output[offset + byte] = (char)((bits >> (byte * 8)) & 255);
}

fn long kmeans_plus_plus_seeding(long* input, usz length, char* output,
        usz output_capacity) @export("kmeans_plus_plus_seeding") {
    if (input == null || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    long point_count_value = input[0];
    long dimension_value = input[1];
    long center_count_value = input[2];
    long first_row = input[3];
    if (point_count_value < 1 || point_count_value > MAX_POINTS
        || dimension_value < 1 || dimension_value > MAX_DIMENSION
        || center_count_value < 1 || center_count_value > MAX_CENTERS
        || center_count_value > point_count_value
        || first_row < 0 || first_row >= point_count_value) return -1;

    usz point_count = (usz)point_count_value;
    usz dimension = (usz)dimension_value;
    usz center_count = (usz)center_count_value;
    usz coordinate_count = point_count * dimension;
    usz draw_offset = 4 + coordinate_count;
    if (length != draw_offset + center_count - 1) return -1;

    long[128] coordinates;
    for (usz index = 0; index < coordinate_count; index++) {
        long coordinate = input[4 + index];
        if (coordinate < -16 || coordinate > 16) return -1;
        coordinates[index] = coordinate;
    }

    long[8] centers;
    long[32] nearest;
    centers[0] = first_row;
    for (usz row = 0; row < point_count; row++)
        nearest[row] = squared_distance(&coordinates[0], dimension, row, (usz)first_row);

    for (usz step = 0; step + 1 < center_count; step++) {
        long draw = input[draw_offset + step];
        long total_weight = 0;
        for (usz row = 0; row < point_count; row++) total_weight += nearest[row];

        long chosen = -1;
        if (total_weight == 0) {
            if (draw != 0) return -1;
            for (usz row = 0; row < point_count; row++) {
                if (!row_is_selected(&centers[0], step + 1, (long)row)) {
                    chosen = (long)row;
                    break;
                }
            }
        } else {
            if (draw < 0 || draw >= total_weight) return -1;
            long cumulative = 0;
            for (usz row = 0; row < point_count; row++) {
                cumulative += nearest[row];
                if (cumulative > draw) {
                    chosen = (long)row;
                    break;
                }
            }
        }
        if (chosen < 0) return -1;
        centers[step + 1] = chosen;
        for (usz row = 0; row < point_count; row++) {
            long distance = squared_distance(&coordinates[0], dimension, row, (usz)chosen);
            if (distance < nearest[row]) nearest[row] = distance;
        }
    }

    usz output_bytes = center_count * 8;
    if (output == null || output_capacity < output_bytes) return -2;
    for (usz index = 0; index < center_count; index++)
        store_i64_le(output, index * 8, centers[index]);
    return (long)output_bytes;
}
