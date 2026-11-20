package zhang_suen_thinning

import "core:c"

MAX_ROWS :: 32
MAX_COLUMNS :: 32
MAX_CELLS :: 1024
MAX_PARSEABLE_INPUT_LENGTH :: 1027

thin_phase :: proc(image: []u8, marked: []u8, rows, columns: int,
        second_phase: bool) -> bool {
    cells := rows * columns
    for index := 0; index < cells; index += 1 {
        marked[index] = 0
    }
    changed := false
    for row := 1; row + 1 < rows; row += 1 {
        for column := 1; column + 1 < columns; column += 1 {
            index := row * columns + column
            if image[index] == 0 do continue
            p2 := image[index - columns]
            p3 := image[index - columns + 1]
            p4 := image[index + 1]
            p5 := image[index + columns + 1]
            p6 := image[index + columns]
            p7 := image[index + columns - 1]
            p8 := image[index - 1]
            p9 := image[index - columns - 1]
            ring := [9]u8{p2, p3, p4, p5, p6, p7, p8, p9, p2}
            black_neighbors := 0
            transitions := 0
            for neighbor := 0; neighbor < 8; neighbor += 1 {
                black_neighbors += int(ring[neighbor])
                if ring[neighbor] == 0 && ring[neighbor + 1] == 1 {
                    transitions += 1
                }
            }
            if black_neighbors < 2 || black_neighbors > 6 || transitions != 1 do continue
            blocked := false
            if second_phase {
                blocked = (p2 != 0 && p4 != 0 && p8 != 0) ||
                          (p2 != 0 && p6 != 0 && p8 != 0)
            } else {
                blocked = (p2 != 0 && p4 != 0 && p6 != 0) ||
                          (p4 != 0 && p6 != 0 && p8 != 0)
            }
            if blocked do continue
            marked[index] = 1
            changed = true
        }
    }
    if changed {
        for index := 0; index < cells; index += 1 {
            if marked[index] != 0 do image[index] = 0
        }
    }
    return changed
}

@(export)
zhang_suen_thinning :: proc "contextless" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
    rows_value := input[0]
    columns_value := input[1]
    if rows_value < 1 || rows_value > MAX_ROWS ||
        columns_value < 1 || columns_value > MAX_COLUMNS do return -1
    rows := int(rows_value)
    columns := int(columns_value)
    cells := rows * columns
    if length != c.size_t(2 + cells) do return -1
    for index := 0; index < cells; index += 1 {
        if input[index + 2] != 0 && input[index + 2] != 1 do return -1
    }
    if output == nil || output_capacity < c.size_t(cells) do return -2

    image: [MAX_CELLS]u8
    marked: [MAX_CELLS]u8
    for index := 0; index < cells; index += 1 {
        image[index] = u8(input[index + 2])
    }
    for {
        first_changed := thin_phase(image[:cells], marked[:cells], rows, columns, false)
        second_changed := thin_phase(image[:cells], marked[:cells], rows, columns, true)
        if !first_changed && !second_changed do break
    }
    for index := 0; index < cells; index += 1 {
        output[index] = image[index]
    }
    return i64(cells)
}
