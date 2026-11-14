// Uncompiled and unexecuted Cartesian-tree histogram draft.
module cartesian_histogram_area
@[export: 'cartesian_histogram_area']
pub fn cartesian_histogram_area(heights &i64, length usize) i64 {
    unsafe {
        if length == 0 { return 0 }
        if heights == nil || length > 64 { return -9223372036854775807-1 }
        n := int(length)
        for i in 0 .. n { if heights[i] < 0 || heights[i] > 1000000 { return -9223372036854775807-1 } }
        mut left := [64]int{}
        mut right := [64]int{}
        mut stack := [64]int{}
        mut order := [64]int{}
        mut sizes := [64]int{}
        for i in 0 .. n { left[i] = n; right[i] = n }
        mut top := 0
        for i in 0 .. n {
            mut last := n
            for top > 0 && heights[stack[top-1]] > heights[i] { top--; last = stack[top] }
            if top > 0 { right[stack[top-1]] = i }
            left[i] = last; stack[top] = i; top++
        }
        root := stack[0]; top = 1; stack[0] = root
        mut used := 0
        for top > 0 {
            top--; node := stack[top]; order[used] = node; used++
            if left[node] < n { stack[top] = left[node]; top++ }
            if right[node] < n { stack[top] = right[node]; top++ }
        }
        mut best := i64(0)
        for used > 0 {
            used--; node := order[used]; sizes[node] = 1
            if left[node] < n { sizes[node] += sizes[left[node]] }
            if right[node] < n { sizes[node] += sizes[right[node]] }
            area := heights[node]*i64(sizes[node])
            if area > best { best = area }
        }
        return best
    }
}
