module print_amatrix_in_spiral_order

fn mix(h u32, b u8) u32 { return (h ^ u32(b)) * 16777619 }
fn feed(mut h u32, x u32) u32 {
    for shift in [u32(0), 8, 16, 24] { h = mix(h, u8(x >> shift)) }
    return h
}

@[export: 'print_amatrix_in_spiral_order']
pub fn print_amatrix_in_spiral_order(v &i64, n usize) i64 {
    if isnil(v) || n < 3 || n > 66 || v[0] < 1 || v[0] > 8 || v[1] < 1 || v[1] > 8 || n != 2 + usize(v[0] * v[1]) { return -1 }
    rows, cols := int(v[0]), int(v[1])
    for i := 2; i < n; i++ { if v[i] < -2147483648 || v[i] > 2147483647 { return -1 } }
    mut top := 0
    mut bottom := rows - 1
    mut left := 0
    mut right := cols - 1
    mut h := u32(2166136261)
    for top <= bottom && left <= right {
        for c := left; c <= right; c++ { h = feed(h, u32(i32(v[2 + top * cols + c]))) }
        top++
        for r := top; r <= bottom; r++ { h = feed(h, u32(i32(v[2 + r * cols + right]))) }
        if right == 0 { break }
        right--
        if top <= bottom {
            for c := right; c >= left; c-- { h = feed(h, u32(i32(v[2 + bottom * cols + c]))) }
            if bottom == 0 { break }
            bottom--
        }
        if left <= right {
            for r := bottom; r >= top; r-- { h = feed(h, u32(i32(v[2 + r * cols + left]))) }
            left++
        }
    }
    return i64(h)
}
