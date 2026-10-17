const MAX_CELLS: usize = 256;
const MAX_INPUT_LENGTH: usize = 259;
const INVALID_RESULT: i64 = i64::MIN;

#[no_mangle]
pub unsafe extern "C" fn rotting_oranges(input: *const i64, length: usize) -> i64 {
    if input.is_null() {
        return if length == 0 { 0 } else { INVALID_RESULT };
    }
    if length == 0 { return 0; }
    if length < 2 || length > MAX_INPUT_LENGTH { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(input, length);
    let rows_value = values[0];
    let columns_value = values[1];
    if rows_value == 0 {
        return if columns_value == 0 && length == 2 { 0 } else { INVALID_RESULT };
    }
    if !(1..=16).contains(&rows_value) || !(0..=16).contains(&columns_value) {
        return INVALID_RESULT;
    }
    let rows = rows_value as usize;
    let columns = columns_value as usize;
    let cell_count = rows * columns;
    if length != 2 + cell_count { return INVALID_RESULT; }

    let mut cells = [0_u8; MAX_CELLS];
    let mut queue = [0_usize; MAX_CELLS];
    let mut distance = [0_u16; MAX_CELLS];
    let (mut head, mut tail, mut fresh, mut rotted) = (0usize, 0usize, 0usize, 0usize);
    for index in 0..cell_count {
        let value = values[2 + index];
        if !(0..=2).contains(&value) { return INVALID_RESULT; }
        cells[index] = value as u8;
        if value == 1 { fresh += 1; }
        if value == 2 {
            queue[tail] = index;
            tail += 1;
        }
    }
    if columns == 0 || fresh == 0 { return 0; }

    let mut minutes = 0_u16;
    while head < tail {
        let index = queue[head];
        head += 1;
        let row = index / columns;
        let column = index % columns;
        let next_distance = distance[index] + 1;
        let mut neighbors = [0usize; 4];
        let mut neighbor_count = 0usize;
        if row > 0 { neighbors[neighbor_count] = index - columns; neighbor_count += 1; }
        if column + 1 < columns { neighbors[neighbor_count] = index + 1; neighbor_count += 1; }
        if row + 1 < rows { neighbors[neighbor_count] = index + columns; neighbor_count += 1; }
        if column > 0 { neighbors[neighbor_count] = index - 1; neighbor_count += 1; }
        for offset in 0..neighbor_count {
            let next = neighbors[offset];
            if cells[next] != 1 { continue; }
            cells[next] = 2;
            distance[next] = next_distance;
            minutes = minutes.max(next_distance);
            rotted += 1;
            queue[tail] = next;
            tail += 1;
        }
    }
    if rotted == fresh { i64::from(minutes) } else { -1 }
}
