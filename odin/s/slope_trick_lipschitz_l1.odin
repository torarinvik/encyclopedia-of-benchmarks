// Uncompiled and unexecuted two-heap slope-trick draft.
package slope_trick_lipschitz_l1
import "core:c"

push :: proc(heap: ^[128]i64, count: ^int, value: i64) {
    i := count^; count^ += 1
    for i > 0 {
        parent := (i-1)/2
        if heap[parent] >= value { break }
        heap[i] = heap[parent]; i = parent
    }
    heap[i] = value
}
replace :: proc(heap: ^[128]i64, count: int, value: i64) {
    i := 0
    for 2*i+1 < count {
        child := 2*i+1
        if child+1 < count && heap[child+1] > heap[child] { child += 1 }
        if heap[child] <= value { break }
        heap[i] = heap[child]; i = child
    }
    heap[i] = value
}
@(export)
slope_trick_lipschitz_l1 :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 130 { return -1 }
    if input[0] < 0 || input[0] > 128 || input[1] < 0 || input[1] > 100 { return -1 }
    n := int(input[0])
    if length != c.size_t(n+2) { return -1 }
    for i := 0; i < n; i += 1 { if input[2+i] < 0 || input[2+i] > 100 { return -1 } }
    left, right: [128]i64
    ln, rn := 0, 0
    shift_l, shift_r, answer := i64(0), i64(0), i64(0)
    for i := 0; i < n; i += 1 {
        shift_l -= input[1]; shift_r += input[1]
        push(&left, &ln, input[2+i]-shift_l)
        push(&right, &rn, shift_r-input[2+i])
        l, r := left[0]+shift_l, shift_r-right[0]
        if l > r {
            answer += l-r
            replace(&left, ln, r-shift_l)
            replace(&right, rn, shift_r-l)
        }
    }
    return answer
}
