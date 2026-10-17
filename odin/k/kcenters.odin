package kcenters

import "core:c"

@(export)
kcenters :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 2 || length > 66 do return -1
    point_count := values[0]
    center_count := values[1]
    if point_count < 1 || point_count > 8 || center_count < 1 || center_count > point_count do return -1
    if length != c.size_t(2 + point_count * point_count) do return -1
    for row := 0; row < int(point_count); row += 1 {
        for column := 0; column < int(point_count); column += 1 {
            distance := values[2 + row * int(point_count) + column]
            if distance < 0 || distance > 1_000_000 || (row == column && distance != 0) do return -1
            if distance != values[2 + column * int(point_count) + row] do return -1
        }
    }

    selected: [8]bool = {}
    max_distance: [8]i64
    for point := 0; point < int(point_count); point += 1 do max_distance[point] = 2_147_483_647
    selected[0] = true
    for point := 1; point < int(point_count); point += 1 {
        distance := values[2 + point]
        if distance < max_distance[point] do max_distance[point] = distance
    }
    for center := 1; center < int(center_count); center += 1 {
        farthest := -1
        for point := 0; point < int(point_count); point += 1 {
            if !selected[point] && (farthest == -1 || max_distance[point] > max_distance[farthest]) do farthest = point
        }
        selected[farthest] = true
        for point := 0; point < int(point_count); point += 1 {
            distance := values[2 + farthest * int(point_count) + point]
            if distance < max_distance[point] do max_distance[point] = distance
        }
    }
    result: i64 = 0
    for point := 0; point < int(point_count); point += 1 {
        if max_distance[point] > result do result = max_distance[point]
    }
    return result
}
