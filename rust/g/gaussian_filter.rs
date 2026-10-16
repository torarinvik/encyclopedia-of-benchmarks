const SCALE: i64 = 1_000_000_000_000_000;

fn gaussian_filter_weight(kernel_size: i64, distance: i64) -> i64 {
    if kernel_size == 3 {
        return match distance {
            0 => 159154943091895,
            1 => 96532352630054,
            _ => 58549831524319,
        };
    }
    match distance {
        0 => 198943678864869,
        1 => 91083053297916,
        2 => 41700860491808,
        4 => 8740975213082,
        5 => 4001910066968,
        _ => 384051647741,
    }
}

#[no_mangle]
pub unsafe extern "C" fn gaussian_filter(
    values: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if values.is_null() || length < 3 {
        return -1;
    }
    let height = *values;
    let width = *values.add(1);
    let kernel_size = *values.add(2);
    if !(3..=12).contains(&height)
        || !(3..=12).contains(&width)
        || (kernel_size != 3 && kernel_size != 5)
        || height < kernel_size
        || width < kernel_size
        || length != 3 + (height * width) as usize
    {
        return -1;
    }
    for index in 3..length {
        let pixel = *values.add(index);
        if !(0..=255).contains(&pixel) {
            return -1;
        }
    }

    let output_height = (height - kernel_size + 1) as usize;
    let output_width = (width - kernel_size + 1) as usize;
    let output_count = output_height * output_width;
    if capacity < output_count || output.is_null() {
        return -2;
    }
    let center = kernel_size / 2;
    for row in 0..output_height {
        for column in 0..output_width {
            let mut total = 0i64;
            for kernel_row in 0..kernel_size {
                let dy = kernel_row - center;
                for kernel_column in 0..kernel_size {
                    let dx = kernel_column - center;
                    let pixel_index = 3 + (row + kernel_row as usize) * width as usize
                        + column + kernel_column as usize;
                    total += *values.add(pixel_index)
                        * gaussian_filter_weight(kernel_size, dx * dx + dy * dy);
                }
            }
            *output.add(row * output_width + column) = (total / SCALE) as u8;
        }
    }
    output_count as i64
}
