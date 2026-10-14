package area_of_polygon

import "core:c"

MAX_POLYGONS :: 32
MAX_VERTICES_PER_POLYGON :: 128
MAX_TOTAL_VERTICES :: 512
MAX_INPUT_VALUES :: 1 + MAX_POLYGONS + 2 * MAX_TOTAL_VERTICES
COORDINATE_LIMIT :: i64(1_000_000)
AREA_OFFSET :: i64(1_000_000_007)

@(export)
area_of_polygon_benchmark :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length < 1 || length > MAX_INPUT_VALUES do return -1
    polygon_count_value := values[0]
    if polygon_count_value < 0 || polygon_count_value > MAX_POLYGONS do return -1
    polygon_count := int(polygon_count_value)
    cursor := 1
    total_vertices := 0
    for polygon := 0; polygon < polygon_count; polygon += 1 {
        if cursor >= int(length) do return -1
        vertex_count_value := values[cursor]
        cursor += 1
        if vertex_count_value < 3 || vertex_count_value > MAX_VERTICES_PER_POLYGON do return -1
        vertex_count := int(vertex_count_value)
        if total_vertices + vertex_count > MAX_TOTAL_VERTICES || 2 * vertex_count > int(length) - cursor do return -1
        for vertex := 0; vertex < vertex_count; vertex += 1 {
            x := values[cursor + 2 * vertex]
            y := values[cursor + 2 * vertex + 1]
            if x < -COORDINATE_LIMIT || x > COORDINATE_LIMIT || y < -COORDINATE_LIMIT || y > COORDINATE_LIMIT do return -1
        }
        cursor += 2 * vertex_count
        total_vertices += vertex_count
    }
    if cursor != int(length) do return -1

    cursor = 1
    checksum := i64(0)
    for polygon := 0; polygon < polygon_count; polygon += 1 {
        vertex_count := int(values[cursor])
        cursor += 1
        points := cursor
        previous_x := values[points + 2 * (vertex_count - 1)]
        previous_y := values[points + 2 * (vertex_count - 1) + 1]
        cross_sum := i64(0)
        for vertex := 0; vertex < vertex_count; vertex += 1 {
            current_x := values[points + 2 * vertex]
            current_y := values[points + 2 * vertex + 1]
            cross_sum += previous_x * current_y - current_x * previous_y
            previous_x = current_x
            previous_y = current_y
        }
        doubled_area := cross_sum
        if doubled_area < 0 do doubled_area = -doubled_area
        checksum += i64(polygon + 1) * (doubled_area + AREA_OFFSET)
        cursor += 2 * vertex_count
    }
    return checksum
}
