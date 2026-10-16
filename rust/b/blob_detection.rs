const MAX_SIDE: usize = 128;
const MAX_CELLS: usize = MAX_SIDE * MAX_SIDE;
const MAX_INPUT_LENGTH: usize = 3 + 3 * MAX_CELLS;

fn is_target_color(red: i64, green: i64, blue: i64, profile: i64) -> bool {
    let maximum = red.max(green).max(blue);
    let minimum = red.min(green).min(blue);
    let delta = maximum - minimum;
    let (hue_minimum, hue_maximum, saturation_minimum) = if profile == 0 {
        (379, 496, 436)
    } else {
        (398, 498, 355)
    };
    if maximum == 0 || delta == 0 || 1000 * delta < saturation_minimum * maximum {
        return false;
    }
    let hue_numerator = if maximum == red {
        (green - blue).rem_euclid(6 * delta)
    } else if maximum == green {
        2 * delta + blue - red
    } else {
        4 * delta + red - green
    };
    hue_minimum * 6 * delta <= 1000 * hue_numerator &&
        1000 * hue_numerator <= hue_maximum * 6 * delta
}

#[no_mangle]
pub unsafe extern "C" fn blob_detection(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let height_value = *input;
    let width_value = *input.add(1);
    let profile = *input.add(2);
    if height_value < 1 || height_value > MAX_SIDE as i64 ||
        width_value < 1 || width_value > MAX_SIDE as i64 {
        return -1;
    }
    let height = height_value as usize;
    let width = width_value as usize;
    let cells = height * width;
    if (profile != 0 && profile != 1) || length != 3 + 3 * cells {
        return -1;
    }
    for channel in 0..3 * cells {
        let value = *input.add(3 + channel);
        if !(0..=255).contains(&value) {
            return -1;
        }
    }

    let mut mask = [false; MAX_CELLS];
    let mut eroded = [false; MAX_CELLS];
    let mut opened = [false; MAX_CELLS];
    let mut visited = [false; MAX_CELLS];
    let mut queue = [0usize; MAX_CELLS];
    for index in 0..cells {
        mask[index] = is_target_color(*input.add(3 + 3 * index),
                                      *input.add(4 + 3 * index),
                                      *input.add(5 + 3 * index), profile);
    }

    for row in 0..height {
        for column in 0..width {
            let mut keep = true;
            for dy in -3i64..=3 {
                for dx in -3i64..=3 {
                    if dx * dx + dy * dy > 9 { continue; }
                    let y = row as i64 + dy;
                    let x = column as i64 + dx;
                    if y >= 0 && y < height_value && x >= 0 && x < width_value &&
                        !mask[y as usize * width + x as usize] {
                        keep = false;
                        break;
                    }
                }
                if !keep { break; }
            }
            eroded[row * width + column] = keep;
        }
    }

    for row in 0..height {
        for column in 0..width {
            let mut set = false;
            for dy in -3i64..=3 {
                for dx in -3i64..=3 {
                    if dx * dx + dy * dy > 9 { continue; }
                    let y = row as i64 + dy;
                    let x = column as i64 + dx;
                    if y >= 0 && y < height_value && x >= 0 && x < width_value &&
                        eroded[y as usize * width + x as usize] {
                        set = true;
                        break;
                    }
                }
                if set { break; }
            }
            opened[row * width + column] = set;
        }
    }

    let mut object_count = 0i64;
    for start in 0..cells {
        if !opened[start] || visited[start] { continue; }
        let (mut head, mut tail, mut area) = (0usize, 0usize, 0usize);
        visited[start] = true;
        queue[tail] = start;
        tail += 1;
        while head < tail {
            let index = queue[head];
            head += 1;
            area += 1;
            let row = (index / width) as i64;
            let column = (index % width) as i64;
            for dy in -1i64..=1 {
                for dx in -1i64..=1 {
                    if dx == 0 && dy == 0 { continue; }
                    let y = row + dy;
                    let x = column + dx;
                    if y < 0 || y >= height_value || x < 0 || x >= width_value { continue; }
                    let neighbor = y as usize * width + x as usize;
                    if opened[neighbor] && !visited[neighbor] {
                        visited[neighbor] = true;
                        queue[tail] = neighbor;
                        tail += 1;
                    }
                }
            }
        }
        if (200..=5000).contains(&area) {
            object_count += 1;
            if object_count == 50 { return object_count; }
        }
    }
    object_count
}
