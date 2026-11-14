module divide_conquer_tangent_hull

// Unverified divide-and-conquer tangent-merge hull draft.
fn cross(x []i64, y []i64, a int, b int, c int) i64 {
    return (x[b]-x[a])*(y[c]-y[a]) - (y[b]-y[a])*(x[c]-x[a])
}
fn chain(x []i64, y []i64, order []int, lo int, hi int, upper bool) []int {
    if hi-lo == 1 { return [order[lo]] }
    middle := lo+(hi-lo)/2
    left := chain(x, y, order, lo, middle, upper)
    right := chain(x, y, order, middle, hi, upper)
    mut i := left.len-1
    mut j := 0
    mut changed := true
    for changed {
        changed = false
        for i > 0 {
            sign := cross(x, y, left[i], right[j], left[i-1])
            if (upper && sign <= 0) || (!upper && sign >= 0) { break }
            i--
            changed = true
        }
        for j+1 < right.len {
            sign := cross(x, y, left[i], right[j], right[j+1])
            if (upper && sign <= 0) || (!upper && sign >= 0) { break }
            j++
            changed = true
        }
    }
    mut merged := []int{cap: i+1+right.len-j}
    for k in 0 .. i+1 { merged << left[k] }
    for k in j .. right.len { merged << right[k] }
    return merged
}

@[export: 'divide_conquer_tangent_hull']
pub fn divide_conquer_tangent_hull(input &i64, length usize, mut output &u8, capacity usize) i64 {
    if unsafe { input == nil } || length < 7 || length > 66 { return -1 }
    unsafe {
        if input[0] < 3 || input[0] > 32 { return -1 }
        n := int(input[0])
        if length != usize(1+2*n) { return -1 }
        mut x := []i64{len: n}
        mut y := []i64{len: n}
        mut order := []int{len: n}
        mut scratch := []int{len: n}
        for i in 0 .. n {
            x[i] = input[1+2*i]
            y[i] = input[2+2*i]
            if x[i] < -1000 || x[i] > 1000 || y[i] < -1000 || y[i] > 1000 { return -1 }
            for j in 0 .. i { if x[i] == x[j] { return -1 } }
            order[i] = i
        }
        for i in 0 .. n { for j in i+1 .. n { for k in j+1 .. n {
            if cross(x, y, i, j, k) == 0 { return -1 }
        } } }
        mut width := 1
        for width < n {
            mut begin := 0
            for begin < n {
                middle := if begin+width < n { begin+width } else { n }
                end := if begin+2*width < n { begin+2*width } else { n }
                mut left := begin
                mut right := middle
                mut dest := begin
                for left < middle && right < end {
                    if x[order[right]] < x[order[left]] { scratch[dest] = order[right]; right++ }
                    else { scratch[dest] = order[left]; left++ }
                    dest++
                }
                for left < middle { scratch[dest] = order[left]; left++; dest++ }
                for right < end { scratch[dest] = order[right]; right++; dest++ }
                begin += 2*width
            }
            for i in 0 .. n { order[i] = scratch[i] }
            width *= 2
        }
        mut hull := chain(x, y, order, 0, n, false)
        upper := chain(x, y, order, 0, n, true)
        mut i := upper.len-1
        for i > 1 { i--; hull << upper[i] }
        bytes := 16*hull.len
        if output == nil || capacity < usize(bytes) { return -2 }
        for index, id in hull {
            words := [u64(x[id]), u64(y[id])]
            for axis in 0 .. 2 { for b in 0 .. 8 { output[16*index+8*axis+b] = u8(words[axis] >> (8*b)) } }
        }
        return i64(bytes)
    }
}
