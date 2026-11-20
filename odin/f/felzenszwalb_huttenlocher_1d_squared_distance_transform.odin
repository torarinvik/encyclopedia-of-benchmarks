package felzenszwalb_huttenlocher_1d_squared_distance_transform
import "core:c"

MAX_SITES :: 128
MAX_INPUT_WORDS :: 130
SENTINEL :: i64(-4611686018427387904)

floor_div :: proc(numerator, denominator: i64) -> i64 {
    quotient := numerator / denominator
    remainder := numerator % denominator
    if remainder != 0 && numerator < 0 { quotient -= 1 }
    return quotient
}

store_i64_le :: proc(output: [^]u8, word: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[word*8+byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
felzenszwalb_huttenlocher_1d_squared_distance_transform :: proc "c" (
    input: [^]i64, length: c.size_t, output: [^]u8,
    output_capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT_WORDS do return -1
    n64 := input[0]
    if n64 < 1 || n64 > MAX_SITES do return -1
    n := int(n64)
    if int(length) != n + 1 do return -1
    for i := 0; i < n; i += 1 {
        cost := input[i+1]
        if cost < 0 || cost > 1000000 do return -1
    }
    if output == nil || output_capacity < c.size_t(n*16) do return -2

    sites: [MAX_SITES]int
    starts: [MAX_SITES]i64
    top := 0
    sites[0] = 0
    starts[0] = SENTINEL
    for q := 1; q < n; q += 1 {
        for {
            p := sites[top]
            numerator := input[q+1] + i64(q*q) - input[p+1] - i64(p*p)
            denominator := i64(2*(q-p))
            first := floor_div(numerator, denominator) + 1
            if top == 0 || first > starts[top] {
                top += 1
                sites[top] = q
                starts[top] = first
                break
            }
            top -= 1
        }
    }

    active := 0
    for x := 0; x < n; x += 1 {
        for active < top && starts[active+1] <= i64(x) { active += 1 }
        site := sites[active]
        delta := i64(x-site)
        distance := delta*delta + input[site+1]
        store_i64_le(output, 2*x, distance)
        store_i64_le(output, 2*x+1, i64(site))
    }
    return i64(n*16)
}
