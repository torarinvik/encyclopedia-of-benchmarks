const MAX_PIXELS: usize = 256;

#[inline(never)]
fn rounded_add(left: f64, right: f64) -> f64 { left + right }
#[inline(never)]
fn rounded_subtract(left: f64, right: f64) -> f64 { left - right }
#[inline(never)]
fn rounded_multiply(left: f64, right: f64) -> f64 { left * right }
#[inline(never)]
fn rounded_divide(left: f64, right: f64) -> f64 { left / right }

#[no_mangle]
pub unsafe extern "C" fn mandelbrot(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length != 6 { return -1; }
    let width_value = *input;
    let height_value = *input.add(1);
    let center_x_q = *input.add(2);
    let center_y_q = *input.add(3);
    let figure_width_q = *input.add(4);
    let max_step_value = *input.add(5);
    if !(1..=16).contains(&width_value) || !(1..=16).contains(&height_value)
        || !(-64..=64).contains(&center_x_q) || !(-64..=64).contains(&center_y_q)
        || !(1..=64).contains(&figure_width_q) || !(2..=64).contains(&max_step_value) {
        return -1;
    }
    let width = width_value as usize;
    let height = height_value as usize;
    let max_step = max_step_value as usize;
    let pixel_count = width * height;
    if output.is_null() || capacity < pixel_count { return -2; }
    if pixel_count > MAX_PIXELS { return -1; }

    let center_x = center_x_q as f64 / 16.0;
    let center_y = center_y_q as f64 / 16.0;
    let figure_width = figure_width_q as f64 / 16.0;
    let figure_height = rounded_multiply(
        rounded_divide(figure_width, width as f64), height as f64);
    let mut offset = 0;
    for image_x in 0..width {
        let x_position = rounded_subtract(rounded_divide(image_x as f64, width as f64), 0.5);
        let figure_x = rounded_add(center_x, rounded_multiply(x_position, figure_width));
        for image_y in 0..height {
            let y_position = rounded_subtract(rounded_divide(image_y as f64, height as f64), 0.5);
            let figure_y = rounded_add(center_y, rounded_multiply(y_position, figure_height));
            let mut a = figure_x;
            let mut b = figure_y;
            let mut current_step = 0;
            for step in 0..max_step {
                current_step = step;
                let a_new = rounded_add(
                    rounded_subtract(rounded_multiply(a, a), rounded_multiply(b, b)), figure_x);
                b = rounded_add(rounded_multiply(rounded_multiply(2.0, a), b), figure_y);
                a = a_new;
                if rounded_add(rounded_multiply(a, a), rounded_multiply(b, b)) > 4.0 { break; }
            }
            let normalized_distance = rounded_divide(current_step as f64, (max_step - 1) as f64);
            *output.add(offset) = if normalized_distance >= 1.0 { 0 } else { 255 };
            offset += 1;
        }
    }
    pixel_count as i64
}
