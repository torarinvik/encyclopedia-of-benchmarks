package chord_stabilization_trace
import "core:c"

chord_between :: proc(ids: [16]int, ring, left, item, right: int) -> bool {
    distance := (ids[item]-ids[left]+ring)%ring
    span := (ids[right]-ids[left]+ring)%ring
    return distance > 0 && (span == 0 || distance < span)
}
@(export)
chord_stabilization_trace :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 6 || length > 115 do return -1
    if input[0] < 1 || input[0] > 6 || input[1] < 1 || input[1] > 16 || input[2] < 0 || input[2] > 64 do return -1
    ring := 1 << uint(input[0]); n, q := int(input[1]), int(input[2])
    if n > ring || length != c.size_t(3+3*n+q) do return -1
    ids, succ, pred: [16]int
    for i := 0; i < n; i += 1 {
        if input[3+i] < 0 || input[3+i] >= i64(ring) do return -1
        if i > 0 && input[3+i] <= i64(ids[i-1]) do return -1
        if input[3+n+i] < 0 || input[3+n+i] >= i64(n) || input[3+2*n+i] < -1 || input[3+2*n+i] >= i64(n) do return -1
        ids[i] = int(input[3+i]); succ[i] = int(input[3+n+i]); pred[i] = int(input[3+2*n+i])
    }
    for i := 0; i < q; i += 1 do if input[3+3*n+i] < 0 || input[3+3*n+i] >= i64(n) do return -1
    for i := 0; i < q; i += 1 {
        node := int(input[3+3*n+i]); candidate := pred[succ[node]]
        if candidate >= 0 && chord_between(ids, ring, node, candidate, succ[node]) do succ[node] = candidate
        receiver := succ[node]
        if pred[receiver] < 0 || chord_between(ids, ring, pred[receiver], node, receiver) do pred[receiver] = node
    }
    if output == nil || capacity < c.size_t(2*n) do return -2
    for i := 0; i < n; i += 1 {
        output[i] = u8(succ[i]); output[n+i] = 255
        if pred[i] >= 0 do output[n+i] = u8(pred[i])
    }
    return i64(2*n)
}
