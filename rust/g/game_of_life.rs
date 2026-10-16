/// Compute one finite, non-wrapping Conway Game of Life generation.
const MAX_SIDE: i64 = 32;

#[no_mangle]
pub unsafe extern "C" fn game_of_life(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if length == 0 || input.is_null() { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let side_value = values[0];
    if !(0..=MAX_SIDE).contains(&side_value) { return -1; }
    let side = side_value as usize;
    let cell_count = side * side;
    if length != cell_count + 1 || values[1..].iter().any(|&cell| cell != 0 && cell != 1) {
        return -1;
    }
    if output_capacity < cell_count || (cell_count != 0 && output.is_null()) { return -2; }

    for row in 0..side {
        for column in 0..side {
            let mut neighbors = 0;
            for row_delta in -1isize..=1 {
                for column_delta in -1isize..=1 {
                    if row_delta == 0 && column_delta == 0 { continue; }
                    let neighbor_row = row as isize + row_delta;
                    let neighbor_column = column as isize + column_delta;
                    if neighbor_row >= 0 && neighbor_row < side as isize &&
                        neighbor_column >= 0 && neighbor_column < side as isize &&
                        values[1 + neighbor_row as usize * side + neighbor_column as usize] == 1 {
                        neighbors += 1;
                    }
                }
            }
            let index = row * side + column;
            let alive = values[index + 1] == 1;
            *output.add(index) = u8::from((alive && (neighbors == 2 || neighbors == 3)) ||
                                           (!alive && neighbors == 3));
        }
    }
    cell_count as i64
}
