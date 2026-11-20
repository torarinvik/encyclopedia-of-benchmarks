package brownian_tree_diffusion_limited_aggregation

import "core:c"

SIDE :: 33
MAX_POINTS :: 17
MAX_ATTEMPTS :: i64(16)
MAX_STEPS :: i64(512)
GOLDEN :: u64(0x9e3779b97f4a7c15)
MULTIPLIER :: u64(0x2545f4914f6cdd1d)

dla_next :: proc(state: ^u64) -> u64 {
    value := state^
    value ^= value >> 12
    value ^= value << 25
    value ^= value >> 27
    state^ = value
    return value * MULTIPLIER
}

dla_touches :: proc(occupied: [^]u8, x, y: int) -> bool {
    at := y * SIDE + x
    return occupied[at - 1] != 0 || occupied[at - SIDE] != 0 ||
        occupied[at + 1] != 0 || occupied[at + SIDE] != 0
}

dla_store_i64 :: proc(output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
brownian_tree_diffusion_limited_aggregation :: proc "c" (
    input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length != 3 do return -1
    attempts_value, seed_value, steps_value := input[0], input[1], input[2]
    if attempts_value < 0 || attempts_value > MAX_ATTEMPTS || seed_value < 1 ||
        steps_value < 1 || steps_value > MAX_STEPS do return -1

    occupied: [SIDE * SIDE]u8
    point_x: [MAX_POINTS]i32
    point_y: [MAX_POINTS]i32
    for cell := 0; cell < SIDE * SIDE; cell += 1 { occupied[cell] = 0 }
    point_x[0] = 16
    point_y[0] = 16
    point_count := 1
    occupied[16 * SIDE + 16] = 1

    for attempt := 0; attempt < int(attempts_value); attempt += 1 {
        state := u64(seed_value) ^ (GOLDEN * u64(attempt + 1))
        if state == 0 do state = MULTIPLIER
        side_draw := dla_next(&state)
        position_draw := dla_next(&state)
        launch_side := side_draw % 4
        position := 1 + int(position_draw % 31)
        x, y: int
        if launch_side == 0 { x, y = position, 1 }
        else if launch_side == 1 { x, y = 31, position }
        else if launch_side == 2 { x, y = position, 31 }
        else { x, y = 1, position }

        at := y * SIDE + x
        if occupied[at] != 0 do continue
        if dla_touches(&occupied[0], x, y) {
            occupied[at] = 1
            point_x[point_count] = i32(x)
            point_y[point_count] = i32(y)
            point_count += 1
            continue
        }
        for step := 0; step < int(steps_value); step += 1 {
            direction := dla_next(&state) % 4
            if direction == 0 do x -= 1
            else if direction == 1 do y -= 1
            else if direction == 2 do x += 1
            else do y += 1
            if x == 0 || x == 32 || y == 0 || y == 32 do break
            at = y * SIDE + x
            if dla_touches(&occupied[0], x, y) {
                occupied[at] = 1
                point_x[point_count] = i32(x)
                point_y[point_count] = i32(y)
                point_count += 1
                break
            }
        }
    }

    required := (1 + 2 * point_count) * 8
    if output == nil || capacity < c.size_t(required) do return -2
    dla_store_i64(output, 0, i64(point_count))
    for point := 0; point < point_count; point += 1 {
        dla_store_i64(output, (1 + 2 * point) * 8, i64(point_x[point]))
        dla_store_i64(output, (2 + 2 * point) * 8, i64(point_y[point]))
    }
    return i64(required)
}
