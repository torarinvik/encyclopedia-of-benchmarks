package divide_conquer_tangent_hull

import "core:c"

// Unverified divide-and-conquer tangent-merge hull draft.
cross :: proc "contextless" (x, y: []i64, a, b, d: int) -> i64 {
    return (x[b]-x[a])*(y[d]-y[a]) - (y[b]-y[a])*(x[d]-x[a])
}

chain :: proc "contextless" (x, y: []i64, order, output: []int,
                             lo, hi, base: int, upper: bool) -> int {
    if hi-lo == 1 { output[base] = order[lo]; return 1 }
    middle := lo+(hi-lo)/2
    left_capacity := middle-lo
    left_n := chain(x, y, order, output, lo, middle, base, upper)
    right_n := chain(x, y, order, output, middle, hi, base+left_capacity, upper)
    i, j := left_n-1, 0
    changed := true
    for changed {
        changed = false
        for i > 0 {
            sign := cross(x, y, output[base+i], output[base+left_capacity+j], output[base+i-1])
            if (upper && sign <= 0) || (!upper && sign >= 0) do break
            i -= 1; changed = true
        }
        for j+1 < right_n {
            sign := cross(x, y, output[base+i], output[base+left_capacity+j], output[base+left_capacity+j+1])
            if (upper && sign <= 0) || (!upper && sign >= 0) do break
            j += 1; changed = true
        }
    }
    suffix := right_n-j
    for k := 0; k < suffix; k += 1 { output[base+i+1+k] = output[base+left_capacity+j+k] }
    return i+1+suffix
}

@(export)
divide_conquer_tangent_hull :: proc "c" (input: [^]i64, length: c.size_t,
                                        output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 7 || length > 66 || input[0] < 3 || input[0] > 32 do return -1
    n := int(input[0])
    if int(length) != 1+2*n do return -1
    x, y: [32]i64
    order, scratch: [32]int
    for i := 0; i < n; i += 1 {
        x[i] = input[1+2*i]; y[i] = input[2+2*i]
        if x[i] < -1000 || x[i] > 1000 || y[i] < -1000 || y[i] > 1000 do return -1
        for j := 0; j < i; j += 1 { if x[j] == x[i] do return -1 }
        order[i] = i
    }
    for i := 0; i < n; i += 1 {
        for j := i+1; j < n; j += 1 {
            for k := j+1; k < n; k += 1 { if cross(x[:], y[:], i, j, k) == 0 do return -1 }
        }
    }
    for width := 1; width < n; width *= 2 {
        for begin := 0; begin < n; begin += 2*width {
            middle := min(begin+width, n)
            end := min(begin+2*width, n)
            left, right, dest := begin, middle, begin
            for left < middle && right < end {
                if x[order[right]] < x[order[left]] { scratch[dest] = order[right]; right += 1
                } else { scratch[dest] = order[left]; left += 1 }
                dest += 1
            }
            for left < middle { scratch[dest] = order[left]; left += 1; dest += 1 }
            for right < end { scratch[dest] = order[right]; right += 1; dest += 1 }
        }
        for i := 0; i < n; i += 1 { order[i] = scratch[i] }
    }
    lower, upper, hull: [32]int
    lower_n := chain(x[:], y[:], order[:], lower[:], 0, n, 0, false)
    upper_n := chain(x[:], y[:], order[:], upper[:], 0, n, 0, true)
    count := 0
    for i := 0; i < lower_n; i += 1 { hull[count] = lower[i]; count += 1 }
    for i := upper_n-1; i > 1; { i -= 1; hull[count] = upper[i]; count += 1 }
    bytes := 16*count
    if output == nil || int(capacity) < bytes do return -2
    for i := 0; i < count; i += 1 {
        words := [2]u64{u64(x[hull[i]]), u64(y[hull[i]])}
        for axis := 0; axis < 2; axis += 1 {
            for b := 0; b < 8; b += 1 { output[16*i+8*axis+b] = u8(words[axis] >> u64(8*b)) }
        }
    }
    return i64(bytes)
}
