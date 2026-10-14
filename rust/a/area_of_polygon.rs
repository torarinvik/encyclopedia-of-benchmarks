const MAX_POLYGONS: usize = 32;
const MAX_VERTICES_PER_POLYGON: usize = 128;
const MAX_TOTAL_VERTICES: usize = 512;
const MAX_INPUT_VALUES: usize = 1 + MAX_POLYGONS + 2 * MAX_TOTAL_VERTICES;
const COORDINATE_LIMIT: i64 = 1_000_000;
const AREA_OFFSET: i64 = 1_000_000_007;

#[no_mangle]
pub unsafe extern "C" fn area_of_polygon_benchmark(values: *const i64, length: usize) -> i64 {
    if length < 1 || length > MAX_INPUT_VALUES { return -1; }
    let polygon_count_value = *values;
    if !(0..=MAX_POLYGONS as i64).contains(&polygon_count_value) { return -1; }
    let polygon_count = polygon_count_value as usize;
    let mut cursor = 1usize;
    let mut total_vertices = 0usize;
    for _ in 0..polygon_count {
        if cursor >= length { return -1; }
        let vertex_count_value = *values.add(cursor);
        cursor += 1;
        if !(3..=MAX_VERTICES_PER_POLYGON as i64).contains(&vertex_count_value) { return -1; }
        let vertex_count = vertex_count_value as usize;
        if total_vertices + vertex_count > MAX_TOTAL_VERTICES || 2 * vertex_count > length - cursor { return -1; }
        for vertex in 0..vertex_count {
            let x = *values.add(cursor + 2 * vertex);
            let y = *values.add(cursor + 2 * vertex + 1);
            if !(-COORDINATE_LIMIT..=COORDINATE_LIMIT).contains(&x)
                || !(-COORDINATE_LIMIT..=COORDINATE_LIMIT).contains(&y) { return -1; }
        }
        cursor += 2 * vertex_count;
        total_vertices += vertex_count;
    }
    if cursor != length { return -1; }

    cursor = 1;
    let mut checksum = 0i64;
    for polygon in 0..polygon_count {
        let vertex_count = *values.add(cursor) as usize;
        cursor += 1;
        let points = cursor;
        let mut previous_x = *values.add(points + 2 * (vertex_count - 1));
        let mut previous_y = *values.add(points + 2 * (vertex_count - 1) + 1);
        let mut cross_sum = 0i64;
        for vertex in 0..vertex_count {
            let current_x = *values.add(points + 2 * vertex);
            let current_y = *values.add(points + 2 * vertex + 1);
            cross_sum += previous_x * current_y - current_x * previous_y;
            previous_x = current_x;
            previous_y = current_y;
        }
        checksum += (polygon as i64 + 1) * (cross_sum.abs() + AREA_OFFSET);
        cursor += 2 * vertex_count;
    }
    checksum
}
