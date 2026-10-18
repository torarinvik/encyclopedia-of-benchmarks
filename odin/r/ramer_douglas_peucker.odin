package ramer_douglas_peucker

import "core:c"
import "core:math"

MAX_POINTS :: 12
MAX_OUTPUT :: 25

@(export)
ramer_douglas_peucker :: proc "c" (input: [^]f64, input_length: c.size_t,
    output: [^]f64, capacity: c.size_t) -> i64 {
    if input == nil || input_length < 2 || input_length > 26 do return -1
    if !math.is_finite(input[0]) || input[0] < 0 || input[0] > 12 || math.trunc(input[0]) != input[0] do return -1
    n := int(input[0])
    epsilon := input[1]
    if input_length != c.size_t(2 + 2*n) || !math.is_finite(epsilon) || epsilon < 0 || epsilon > 100 do return -1
    xs, ys: [MAX_POINTS]f64
    for i in 0..<n {
        xs[i] = input[2+2*i]
        ys[i] = input[3+2*i]
        if !math.is_finite(xs[i]) || !math.is_finite(ys[i]) || math.abs(xs[i]) > 100 || math.abs(ys[i]) > 100 do return -1
    }
    if n >= 3 {
        for i in 0..<n {
            for j in i+1..<n {
                if xs[i] == xs[j] && ys[i] == ys[j] do return -1
                dx, dy := xs[j]-xs[i], ys[j]-ys[i]
                length_squared := dx*dx + dy*dy
                line_length := math.sqrt_f64(length_squared)
                if !math.is_finite(length_squared) || length_squared <= 0 || !math.is_finite(line_length) || line_length <= 0 do return -1
                max_clamped, max_line: f64 = 0, 0
                index_clamped, index_line := i, i
                for k in i+1..<j {
                    px, py := xs[k], ys[k]
                    t := ((px-xs[i])*dx + (py-ys[i])*dy) / length_squared
                    if t < 0 || t > 1 do return -1
                    nearest_x, nearest_y := xs[i]+t*dx, ys[i]+t*dy
                    clamped_distance := math.hypot_f64(px-nearest_x, py-nearest_y)
                    numerator := dy*px - dx*py + xs[j]*ys[i] - ys[j]*xs[i]
                    line_distance := math.abs(numerator) / line_length
                    if !math.is_finite(clamped_distance) || !math.is_finite(line_distance) do return -1
                    if clamped_distance > max_clamped { max_clamped = clamped_distance; index_clamped = k }
                    if line_distance > max_line { max_line = line_distance; index_line = k }
                }
                if index_clamped != index_line || (max_clamped > epsilon) != (max_line > epsilon) do return -1
            }
        }
    }
    keep: [MAX_POINTS]bool
    if n > 0 do keep[0] = true
    if n > 1 do keep[n-1] = true
    if n >= 3 {
        starts, finishes: [24]int
        top := 1
        starts[0], finishes[0] = 0, n-1
        for top > 0 {
            top -= 1
            start, finish := starts[top], finishes[top]
            dx, dy := xs[finish]-xs[start], ys[finish]-ys[start]
            length_squared := dx*dx + dy*dy
            max_distance: f64 = 0
            max_index := start
            for k in start+1..<finish {
                t := ((xs[k]-xs[start])*dx + (ys[k]-ys[start])*dy) / length_squared
                nearest_x, nearest_y := xs[start]+t*dx, ys[start]+t*dy
                ddx, ddy := xs[k]-nearest_x, ys[k]-nearest_y
                distance := math.hypot_f64(ddx, ddy)
                if distance > max_distance { max_distance = distance; max_index = k }
            }
            if max_distance > epsilon {
                keep[max_index] = true
                starts[top], finishes[top] = start, max_index
                top += 1
                starts[top], finishes[top] = max_index, finish
                top += 1
            }
        }
    }
    staged: [MAX_OUTPUT]f64
    result_count := 0
    for i in 0..<n {
        if keep[i] {
            staged[1+2*result_count] = xs[i]
            staged[2+2*result_count] = ys[i]
            result_count += 1
        }
    }
    staged[0] = f64(result_count)
    output_size := 1 + 2*result_count
    if output == nil || capacity < c.size_t(output_size) do return -2
    for i in 0..<output_size { output[i] = staged[i] }
    return i64(output_size)
}
