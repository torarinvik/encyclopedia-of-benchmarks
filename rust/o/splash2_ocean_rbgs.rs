const MAX_CELLS: usize = 64;
const MAX_INPUT: usize = 132;

#[no_mangle]
pub unsafe extern "C" fn splash2_ocean_rbgs(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || !(3..=MAX_INPUT).contains(&input_length) {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    if values.iter().any(|value| !value.is_finite()) {
        return -1;
    }
    let side = match values[0] {
        4.0 => 4,
        6.0 => 6,
        8.0 => 8,
        _ => return -1,
    };
    let cells = side * side;
    if input_length != 3 + 2 * cells {
        return -1;
    }
    let eigenvalue_squared = values[1];
    let spacing = values[2];
    if !(0.0..=2.0).contains(&eigenvalue_squared) || !(0.125..=1.0).contains(&spacing) {
        return -1;
    }
    let factor = 4.0 - eigenvalue_squared * spacing * spacing;
    if !factor.is_finite() || factor <= 0.0 {
        return -1;
    }

    let mut grid = [0.0; MAX_CELLS];
    let mut rhs = [0.0; MAX_CELLS];
    for index in 0..cells {
        grid[index] = values[3 + index];
        rhs[index] = values[3 + cells + index];
        if !(-8.0..=8.0).contains(&grid[index]) || !(-8.0..=8.0).contains(&rhs[index]) {
            return -1;
        }
    }
    let needed = 1 + cells;
    if output.is_null() || output_capacity < needed {
        return -2;
    }

    let mut max_change = 0.0f64;
    for color in 0..2 {
        for row in 1..side - 1 {
            for column in 1..side - 1 {
                if (row + column) % 2 != color {
                    continue;
                }
                let index = row * side + column;
                let neighbors = grid[index + 1] + grid[index - 1]
                    + grid[index - side] + grid[index + side];
                let updated = (neighbors - rhs[index]) / factor;
                max_change = max_change.max((grid[index] - updated).abs());
                grid[index] = updated;
            }
        }
    }
    unsafe {
        *output = max_change;
        for index in 0..cells {
            *output.add(index + 1) = grid[index];
        }
    }
    needed as i64
}
