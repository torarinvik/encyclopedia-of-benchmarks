package multiprobe_lsh_probe_sequence

import "core:c"

mpls_key :: proc(mask: int, distances: ^[8]int, n: int) -> int {
    score, bits := 0, 0
    for i := 0; i < n; i += 1 do if mask & (1 << uint(i)) != 0 { score += distances[i]*distances[i]; bits += 1 }
    return score*2304 + bits*256 + mask
}
mpls_push :: proc(heap: ^[256]int, size, mask: int, distances: ^[8]int, n: int) -> int {
    at := size; key := mpls_key(mask, distances, n)
    for at > 0 && key < mpls_key(heap[(at-1)/2], distances, n) { heap[at] = heap[(at-1)/2]; at = (at-1)/2 }
    heap[at] = mask
    return size+1
}
mpls_pop :: proc(heap: ^[256]int, size: int, distances: ^[8]int, n: int) -> int {
    result := heap[0]; remaining := size-1; last := heap[remaining]; at := 0
    for 2*at+1 < remaining {
        child := 2*at+1
        if child+1 < remaining && mpls_key(heap[child+1], distances, n) < mpls_key(heap[child], distances, n) do child += 1
        if mpls_key(heap[child], distances, n) >= mpls_key(last, distances, n) do break
        heap[at] = heap[child]; at = child
    }
    if remaining > 0 do heap[at] = last
    return result
}
@(export)
multiprobe_lsh_probe_sequence :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 4 || length > 7 || input[0] < 1 || input[0] > 4 || input[1] < 1 || input[1] > 1000 do return -1
    m, width := int(input[0]), int(input[1]); limit := 1
    for i := 0; i < m; i += 1 do limit *= 3
    if length != c.size_t(3+m) || input[2] < 0 || input[2] >= i64(limit) do return -1
    count := int(input[2]); distances, coords, signs: [8]int
    for i := 0; i < m; i += 1 {
        if input[3+i] < 0 || input[3+i] > i64(width) do return -1
        distances[2*i] = int(input[3+i]); distances[2*i+1] = width-distances[2*i]
        coords[2*i] = i; coords[2*i+1] = i; signs[2*i] = -1; signs[2*i+1] = 1
    }
    for i := 1; i < 2*m; i += 1 {
        d, c, s, j := distances[i], coords[i], signs[i], i
        for j > 0 && (distances[j-1] > d || (distances[j-1] == d && (coords[j-1] > c || (coords[j-1] == c && signs[j-1] > s)))) {
            distances[j] = distances[j-1]; coords[j] = coords[j-1]; signs[j] = signs[j-1]; j -= 1
        }
        distances[j] = d; coords[j] = c; signs[j] = s
    }
    heap: [256]int; result: [80]u8
    size := mpls_push(&heap, 0, 1, &distances, 2*m); emitted := 0
    for emitted < count {
        mask := mpls_pop(&heap, size, &distances, 2*m); size -= 1; top := 0
        for (1 << uint(top+1)) <= mask do top += 1
        if top+1 < 2*m {
            size = mpls_push(&heap, size, (mask ~ (1 << uint(top))) | (1 << uint(top+1)), &distances, 2*m)
            size = mpls_push(&heap, size, mask | (1 << uint(top+1)), &distances, 2*m)
        }
        seen := 0; valid := true
        for i := 0; i < 2*m; i += 1 do if mask & (1 << uint(i)) != 0 {
            bit := 1 << uint(coords[i]); if seen & bit != 0 { valid = false; break }; seen |= bit
        }
        if valid { result[emitted] = u8(mask); emitted += 1 }
    }
    if output == nil || capacity < c.size_t(count) do return -2
    for i := 0; i < count; i += 1 do output[i] = result[i]
    return i64(count)
}
