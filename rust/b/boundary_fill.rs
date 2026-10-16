const MAX_SIDE: usize = 32;
const MAX_CELLS: usize = MAX_SIDE * MAX_SIDE;

fn put_i64(output: &mut [u8], index: usize, value: i64) {
    output[index * 8..index * 8 + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub extern "C" fn boundary_fill(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 6 || length > 6 + MAX_CELLS { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    let width_value = input[0];
    let height_value = input[1];
    let start_x_value = input[2];
    let start_y_value = input[3];
    let new_color = input[4];
    let boundary_color = input[5];
    if !(1..=MAX_SIDE as i64).contains(&width_value)
        || !(1..=MAX_SIDE as i64).contains(&height_value)
        || !(i32::MIN as i64..=i32::MAX as i64).contains(&new_color)
        || !(i32::MIN as i64..=i32::MAX as i64).contains(&boundary_color) { return -1; }
    let width = width_value as usize;
    let height = height_value as usize;
    if length != 6 + width * height || start_x_value < 0 || start_x_value >= width_value
        || start_y_value < 0 || start_y_value >= height_value { return -1; }
    let cells = width * height;
    let mut image = [0_i64; MAX_CELLS];
    for index in 0..cells {
        let pixel = input[6 + index];
        if !(i32::MIN as i64..=i32::MAX as i64).contains(&pixel) { return -1; }
        image[index] = pixel;
    }
    let start = start_x_value as usize * height + start_y_value as usize;
    if image[start] != new_color && image[start] != boundary_color {
        let mut stack = [0_usize; MAX_CELLS];
        let mut top = 0;
        image[start] = new_color;
        stack[top] = start;
        top += 1;
        while top != 0 {
            top -= 1;
            let index = stack[top];
            let x = index / height;
            let y = index % height;
            for dx in -1_i64..=1 {
                for dy in -1_i64..=1 {
                    if dx == 0 && dy == 0 { continue; }
                    let next_x = x as i64 + dx;
                    let next_y = y as i64 + dy;
                    if next_x < 0 || next_x >= width_value || next_y < 0 || next_y >= height_value { continue; }
                    let next = next_x as usize * height + next_y as usize;
                    if image[next] != new_color && image[next] != boundary_color {
                        image[next] = new_color;
                        stack[top] = next;
                        top += 1;
                    }
                }
            }
        }
    }
    let required = cells * 8;
    if output.is_null() || capacity < required { return -2; }
    let output = unsafe { std::slice::from_raw_parts_mut(output, required) };
    for index in 0..cells { put_i64(output, index, image[index]); }
    required as i64
}
