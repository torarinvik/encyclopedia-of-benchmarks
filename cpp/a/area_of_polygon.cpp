#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_polygons = 32;
constexpr std::size_t max_vertices_per_polygon = 128;
constexpr std::size_t max_total_vertices = 512;
constexpr std::size_t max_input_values = 1 + max_polygons + 2 * max_total_vertices;
constexpr std::int64_t coordinate_limit = 1'000'000;
constexpr std::int64_t area_offset = 1'000'000'007;
}

extern "C" std::int64_t area_of_polygon_benchmark(const std::int64_t *values, std::size_t length)
{
    if (length < 1 || length > max_input_values) return -1;
    const std::int64_t polygon_count_value = values[0];
    if (polygon_count_value < 0 || polygon_count_value > static_cast<std::int64_t>(max_polygons)) return -1;
    const std::size_t polygon_count = static_cast<std::size_t>(polygon_count_value);
    std::size_t cursor = 1;
    std::size_t total_vertices = 0;
    for (std::size_t polygon = 0; polygon < polygon_count; ++polygon) {
        if (cursor >= length) return -1;
        const std::int64_t vertex_count_value = values[cursor++];
        if (vertex_count_value < 3 || vertex_count_value > static_cast<std::int64_t>(max_vertices_per_polygon)) return -1;
        const std::size_t vertex_count = static_cast<std::size_t>(vertex_count_value);
        if (total_vertices + vertex_count > max_total_vertices || 2 * vertex_count > length - cursor) return -1;
        for (std::size_t vertex = 0; vertex < vertex_count; ++vertex) {
            const std::int64_t x = values[cursor + 2 * vertex];
            const std::int64_t y = values[cursor + 2 * vertex + 1];
            if (x < -coordinate_limit || x > coordinate_limit || y < -coordinate_limit || y > coordinate_limit) return -1;
        }
        cursor += 2 * vertex_count;
        total_vertices += vertex_count;
    }
    if (cursor != length) return -1;

    cursor = 1;
    std::int64_t checksum = 0;
    for (std::size_t polygon = 0; polygon < polygon_count; ++polygon) {
        const std::size_t vertex_count = static_cast<std::size_t>(values[cursor++]);
        const std::size_t points = cursor;
        std::int64_t previous_x = values[points + 2 * (vertex_count - 1)];
        std::int64_t previous_y = values[points + 2 * (vertex_count - 1) + 1];
        std::int64_t cross_sum = 0;
        for (std::size_t vertex = 0; vertex < vertex_count; ++vertex) {
            const std::int64_t current_x = values[points + 2 * vertex];
            const std::int64_t current_y = values[points + 2 * vertex + 1];
            cross_sum += previous_x * current_y - current_x * previous_y;
            previous_x = current_x;
            previous_y = current_y;
        }
        const std::int64_t doubled_area = cross_sum < 0 ? -cross_sum : cross_sum;
        checksum += static_cast<std::int64_t>(polygon + 1) * (doubled_area + area_offset);
        cursor += 2 * vertex_count;
    }
    return checksum;
}
