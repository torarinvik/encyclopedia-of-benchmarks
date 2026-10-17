package simultaneous_linear_equation_solver

import "core:c"
import "core:math"

MAX_EQUATIONS :: 5
MAX_INPUT_LENGTH :: 31
MAX_OUTPUT_BYTES :: 48
HALF_STEP_LIMIT :: 4.503599627370496e15
MAX_TICK_MAGNITUDE :: i64(2251799813685248)

write_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export, link_name="simultaneous_linear_equation_solver")
simultaneous_linear_equation_solver :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
    n_value := input[0]
    if n_value < 1 || n_value > MAX_EQUATIONS do return -1
    n := int(n_value)
    if int(length) != 1 + n * (n + 1) do return -1

    matrix: [30]f64
    has_zero := false
    for row := 0; row < n; row += 1 {
        for col := 0; col <= n; col += 1 {
            raw := input[1 + row * (n + 1) + col]
            if raw < -100000 || raw > 100000 do return -1
            matrix[row * 6 + col] = f64(raw) / 1000.0
            has_zero = has_zero || raw == 0
        }
    }

    if n == 1 {
        if matrix[0] == 0 do return -1
    } else {
        if has_zero {
            full_row := n
            for row := 0; row < n; row += 1 {
                all_nonzero := true
                for col := 0; col <= n; col += 1 {
                    if matrix[row * 6 + col] == 0 do all_nonzero = false
                }
                if all_nonzero { full_row = row; break }
            }
            if full_row == n do return -1
            if full_row != 0 {
                for col := 0; col <= n; col += 1 {
                    saved := matrix[full_row * 6 + col]
                    for row := full_row; row > 0; row -= 1 {
                        matrix[row * 6 + col] = matrix[(row - 1) * 6 + col]
                    }
                    matrix[col] = saved
                }
            }
        }

        for level := 0; level + 2 <= n; level += 1 {
            if matrix[level * 6 + level] == 0 do return -1
            for row := level; row < n; row += 1 {
                magnitude := matrix[row * 6 + level]
                if magnitude != 0 {
                    for col := level; col <= n; col += 1 {
                        matrix[row * 6 + col] /= magnitude
                    }
                }
            }
            first_row: [6]f64
            for col := level; col <= n; col += 1 { first_row[col] = matrix[level * 6 + col] }
            for row := level + 1; row < n; row += 1 {
                if matrix[row * 6 + level] != 0 {
                    for col := level; col <= n; col += 1 {
                        matrix[row * 6 + col] = first_row[col] - matrix[row * 6 + col]
                    }
                }
            }
        }
    }

    for row := 0; row < n; row += 1 {
        for col := row; col <= n; col += 1 {
            value := matrix[row * 6 + col]
            if value != value || value >= 1.7976931348623157e308 || value <= -1.7976931348623157e308 do return -1
        }
    }
    solutions: [5]f64
    for row := n - 1; row >= 0; row -= 1 {
        if matrix[row * 6 + row] == 0 do return -1
        value := matrix[row * 6 + n]
        for col := row + 1; col < n; col += 1 { value -= matrix[row * 6 + col] * solutions[col] }
        value /= matrix[row * 6 + row]
        if value != value || value >= 1.7976931348623157e308 || value <= -1.7976931348623157e308 do return -1
        solutions[row] = value
    }

    buffer: [MAX_OUTPUT_BYTES]u8
    write_i64_le(buffer[:], 0, n_value)
    for row := 0; row < n; row += 1 {
        scaled := solutions[row] * 100000.0
        if scaled != scaled || scaled <= -HALF_STEP_LIMIT || scaled >= HALF_STEP_LIMIT do return -1
        lower := math.floor(scaled)
        midpoint := lower + 0.5
        exact_side := math.fused_mul_add(solutions[row], 100000.0, -midpoint)
        if exact_side != exact_side || exact_side >= 1.7976931348623157e308 || exact_side <= -1.7976931348623157e308 do return -1
        rounded := i64(lower)
        if exact_side > 0 || (exact_side == 0 && rounded % 2 != 0) do rounded += 1
        if rounded < -MAX_TICK_MAGNITUDE || rounded > MAX_TICK_MAGNITUDE do return -1
        rounded_value := f64(rounded) / 100000.0
        projected := rounded_value * 100000.0
        if projected != projected || projected >= 1.7976931348623157e308 || projected <= -1.7976931348623157e308 do return -1
        projected_lower := math.floor(projected)
        projected_midpoint := projected_lower + 0.5
        ticks := i64(projected_lower)
        if projected > projected_midpoint || (projected == projected_midpoint && ticks % 2 != 0) do ticks += 1
        if ticks < -MAX_TICK_MAGNITUDE || ticks > MAX_TICK_MAGNITUDE do return -1
        write_i64_le(buffer[:], 8 + row * 8, ticks)
    }

    needed := 8 + 8 * n
    if output == nil || int(capacity) < needed do return -2
    for index := 0; index < needed; index += 1 { output[index] = buffer[index] }
    return i64(needed)
}
