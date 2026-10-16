// Count triangles whose strict interior contains the origin.
module problem102

const max_values = usize(6000)
const min_coord = i64(-1000)
const max_coord = i64(1000)

fn origin_inside(x1 i64, y1 i64, x2 i64, y2 i64, x3 i64, y3 i64) i64 {
    abx := x2 - x1
    aby := y2 - y1
    acx := x3 - x1
    acy := y3 - y1
    mut denominator := acx * aby - acy * abx
    mut numerator_a := -(x1 * aby - y1 * abx)
    mut numerator_b := x1 * acy - y1 * acx
    if denominator == 0 { return -1 }
    if denominator < 0 {
        denominator = -denominator
        numerator_a = -numerator_a
        numerator_b = -numerator_b
    }
    if numerator_a > 0 && numerator_b > 0 && numerator_a + numerator_b < denominator {
        return 1
    }
    return 0
}

@[export: 'problem102']
pub fn problem102(input &i64, length usize) i64 {
    if length < 6 || length > max_values || length % 6 != 0 { return -1 }
    for index in 0 .. length {
        value := unsafe { input[index] }
        if value < min_coord || value > max_coord { return -1 }
    }
    mut count := i64(0)
    mut offset := usize(0)
    for offset < length {
        inside := origin_inside(unsafe { input[offset] }, unsafe { input[offset + 1] },
                                unsafe { input[offset + 2] }, unsafe { input[offset + 3] },
                                unsafe { input[offset + 4] }, unsafe { input[offset + 5] })
        if inside < 0 { return -1 }
        count += inside
        offset += 6
    }
    return count
}
