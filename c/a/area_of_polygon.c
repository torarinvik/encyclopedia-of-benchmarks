#include <stddef.h>
#include <stdint.h>

#define MAX_POLYGONS 32
#define MAX_VERTICES_PER_POLYGON 128
#define MAX_TOTAL_VERTICES 512
#define MAX_INPUT_VALUES (1 + MAX_POLYGONS + 2 * MAX_TOTAL_VERTICES)
#define COORDINATE_LIMIT 1000000LL
#define AREA_OFFSET 1000000007LL

int64_t area_of_polygon_benchmark(const int64_t *values, size_t length)
{
    if (length < 1 || length > MAX_INPUT_VALUES) return -1;
    const int64_t polygon_count_value = values[0];
    if (polygon_count_value < 0 || polygon_count_value > MAX_POLYGONS) return -1;
    const size_t polygon_count = (size_t)polygon_count_value;
    size_t cursor = 1;
    size_t total_vertices = 0;
    for (size_t polygon = 0; polygon < polygon_count; ++polygon) {
        if (cursor >= length) return -1;
        const int64_t vertex_count_value = values[cursor++];
        if (vertex_count_value < 3 || vertex_count_value > MAX_VERTICES_PER_POLYGON) return -1;
        const size_t vertex_count = (size_t)vertex_count_value;
        if (total_vertices + vertex_count > MAX_TOTAL_VERTICES ||
            2 * vertex_count > length - cursor) return -1;
        for (size_t vertex = 0; vertex < vertex_count; ++vertex) {
            const int64_t x = values[cursor + 2 * vertex];
            const int64_t y = values[cursor + 2 * vertex + 1];
            if (x < -COORDINATE_LIMIT || x > COORDINATE_LIMIT ||
                y < -COORDINATE_LIMIT || y > COORDINATE_LIMIT) return -1;
        }
        cursor += 2 * vertex_count;
        total_vertices += vertex_count;
    }
    if (cursor != length) return -1;

    cursor = 1;
    int64_t checksum = 0;
    for (size_t polygon = 0; polygon < polygon_count; ++polygon) {
        const size_t vertex_count = (size_t)values[cursor++];
        const size_t points = cursor;
        int64_t previous_x = values[points + 2 * (vertex_count - 1)];
        int64_t previous_y = values[points + 2 * (vertex_count - 1) + 1];
        int64_t cross_sum = 0;
        for (size_t vertex = 0; vertex < vertex_count; ++vertex) {
            const int64_t current_x = values[points + 2 * vertex];
            const int64_t current_y = values[points + 2 * vertex + 1];
            cross_sum += previous_x * current_y - current_x * previous_y;
            previous_x = current_x;
            previous_y = current_y;
        }
        const int64_t doubled_area = cross_sum < 0 ? -cross_sum : cross_sum;
        checksum += (int64_t)(polygon + 1) * (doubled_area + AREA_OFFSET);
        cursor += 2 * vertex_count;
    }
    return checksum;
}
