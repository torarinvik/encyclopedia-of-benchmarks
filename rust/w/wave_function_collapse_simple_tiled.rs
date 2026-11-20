const MAX_CELLS: usize = 16;
const MAX_TILES: usize = 4;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 56;

fn propagate(
    domains: &mut [u8; MAX_CELLS],
    compatibility: &[u8; 4 * MAX_TILES],
    width: usize,
    height: usize,
    tile_count: usize,
    start_cell: usize,
    seed_all: bool,
) -> bool {
    let cell_count = width * height;
    let mut queue = [0usize; MAX_CELLS];
    let mut in_queue = [false; MAX_CELLS];
    let (mut head, mut tail, mut queued) = (0usize, 0usize, 0usize);
    if seed_all {
        for cell in 0..cell_count {
            queue[tail] = cell;
            tail = (tail + 1) % cell_count;
            queued += 1;
            in_queue[cell] = true;
        }
    } else {
        queue[tail] = start_cell;
        tail = (tail + 1) % cell_count;
        queued += 1;
        in_queue[start_cell] = true;
    }

    while queued != 0 {
        let source = queue[head];
        head = (head + 1) % cell_count;
        queued -= 1;
        in_queue[source] = false;
        let row = source / width;
        let column = source % width;
        for direction in 0..4 {
            let neighbor = match direction {
                0 if row != 0 => Some(source - width),
                1 if column + 1 < width => Some(source + 1),
                2 if row + 1 < height => Some(source + width),
                3 if column != 0 => Some(source - 1),
                _ => None,
            };
            let Some(neighbor) = neighbor else { continue };
            let mut supported = 0u8;
            for tile in 0..tile_count {
                if domains[source] & (1u8 << tile) != 0 {
                    supported |= compatibility[direction * tile_count + tile];
                }
            }
            let reduced = domains[neighbor] & supported;
            if reduced == domains[neighbor] { continue; }
            domains[neighbor] = reduced;
            if reduced == 0 { return false; }
            if !in_queue[neighbor] {
                queue[tail] = neighbor;
                tail = (tail + 1) % cell_count;
                queued += 1;
                in_queue[neighbor] = true;
            }
        }
    }
    true
}

#[no_mangle]
pub unsafe extern "C" fn wave_function_collapse_simple_tiled(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let width_value = *input;
    let height_value = *input.add(1);
    let tile_value = *input.add(2);
    if !(1..=4).contains(&width_value) || !(1..=4).contains(&height_value)
        || !(1..=4).contains(&tile_value) { return -1; }
    let width = width_value as usize;
    let height = height_value as usize;
    let tile_count = tile_value as usize;
    let cell_count = width * height;
    if length != 3 + 2 * cell_count + 5 * tile_count { return -1; }
    let full_mask = ((1u16 << tile_count) - 1) as u8;
    let mut domains = [0u8; MAX_CELLS];
    let mut weights = [0u8; MAX_TILES];
    let mut compatibility = [0u8; 4 * MAX_TILES];
    let mut draws = [0u16; MAX_CELLS];
    let mut position = 3usize;
    for domain in domains.iter_mut().take(cell_count) {
        let value = *input.add(position);
        if value < 1 || value > full_mask as i64 { return -1; }
        *domain = value as u8;
        position += 1;
    }
    for weight in weights.iter_mut().take(tile_count) {
        let value = *input.add(position);
        if !(1..=4).contains(&value) { return -1; }
        *weight = value as u8;
        position += 1;
    }
    for direction in 0..4 {
        for tile in 0..tile_count {
            let value = *input.add(position);
            if value < 0 || value > full_mask as i64 { return -1; }
            compatibility[direction * tile_count + tile] = value as u8;
            position += 1;
        }
    }
    for draw in draws.iter_mut().take(cell_count) {
        let value = *input.add(position);
        if !(0..=65535).contains(&value) { return -1; }
        *draw = value as u16;
        position += 1;
    }

    for first in 0..tile_count {
        for second in 0..tile_count {
            let north = compatibility[first] & (1u8 << second) != 0;
            let south_reverse = compatibility[2 * tile_count + second] & (1u8 << first) != 0;
            let east = compatibility[tile_count + first] & (1u8 << second) != 0;
            let west_reverse = compatibility[3 * tile_count + second] & (1u8 << first) != 0;
            if north != south_reverse || east != west_reverse { return -1; }
        }
    }

    if !propagate(&mut domains, &compatibility, width, height, tile_count, 0, true) { return -2; }
    loop {
        let mut best_cell = cell_count;
        let mut best_count = MAX_TILES + 1;
        for cell in 0..cell_count {
            let count = domains[cell].count_ones() as usize;
            if count > 1 && count < best_count { best_cell = cell; best_count = count; }
        }
        if best_cell == cell_count { break; }
        let mut total_weight = 0u32;
        for tile in 0..tile_count {
            if domains[best_cell] & (1u8 << tile) != 0 { total_weight += weights[tile] as u32; }
        }
        let mut rank = (draws[best_cell] as u32 * total_weight) / 65536;
        let mut selected = tile_count;
        for tile in 0..tile_count {
            if domains[best_cell] & (1u8 << tile) == 0 { continue; }
            if rank < weights[tile] as u32 { selected = tile; break; }
            rank -= weights[tile] as u32;
        }
        if selected == tile_count { return -2; }
        domains[best_cell] = 1u8 << selected;
        if !propagate(&mut domains, &compatibility, width, height, tile_count, best_cell, false) { return -2; }
    }
    let mut result = 1i64 << 32;
    for cell in 0..cell_count {
        let tile = domains[cell].trailing_zeros() as usize;
        result |= (tile as i64) << (2 * cell);
    }
    result
}
