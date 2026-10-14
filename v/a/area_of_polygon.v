module area_of_polygon

const max_polygons = 32
const max_vertices_per_polygon = 128
const max_total_vertices = 512
const max_input_values = 1 + max_polygons + 2 * max_total_vertices
const coordinate_limit = 1_000_000

@[export: 'area_of_polygon_benchmark']
pub fn area_of_polygon_benchmark(values &i64, length usize) i64 {
	area_offset := i64(1_000_000_007)
	if length < 1 || length > max_input_values { return -1 }
	polygon_count_value := unsafe { values[0] }
	if polygon_count_value < 0 || polygon_count_value > max_polygons { return -1 }
	polygon_count := int(polygon_count_value)
	mut cursor := 1
	mut total_vertices := 0
	for _ in 0 .. polygon_count {
		if cursor >= int(length) { return -1 }
		vertex_count_value := unsafe { values[cursor] }
		cursor++
		if vertex_count_value < 3 || vertex_count_value > max_vertices_per_polygon { return -1 }
		vertex_count := int(vertex_count_value)
		if total_vertices + vertex_count > max_total_vertices || 2 * vertex_count > int(length) - cursor { return -1 }
		for vertex in 0 .. vertex_count {
			x := unsafe { values[cursor + 2 * vertex] }
			y := unsafe { values[cursor + 2 * vertex + 1] }
			if x < -coordinate_limit || x > coordinate_limit || y < -coordinate_limit || y > coordinate_limit { return -1 }
		}
		cursor += 2 * vertex_count
		total_vertices += vertex_count
	}
	if cursor != int(length) { return -1 }

	mut checksum := i64(0)
	cursor = 1
	for polygon in 0 .. polygon_count {
		vertex_count := int(unsafe { values[cursor] })
		cursor++
		points := cursor
		mut previous_x := unsafe { values[points + 2 * (vertex_count - 1)] }
		mut previous_y := unsafe { values[points + 2 * (vertex_count - 1) + 1] }
		mut cross_sum := i64(0)
		for vertex in 0 .. vertex_count {
			current_x := unsafe { values[points + 2 * vertex] }
			current_y := unsafe { values[points + 2 * vertex + 1] }
			cross_sum += previous_x * current_y - current_x * previous_y
			previous_x = current_x
			previous_y = current_y
		}
		mut doubled_area := cross_sum
		if doubled_area < 0 { doubled_area = -doubled_area }
		checksum += i64(polygon + 1) * (doubled_area + area_offset)
		cursor += 2 * vertex_count
	}
	return checksum
}
