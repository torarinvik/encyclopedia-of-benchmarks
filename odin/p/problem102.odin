// Count triangles whose strict interior contains the origin.
package problem102

import "core:c"

MAX_VALUES :: c.size_t(6000)
MIN_COORD :: i64(-1000)
MAX_COORD :: i64(1000)

origin_inside :: proc(x1, y1, x2, y2, x3, y3: i64) -> i64 {
    abx, aby := x2 - x1, y2 - y1
    acx, acy := x3 - x1, y3 - y1
    denominator := acx * aby - acy * abx
    numerator_a := -(x1 * aby - y1 * abx)
    numerator_b := x1 * acy - y1 * acx
    if denominator == 0 do return -1
    if denominator < 0 {
        denominator = -denominator
        numerator_a = -numerator_a
        numerator_b = -numerator_b
    }
    if numerator_a > 0 && numerator_b > 0 && numerator_a + numerator_b < denominator { return 1 }
    return 0
}

@(export)
problem102 :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < c.size_t(6) || length > MAX_VALUES || length % c.size_t(6) != 0 do return -1
    for index := c.size_t(0); index < length; index += 1 {
        if input[index] < MIN_COORD || input[index] > MAX_COORD do return -1
    }
    count: i64 = 0
    for offset := c.size_t(0); offset < length; offset += 6 {
        inside := origin_inside(input[offset], input[offset + 1], input[offset + 2],
                               input[offset + 3], input[offset + 4], input[offset + 5])
        if inside < 0 do return -1
        count += inside
    }
    return count
}
