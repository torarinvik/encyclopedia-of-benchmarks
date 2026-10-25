const PIECE_COUNT: usize = 9;
const MAX_DEPTH: usize = 8;

const UPPER_MOVES: [[usize; 18]; 3] = [
    [0, 8, 1, 2, 16, 5, 13, 7, 14, 9, 3, 4, 11, 12, 15, 10, 17, 6],
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
    [1, 2, 9, 10, 4, 17, 6, 0, 8, 15, 11, 12, 5, 13, 7, 14, 3, 16],
];
const LOWER_MOVES: [[usize; 18]; 3] = [
    [0, 2, 3, 10, 11, 5, 17, 7, 1, 9, 15, 12, 13, 6, 8, 14, 4, 16],
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
    [7, 0, 1, 16, 4, 12, 6, 14, 8, 2, 3, 10, 11, 13, 15, 9, 17, 5],
];
const NEAR_MASK: [u8; 18] = [
    0x50, 0x70, 0x70, 0x75, 0x0f, 0x0f, 0x0f, 0x70, 0x70,
    0x70, 0x7d, 0x2b, 0x2f, 0x0f, 0x50, 0x64, 0x67, 0x0f,
];

fn near_enough(state: &[usize; PIECE_COUNT]) -> bool {
    NEAR_MASK[state[1]] & 0x02 != 0
        && NEAR_MASK[state[3]] & 0x08 != 0
        && NEAR_MASK[state[4]] & 0x10 != 0
        && NEAR_MASK[state[5]] & 0x20 != 0
        && NEAR_MASK[state[0]] & 0x01 != 0
        && NEAR_MASK[state[2]] & 0x04 != 0
        && NEAR_MASK[state[6]] & 0x40 != 0
        && NEAR_MASK[state[7]] & 0x40 != 0
        && NEAR_MASK[state[8]] & 0x40 != 0
}

fn is_goal(state: &[usize; PIECE_COUNT]) -> bool {
    state[0] == 5 && state[1] == 6 && state[2] == 12
        && state[3] == 13 && state[4] == 14 && state[5] == 15
        && state[6] + state[7] + state[8] == 3
}

fn apply_move(state: &[usize; PIECE_COUNT], map: &[usize; 18]) -> [usize; PIECE_COUNT] {
    let mut next = [0usize; PIECE_COUNT];
    for piece in 0..PIECE_COUNT {
        next[piece] = map[state[piece]];
    }
    next
}

fn search_up(state: &[usize; PIECE_COUNT], bound: usize, depth: usize, last_move: i32) -> bool {
    if depth as i32 == bound as i32 - 4 && !near_enough(state) {
        return false;
    }
    if is_goal(state) {
        return true;
    }
    if bound <= depth {
        return false;
    }
    for movement in 0..3 {
        if movement as i32 == last_move {
            continue;
        }
        let next = apply_move(state, &UPPER_MOVES[movement]);
        if search_down(&next, bound, depth + 1, movement as i32) {
            return true;
        }
    }
    false
}

fn search_down(state: &[usize; PIECE_COUNT], bound: usize, depth: usize, last_move: i32) -> bool {
    if bound <= depth {
        return false;
    }
    for movement in 0..3 {
        if movement as i32 == last_move {
            continue;
        }
        let next = apply_move(state, &LOWER_MOVES[movement]);
        if search_up(&next, bound, depth + 1, movement as i32) {
            return true;
        }
    }
    false
}

#[no_mangle]
pub unsafe extern "C" fn freebench_mason(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != PIECE_COUNT {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let mut start = [0usize; PIECE_COUNT];
    let mut used = 0u32;
    for piece in 0..PIECE_COUNT {
        let position = values[piece];
        if !(0..18).contains(&position) {
            return -1;
        }
        let bit = 1u32 << position as u32;
        if used & bit != 0 {
            return -1;
        }
        used |= bit;
        start[piece] = position as usize;
    }
    for bound in (2..=MAX_DEPTH).step_by(2) {
        if search_up(&start, bound, 0, -1) {
            return bound as i64;
        }
    }
    -2
}
