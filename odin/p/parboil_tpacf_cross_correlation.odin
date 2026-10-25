package parboil_tpacf_cross_correlation

import "core:c"
import "core:math"

NUM_BINS :: 20
MAX_POINTS :: 4
MAX_INPUT_LENGTH :: 26
PI_VALUE :: 3.141592653589793238462643383279502884

/* Parboil TPACF, Illinois Open Source License; see package LICENSE.txt. */
coordinate :: proc(input: [^]i64, offset: int) -> f32 {
    return f32(input[offset]) / 1_000_000.0
}

@(export)
parboil_tpacf_cross_correlation :: proc "c" (input: [^]i64, input_length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || input_length < 8 || input_length > MAX_INPUT_LENGTH do return -1
    data_value, random_value := input[0], input[1]
    if data_value < 1 || data_value > MAX_POINTS || random_value < 1 || random_value > MAX_POINTS do return -1
    data_count, random_count := int(data_value), int(random_value)
    if input_length != c.size_t(2 + 3 * (data_count + random_count)) do return -1
    for i := 2; i < int(input_length); i += 1 do if input[i] < -1_000_000 || input[i] > 1_000_000 do return -1
    if output == nil || output_capacity < NUM_BINS do return -2

    boundaries: [NUM_BINS + 1]f32 = {}
    for k := 0; k <= NUM_BINS; k += 1 {
        exponent := math.log10_f64(1.0) + f64(k) * 1.0 / 5.0
        arcminutes := math.pow_f64(10.0, exponent)
        radians := arcminutes / 60.0 * (PI_VALUE / 180.0)
        boundaries[k] = f32(math.cos_f64(radians))
    }
    histogram: [NUM_BINS]u8 = {}
    random_base := 2 + 3 * data_count
    for j := 0; j < random_count; j += 1 {
        rx := coordinate(input, random_base + 3*j)
        ry := coordinate(input, random_base + 3*j + 1)
        rz := coordinate(input, random_base + 3*j + 2)
        for i := 0; i < data_count; i += 1 {
            dx := coordinate(input, 2 + 3*i)
            dy := coordinate(input, 2 + 3*i + 1)
            dz := coordinate(input, 2 + 3*i + 2)
            px, py, pz := dx*rx, dy*ry, dz*rz
            xy := px + py
            distance := xy + pz
            min, max := 0, NUM_BINS
            for max > min + 1 {
                middle := (min + max) / 2
                if distance >= boundaries[middle] { max = middle } else { min = middle }
            }
            if distance < boundaries[min] && distance >= boundaries[max] do histogram[max-1] += 1
        }
    }
    for bin := 0; bin < NUM_BINS; bin += 1 do output[bin] = histogram[bin]
    return NUM_BINS
}
