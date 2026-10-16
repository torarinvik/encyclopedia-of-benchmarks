package correlation_matrix_analysis

import "core:c"
import "core:math"

OBSERVATIONS :: 4
MAX_VARIABLES :: 5
MAX_PAIRS :: 10
MAX_OUTPUT_BYTES :: 848

put_f64_le :: proc "contextless" (output: [^]u8, offset: int, value: f64) {
    bits := transmute(u64)value
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits >> u64(8 * byte))
    }
}

put_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := transmute(u64)value
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits >> u64(8 * byte))
    }
}

@(export)
correlation_matrix_analysis :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 22 do return -1
    if input[0] != OBSERVATIONS || input[1] < 2 || input[1] > MAX_VARIABLES do return -1
    p := int(input[1])
    if length != c.size_t(2 + OBSERVATIONS * p) do return -1
    for index := 0; index < OBSERVATIONS * p; index += 1 {
        if input[2 + index] < -1000 || input[2 + index] > 1000 do return -1
    }
    for column := 0; column < p; column += 1 {
        first := input[2 + column]
        varying := false
        for row := 1; row < OBSERVATIONS; row += 1 {
            if input[2 + row * p + column] != first do varying = true
        }
        if !varying do return -1
    }
    output_bytes := 32 * p * p + 48
    if output == nil || capacity < c.size_t(output_bytes) do return -2

    means: [MAX_VARIABLES]f64 = {}
    correlation: [MAX_VARIABLES * MAX_VARIABLES]f64 = {}
    raw: [MAX_VARIABLES * MAX_VARIABLES]f64 = {}
    bonf: [MAX_VARIABLES * MAX_VARIABLES]f64 = {}
    fdr: [MAX_VARIABLES * MAX_VARIABLES]f64 = {}
    for column := 0; column < p; column += 1 {
        for row := 0; row < OBSERVATIONS; row += 1 {
            means[column] += f64(input[2 + row * p + column])
        }
        means[column] /= f64(OBSERVATIONS)
    }
    for index := 0; index < p * p; index += 1 {
        raw[index] = 1.0
        bonf[index] = 1.0
        fdr[index] = 1.0
    }
    for index := 0; index < p; index += 1 do correlation[index * p + index] = 1.0

    pair_i: [MAX_PAIRS]int = {}
    pair_j: [MAX_PAIRS]int = {}
    pair_p: [MAX_PAIRS]f64 = {}
    pair_count := 0
    for j := 1; j < p; j += 1 {
        for i := 0; i < j; i += 1 {
            cross: f64 = 0.0
            sum_i: f64 = 0.0
            sum_j: f64 = 0.0
            for row := 0; row < OBSERVATIONS; row += 1 {
                dx := f64(input[2 + row * p + i]) - means[i]
                dy := f64(input[2 + row * p + j]) - means[j]
                cross += dx * dy
                sum_i += dx * dx
                sum_j += dy * dy
            }
            r := cross / math.sqrt(sum_i * sum_j)
            pv := 1.0 - math.abs(r)
            correlation[i * p + j] = r
            correlation[j * p + i] = r
            raw[i * p + j] = pv
            raw[j * p + i] = pv
            pair_i[pair_count] = i
            pair_j[pair_count] = j
            pair_p[pair_count] = pv
            pair_count += 1
        }
    }
    for k := 0; k < pair_count; k += 1 {
        adjusted := pair_p[k] * f64(pair_count)
        if adjusted > 1.0 do adjusted = 1.0
        i := pair_i[k]
        j := pair_j[k]
        bonf[i * p + j] = adjusted
        bonf[j * p + i] = adjusted
    }
    order: [MAX_PAIRS]int = {}
    for k := 0; k < pair_count; k += 1 do order[k] = k
    for k := 1; k < pair_count; k += 1 {
        value := order[k]
        at := k
        for at > 0 && pair_p[order[at - 1]] > pair_p[value] {
            order[at] = order[at - 1]
            at -= 1
        }
        order[at] = value
    }
    running := 1.0
    for position := pair_count - 1; position >= 0; position -= 1 {
        adjusted := pair_p[order[position]] * f64(pair_count) / f64(position + 1)
        if adjusted > 1.0 do adjusted = 1.0
        if adjusted < running do running = adjusted
        k := order[position]
        i := pair_i[k]
        j := pair_j[k]
        fdr[i * p + j] = running
        fdr[j * p + i] = running
    }
    sig_raw: i64 = 0
    sig_bonf: i64 = 0
    sig_fdr: i64 = 0
    for k := 0; k < pair_count; k += 1 {
        i := pair_i[k]
        j := pair_j[k]
        if pair_p[k] < 0.05 do sig_raw += 1
        if bonf[i * p + j] < 0.05 do sig_bonf += 1
        if fdr[i * p + j] < 0.05 do sig_fdr += 1
    }
    offset := 0
    for index := 0; index < p * p; index += 1 { put_f64_le(output, offset, correlation[index]); offset += 8 }
    for index := 0; index < p * p; index += 1 { put_f64_le(output, offset, raw[index]); offset += 8 }
    for index := 0; index < p * p; index += 1 { put_f64_le(output, offset, bonf[index]); offset += 8 }
    for index := 0; index < p * p; index += 1 { put_f64_le(output, offset, fdr[index]); offset += 8 }
    for value in [i64(OBSERVATIONS), i64(p), 0, sig_raw, sig_bonf, sig_fdr] {
        put_i64_le(output, offset, value)
        offset += 8
    }
    return i64(offset)
}
