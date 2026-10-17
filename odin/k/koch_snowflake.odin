package koch_snowflake

import "core:c"

MAX_POINTS :: 29

Point32 :: struct { x, y: f32 }

@(export, link_name="koch_snowflake")
koch_snowflake :: proc "c" (input: [^]f64, length: c.size_t,
    output: [^]f64, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 20 do return -1
    if input[0] != 0.0 && input[0] != 1.0 do return -1
    if input[1] != 2.0 && input[1] != 3.0 && input[1] != 4.0 && input[1] != 5.0 &&
       input[1] != 6.0 && input[1] != 7.0 && input[1] != 8.0 do return -1
    steps := int(input[0])
    point_count := int(input[1])
    if length != c.size_t(2 + 2 * point_count) do return -1
    for i := 0; i < 2 * point_count; i += 1 {
        value := input[i + 2]
        if value != value || value < -1000.0 || value > 1000.0 do return -1
    }
    result_points := point_count
    if steps == 1 do result_points = 4 * (point_count - 1) + 1
    result_count := 2 * result_points
    if output == nil || output_capacity < c.size_t(result_count) do return -2

    first: [MAX_POINTS]Point32
    second: [MAX_POINTS]Point32
    for i := 0; i < point_count; i += 1 {
        first[i] = Point32{x = f32(input[2 + 2*i]), y = f32(input[3 + 2*i])}
    }
    source := &first
    destination := &second
    source_count := point_count
    for step := 0; step < steps; step += 1 {
        cursor := 0
        for i := 0; i + 1 < source_count; i += 1 {
            start := source[i]
            finish := source[i + 1]
            dx := finish.x - start.x
            dy := finish.y - start.y
            tx := dx / 3.0
            ty := dy / 3.0
            x1 := start.x + tx
            y1 := start.y + ty
            rx := 0.49999997 * tx - 0.86602545 * ty
            ry := 0.86602545 * tx + 0.49999997 * ty
            tx2 := (dx * 2.0) / 3.0
            ty2 := (dy * 2.0) / 3.0
            destination[cursor] = start; cursor += 1
            destination[cursor] = Point32{x = x1, y = y1}; cursor += 1
            destination[cursor] = Point32{x = x1 + rx, y = y1 + ry}; cursor += 1
            destination[cursor] = Point32{x = start.x + tx2, y = start.y + ty2}; cursor += 1
        }
        destination[cursor] = source[source_count - 1]; cursor += 1
        source_count = cursor
        temp := source; source = destination; destination = temp
    }
    for i := 0; i < result_points; i += 1 {
        output[2*i] = f64(source[i].x)
        output[2*i+1] = f64(source[i].y)
    }
    return i64(result_count)
}
