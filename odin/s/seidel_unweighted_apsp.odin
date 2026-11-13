package seidel_unweighted_apsp

import "core:c"

Matrix :: [8][8]i64

distances :: proc(adjacency: Matrix, n: int) -> Matrix {
    squared, expanded, result: Matrix
    degree: [8]i64
    complete := true
    for i := 0; i < n; i += 1 {
        for j := 0; j < n; j += 1 {
            degree[i] += adjacency[i][j]
            if i != j && adjacency[i][j] == 0 do complete = false
            for k := 0; k < n; k += 1 do squared[i][j] += adjacency[i][k] * adjacency[k][j]
        }
    }
    if complete {
        for i := 0; i < n; i += 1 {
            for j := 0; j < n; j += 1 { if i != j do result[i][j] = 1 }
        }
        return result
    }
    for i := 0; i < n; i += 1 {
        for j := 0; j < n; j += 1 {
            if i != j && (adjacency[i][j] != 0 || squared[i][j] != 0) do expanded[i][j] = 1
        }
    }
    coarse := distances(expanded, n)
    for i := 0; i < n; i += 1 {
        for j := 0; j < n; j += 1 {
            if i == j do continue
            neighbor_sum := i64(0)
            for k := 0; k < n; k += 1 do neighbor_sum += coarse[i][k] * adjacency[k][j]
            result[i][j] = 2 * coarse[i][j]
            if neighbor_sum < coarse[i][j] * degree[j] do result[i][j] -= 1
        }
    }
    return result
}

@(export)
seidel_unweighted_apsp :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 66 do return -1
    if input[0] < 1 || input[0] > 8 do return -1
    n := int(input[0])
    if length != c.size_t(1 + n * n) do return -1
    adjacency: Matrix
    for i := 0; i < n; i += 1 {
        for j := 0; j < n; j += 1 {
            value := input[1 + i * n + j]
            if value < 0 || value > 1 || (i == j && value != 0) do return -1
            adjacency[i][j] = value
        }
    }
    for i := 0; i < n; i += 1 {
        for j := 0; j < i; j += 1 { if adjacency[i][j] != adjacency[j][i] do return -1 }
    }
    seen: [8]bool
    queue: [8]int
    seen[0] = true
    head, tail := 0, 1
    for head < tail {
        vertex := queue[head]
        head += 1
        for other := 0; other < n; other += 1 {
            if adjacency[vertex][other] != 0 && !seen[other] {
                seen[other] = true
                queue[tail] = other
                tail += 1
            }
        }
    }
    if tail != n do return -1
    bytes := 8 * n * n
    if output == nil || capacity < c.size_t(bytes) do return -2
    result := distances(adjacency, n)
    for i := 0; i < n; i += 1 {
        for j := 0; j < n; j += 1 {
            bits := u64(result[i][j])
            for byte := 0; byte < 8; byte += 1 {
                output[8 * (i * n + j) + byte] = u8(bits & 255)
                bits >>= 8
            }
        }
    }
    return i64(bytes)
}
