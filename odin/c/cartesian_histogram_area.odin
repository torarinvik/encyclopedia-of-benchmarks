// Uncompiled and unexecuted Cartesian-tree histogram draft.
package cartesian_histogram_area
import "core:c"
@(export)
cartesian_histogram_area :: proc "c" (heights: [^]i64, length: c.size_t) -> i64 {
    if length == 0 { return 0 }
    if heights == nil || length > 64 { return -9223372036854775807-1 }
    n := int(length)
    for i := 0; i < n; i += 1 { if heights[i] < 0 || heights[i] > 1000000 { return -9223372036854775807-1 } }
    left, right, stack, order, sizes: [64]int
    for i := 0; i < n; i += 1 { left[i] = n; right[i] = n }
    top := 0
    for i := 0; i < n; i += 1 {
        last := n
        for top > 0 && heights[stack[top-1]] > heights[i] { top -= 1; last = stack[top] }
        if top > 0 { right[stack[top-1]] = i }
        left[i] = last; stack[top] = i; top += 1
    }
    root := stack[0]; top = 1; stack[0] = root
    used := 0
    for top > 0 {
        top -= 1; node := stack[top]; order[used] = node; used += 1
        if left[node] < n { stack[top] = left[node]; top += 1 }
        if right[node] < n { stack[top] = right[node]; top += 1 }
    }
    best := i64(0)
    for used > 0 {
        used -= 1; node := order[used]; sizes[node] = 1
        if left[node] < n { sizes[node] += sizes[left[node]] }
        if right[node] < n { sizes[node] += sizes[right[node]] }
        area := heights[node]*i64(sizes[node])
        if area > best { best = area }
    }
    return best
}
