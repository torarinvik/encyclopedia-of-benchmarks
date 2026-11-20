package polygon_area_centroid

import "core:c"

MAX_VERTICES :: 16
MAX_PARSEABLE_LENGTH :: 34
SCALE :: i64(1_000_000)

rounded_micro :: proc "contextless" (numerator_input, denominator_input: i64) -> i64 {
    numerator := numerator_input
    denominator := denominator_input
    if denominator < 0 { numerator = -numerator; denominator = -denominator }
    sign := i64(1)
    if numerator < 0 { sign = -1 }
    magnitude := u64(if numerator < 0 { -numerator } else { numerator })
    scaled := magnitude * u64(SCALE)
    divisor := u64(denominator)
    quotient := scaled / divisor
    if 2 * (scaled % divisor) >= divisor { quotient += 1 }
    return sign * i64(quotient)
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
polygon_area_centroid :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 7 || length > c.size_t(MAX_PARSEABLE_LENGTH) do return -1
    count_value := input[0]
    if count_value < 3 || count_value > MAX_VERTICES do return -1
    count := int(count_value)
    if length != c.size_t(1 + 2 * count) do return -1

    xs: [MAX_VERTICES]i64
    ys: [MAX_VERTICES]i64
    for i := 0; i < count; i += 1 {
        x, y := input[1 + 2 * i], input[2 + 2 * i]
        if x < -50 || x > 50 || y < -50 || y > 50 do return -1
        for j := 0; j < i; j += 1 { if xs[j] == x && ys[j] == y do return -1 }
        xs[i], ys[i] = x, y
    }

    twice_area: i64 = 0
    for i := 0; i < count; i += 1 {
        next := (i + 1) % count
        twice_area += xs[i] * ys[next] - xs[next] * ys[i]
    }
    if twice_area == 0 do return -1
    orientation := i64(1)
    if twice_area < 0 { orientation = -1 }
    for i := 0; i < count; i += 1 {
        next := (i + 1) % count
        for j := 0; j < count; j += 1 {
            if j == i || j == next do continue
            side := (xs[next] - xs[i]) * (ys[j] - ys[i]) - (ys[next] - ys[i]) * (xs[j] - xs[i])
            if side * orientation <= 0 do return -1
        }
    }

    numerator_x, numerator_y: i64 = 0, 0
    for i := 0; i < count; i += 1 {
        next := (i + 1) % count
        cross := xs[i] * ys[next] - xs[next] * ys[i]
        numerator_x += (xs[i] + xs[next]) * cross
        numerator_y += (ys[i] + ys[next]) * cross
    }
    x_micro := rounded_micro(numerator_x, 3 * twice_area)
    y_micro := rounded_micro(numerator_y, 3 * twice_area)
    if output == nil || capacity < 16 do return -2
    store_i64_le(output, 0, x_micro)
    store_i64_le(output, 8, y_micro)
    return 16
}
