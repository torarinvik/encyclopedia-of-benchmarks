const SIDE: usize = 33;
const MAX_POINTS: usize = 17;
const GOLDEN: u64 = 0x9e3779b97f4a7c15;
const MULTIPLIER: u64 = 0x2545f4914f6cdd1d;

fn next_word(state: &mut u64) -> u64 {
    *state ^= *state >> 12;
    *state ^= *state << 25;
    *state ^= *state >> 27;
    state.wrapping_mul(MULTIPLIER)
}

fn touches(occupied: &[u8; SIDE * SIDE], x: usize, y: usize) -> bool {
    occupied[y * SIDE + x - 1] != 0 || occupied[(y - 1) * SIDE + x] != 0 ||
        occupied[y * SIDE + x + 1] != 0 || occupied[(y + 1) * SIDE + x] != 0
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { output.add(offset + byte).write((bits >> (8 * byte)) as u8); }
    }
}

#[no_mangle]
pub unsafe extern "C" fn brownian_tree_diffusion_limited_aggregation(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length != 3 {
        return -1;
    }
    let (attempts_value, seed_value, steps_value) = unsafe {
        (input.read(), input.add(1).read(), input.add(2).read())
    };
    if !(0..=16).contains(&attempts_value)
        || seed_value < 1
        || !(1..=512).contains(&steps_value)
    {
        return -1;
    }

    let mut occupied = [0u8; SIDE * SIDE];
    let mut point_x = [0i32; MAX_POINTS];
    let mut point_y = [0i32; MAX_POINTS];
    let mut point_count = 1usize;
    point_x[0] = 16;
    point_y[0] = 16;
    occupied[16 * SIDE + 16] = 1;

    for attempt in 0..attempts_value as u64 {
        let mut state = (seed_value as u64) ^ GOLDEN.wrapping_mul(attempt + 1);
        if state == 0 {
            state = MULTIPLIER;
        }
        let side_draw = next_word(&mut state);
        let position_draw = next_word(&mut state);
        let launch_side = (side_draw % 4) as usize;
        let position = 1 + (position_draw % 31) as usize;
        let (mut x, mut y) = match launch_side {
            0 => (position, 1),
            1 => (31, position),
            2 => (position, 31),
            _ => (1, position),
        };

        let mut at = y * SIDE + x;
        if occupied[at] != 0 {
            continue;
        }
        if touches(&occupied, x, y) {
            occupied[at] = 1;
            point_x[point_count] = x as i32;
            point_y[point_count] = y as i32;
            point_count += 1;
            continue;
        }
        for _ in 0..steps_value as usize {
            match next_word(&mut state) % 4 {
                0 => x -= 1,
                1 => y -= 1,
                2 => x += 1,
                _ => y += 1,
            }
            if x == 0 || x == 32 || y == 0 || y == 32 {
                break;
            }
            at = y * SIDE + x;
            if touches(&occupied, x, y) {
                occupied[at] = 1;
                point_x[point_count] = x as i32;
                point_y[point_count] = y as i32;
                point_count += 1;
                break;
            }
        }
    }

    let required = (1 + 2 * point_count) * 8;
    if output.is_null() || capacity < required {
        return -2;
    }
    store_i64_le(output, 0, point_count as i64);
    for point in 0..point_count {
        store_i64_le(output, (1 + 2 * point) * 8, point_x[point] as i64);
        store_i64_le(output, (2 + 2 * point) * 8, point_y[point] as i64);
    }
    required as i64
}
