// Adapted from Trekhleb's seam-carving explanation. Copyright (c) 2018
// Oleksii Trekhleb; MIT License, see benchmarks/s/seam_carving/LICENSE.txt.
#[no_mangle]
pub unsafe extern "C" fn seam_carving(input: *const i64, length: usize,
                                       output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 39 { return -1; }
    let words = std::slice::from_raw_parts(input, length);
    let width_value = words[0];
    let height_value = words[1];
    if !(2..=6).contains(&width_value) || !(1..=6).contains(&height_value) { return -1; }
    let width = width_value as usize;
    let height = height_value as usize;
    if length != 2 + width * height { return -1; }
    if words[2..].iter().any(|&pixel| !(0..=255).contains(&pixel)) { return -1; }

    let mut energy = [[0.0f64; 6]; 6];
    let mut cumulative = [[0.0f64; 6]; 6];
    let mut previous_x = [[0usize; 6]; 6];
    let mut seam_x = [0usize; 6];
    for y in 0..height {
        let row = y * width;
        for x in 0..width {
            let middle = words[2 + row + x] as f64;
            let mut left_energy = 0.0;
            let mut right_energy = 0.0;
            if x > 0 {
                let difference = words[2 + row + x - 1] as f64 - middle;
                left_energy = difference * difference + difference * difference + difference * difference;
            }
            if x + 1 < width {
                let difference = words[2 + row + x + 1] as f64 - middle;
                right_energy = difference * difference + difference * difference + difference * difference;
            }
            energy[y][x] = (left_energy + right_energy).sqrt();
        }
    }
    for x in 0..width { cumulative[0][x] = energy[0][x]; }
    for y in 1..height {
        for x in 0..width {
            let mut minimum = f64::INFINITY;
            let mut best_x = x;
            let start = if x == 0 { 0 } else { x - 1 };
            let end = if x + 1 < width { x + 1 } else { width - 1 };
            for candidate in start..=end {
                if cumulative[y - 1][candidate] < minimum {
                    minimum = cumulative[y - 1][candidate];
                    best_x = candidate;
                }
            }
            cumulative[y][x] = minimum + energy[y][x];
            previous_x[y][x] = best_x;
        }
    }
    let mut last_x = 0;
    let mut minimum = cumulative[height - 1][0];
    for x in 1..width {
        if cumulative[height - 1][x] < minimum {
            minimum = cumulative[height - 1][x];
            last_x = x;
        }
    }
    seam_x[height - 1] = last_x;
    for y in (1..height).rev() { seam_x[y - 1] = previous_x[y][seam_x[y]]; }

    let needed = height * (width - 1);
    if output.is_null() || output_capacity < needed { return -2; }
    let mut staged = [0u8; 30];
    let mut position = 0;
    for y in 0..height {
        for x in 0..width {
            if x != seam_x[y] {
                staged[position] = words[2 + y * width + x] as u8;
                position += 1;
            }
        }
    }
    for index in 0..needed { *output.add(index) = staged[index]; }
    needed as i64
}
