package page_rank

import "core:c"
import "core:math"

MAX_NODES :: 4

@(export)
page_rank :: proc "c" (input: [^]f64, input_length: c.size_t,
    output: [^]f64, capacity: c.size_t) -> i64 {
    if input == nil || input_length < 6 || input_length > 18 do return -1
    for i in 0..<2 {
        if !math.is_finite(input[i]) || math.trunc(input[i]) != input[i] do return -1
    }
    if input[0] < 2 || input[0] > 4 || input[1] < 0 || input[1] > 8 do return -1
    nodes, iterations := int(input[0]), int(input[1])
    if input_length != c.size_t(2+nodes*nodes) do return -1
    matrix: [16]u8
    degrees: [MAX_NODES]int
    for row in 0..<nodes {
        for column in 0..<nodes {
            value := input[2+row*nodes+column]
            if !math.is_finite(value) || (value != 0 && value != 1) || (row == column && value != 0) do return -1
            matrix[row*nodes+column] = u8(value)
            degrees[row] += int(matrix[row*nodes+column])
        }
    }
    ranks: [MAX_NODES]f64
    for i in 0..<nodes { ranks[i] = 1.0/f64(nodes) }
    for iteration in 0..<iterations {
        dangling_sum: f64 = 0
        for source in 0..<nodes {
            if degrees[source] == 0 { dangling_sum += ranks[source] }
        }
        dangling_share := (dangling_sum*0.5)/f64(nodes)
        baseline := 0.5/f64(nodes) + dangling_share
        next: [MAX_NODES]f64
        for target in 0..<nodes {
            incoming: f64 = 0
            for source in 0..<nodes {
                if matrix[source*nodes+target] == 1 {
                    incoming += ranks[source]/f64(degrees[source])
                }
            }
            next[target] = baseline + incoming*0.5
        }
        ranks = next
    }
    if output == nil || capacity < c.size_t(nodes) do return -2
    for i in 0..<nodes { output[i] = ranks[i] }
    return i64(nodes)
}
