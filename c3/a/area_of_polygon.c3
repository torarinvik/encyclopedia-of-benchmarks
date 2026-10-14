module area_of_polygon;

const usz MAX_POLYGONS = 32;
const usz MAX_VERTICES_PER_POLYGON = 128;
const usz MAX_TOTAL_VERTICES = 512;
const usz MAX_INPUT_VALUES = 1 + MAX_POLYGONS + 2 * MAX_TOTAL_VERTICES;
const long COORDINATE_LIMIT = 1000000;
const long AREA_OFFSET = 1000000007;

fn long area_of_polygon_benchmark(long* values, usz length) @export("area_of_polygon_benchmark") {
    if (length < 1 || length > MAX_INPUT_VALUES) return -1;
    long polygon_count_value = values[0];
    if (polygon_count_value < 0 || polygon_count_value > (long)MAX_POLYGONS) return -1;
    usz polygon_count = (usz)polygon_count_value;
    usz cursor = 1;
    usz total_vertices = 0;
    for (usz polygon = 0; polygon < polygon_count; polygon++) {
        if (cursor >= length) return -1;
        long vertex_count_value = values[cursor++];
        if (vertex_count_value < 3 || vertex_count_value > (long)MAX_VERTICES_PER_POLYGON) return -1;
        usz vertex_count = (usz)vertex_count_value;
        if (total_vertices + vertex_count > MAX_TOTAL_VERTICES || 2 * vertex_count > length - cursor) return -1;
        for (usz vertex = 0; vertex < vertex_count; vertex++) {
            long x = values[cursor + 2 * vertex];
            long y = values[cursor + 2 * vertex + 1];
            if (x < -COORDINATE_LIMIT || x > COORDINATE_LIMIT || y < -COORDINATE_LIMIT || y > COORDINATE_LIMIT) return -1;
        }
        cursor += 2 * vertex_count;
        total_vertices += vertex_count;
    }
    if (cursor != length) return -1;

    cursor = 1;
    long checksum = 0;
    for (usz polygon = 0; polygon < polygon_count; polygon++) {
        usz vertex_count = (usz)values[cursor++];
        usz points = cursor;
        long previous_x = values[points + 2 * (vertex_count - 1)];
        long previous_y = values[points + 2 * (vertex_count - 1) + 1];
        long cross_sum = 0;
        for (usz vertex = 0; vertex < vertex_count; vertex++) {
            long current_x = values[points + 2 * vertex];
            long current_y = values[points + 2 * vertex + 1];
            cross_sum += previous_x * current_y - current_x * previous_y;
            previous_x = current_x;
            previous_y = current_y;
        }
        long doubled_area = cross_sum < 0 ? -cross_sum : cross_sum;
        checksum += (long)(polygon + 1) * (doubled_area + AREA_OFFSET);
        cursor += 2 * vertex_count;
    }
    return checksum;
}
