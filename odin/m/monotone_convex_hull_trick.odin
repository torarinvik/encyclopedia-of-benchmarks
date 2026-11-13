package monotone_convex_hull_trick

import "core:c"

Max_Lines :: 32
Max_Queries :: 32
Max_Length :: 99
Invalid :: i64(-9223372036854775807 - 1)

Line :: struct { slope, intercept: i64 }

line_value :: proc "contextless" (line: Line, x: i64) -> i64 {
    return line.slope * x + line.intercept
}

redundant :: proc "contextless" (a, b, c: Line) -> bool {
    return (b.intercept - a.intercept) * (b.slope - c.slope)
        >= (c.intercept - b.intercept) * (a.slope - b.slope)
}

@(export)
monotone_convex_hull_trick :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 2 || length > c.size_t(Max_Length) do return Invalid
    if values[0] < 1 || values[0] > Max_Lines || values[1] < 0 || values[1] > Max_Queries do return Invalid
    line_count := int(values[0])
    query_count := int(values[1])
    if length != c.size_t(2 + 2 * line_count + query_count) do return Invalid

    hull: [Max_Lines]Line
    hull_count := 0
    previous_slope := i64(9223372036854775807)
    cursor := 2
    for _ in 0 .. line_count {
        line := Line{values[cursor], values[cursor + 1]}
        cursor += 2
        if line.slope < -1000 || line.slope > 1000 || line.intercept < -10000 || line.intercept > 10000 || line.slope >= previous_slope do return Invalid
        previous_slope = line.slope
        for hull_count >= 2 && redundant(hull[hull_count - 2], hull[hull_count - 1], line) { hull_count -= 1 }
        hull[hull_count] = line
        hull_count += 1
    }

    front := 0
    previous_x := i64(-9223372036854775807 - 1)
    checksum := i64(0)
    for i := 0; i < query_count; i += 1 {
        x := values[cursor + i]
        if x < -1000 || x > 1000 || (i > 0 && x < previous_x) do return Invalid
        previous_x = x
        for front + 1 < hull_count && line_value(hull[front + 1], x) <= line_value(hull[front], x) { front += 1 }
        checksum += i64(i + 1) * line_value(hull[front], x)
    }
    return checksum
}
