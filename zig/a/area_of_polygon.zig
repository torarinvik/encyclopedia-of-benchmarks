const MAX_POLYGONS: usize = 32;
const MAX_VERTICES_PER_POLYGON: usize = 128;
const MAX_TOTAL_VERTICES: usize = 512;
const MAX_INPUT_VALUES: usize = 1 + MAX_POLYGONS + 2 * MAX_TOTAL_VERTICES;
const COORDINATE_LIMIT: i64 = 1_000_000;
const AREA_OFFSET: i64 = 1_000_000_007;

export fn area_of_polygon_benchmark(values: [*]const i64, length: usize) i64 {
    if (length < 1 or length > MAX_INPUT_VALUES) return -1;
    const polygon_count_value = values[0];
    if (polygon_count_value < 0 or polygon_count_value > MAX_POLYGONS) return -1;
    const polygon_count: usize = @intCast(polygon_count_value);
    var cursor: usize = 1;
    var total_vertices: usize = 0;
    for (0..polygon_count) |_| {
        if (cursor >= length) return -1;
        const vertex_count_value = values[cursor];
        cursor += 1;
        if (vertex_count_value < 3 or vertex_count_value > MAX_VERTICES_PER_POLYGON) return -1;
        const vertex_count: usize = @intCast(vertex_count_value);
        if (total_vertices + vertex_count > MAX_TOTAL_VERTICES or 2 * vertex_count > length - cursor) return -1;
        for (0..vertex_count) |vertex| {
            const x = values[cursor + 2 * vertex];
            const y = values[cursor + 2 * vertex + 1];
            if (x < -COORDINATE_LIMIT or x > COORDINATE_LIMIT or
                y < -COORDINATE_LIMIT or y > COORDINATE_LIMIT) return -1;
        }
        cursor += 2 * vertex_count;
        total_vertices += vertex_count;
    }
    if (cursor != length) return -1;

    cursor = 1;
    var checksum: i64 = 0;
    for (0..polygon_count) |polygon| {
        const vertex_count: usize = @intCast(values[cursor]);
        cursor += 1;
        const points = cursor;
        var previous_x = values[points + 2 * (vertex_count - 1)];
        var previous_y = values[points + 2 * (vertex_count - 1) + 1];
        var cross_sum: i64 = 0;
        for (0..vertex_count) |vertex| {
            const current_x = values[points + 2 * vertex];
            const current_y = values[points + 2 * vertex + 1];
            cross_sum += previous_x * current_y - current_x * previous_y;
            previous_x = current_x;
            previous_y = current_y;
        }
        const doubled_area = if (cross_sum < 0) -cross_sum else cross_sum;
        checksum += @as(i64, @intCast(polygon + 1)) * (doubled_area + AREA_OFFSET);
        cursor += 2 * vertex_count;
    }
    return checksum;
}
