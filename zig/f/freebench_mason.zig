const State = [9]usize;
const MoveMap = [18]usize;
const MoveSet = [3]MoveMap;
const max_depth: usize = 8;

const upper_moves = MoveSet{
    MoveMap{ 0, 8, 1, 2, 16, 5, 13, 7, 14, 9, 3, 4, 11, 12, 15, 10, 17, 6 },
    MoveMap{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17 },
    MoveMap{ 1, 2, 9, 10, 4, 17, 6, 0, 8, 15, 11, 12, 5, 13, 7, 14, 3, 16 },
};
const lower_moves = MoveSet{
    MoveMap{ 0, 2, 3, 10, 11, 5, 17, 7, 1, 9, 15, 12, 13, 6, 8, 14, 4, 16 },
    MoveMap{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17 },
    MoveMap{ 7, 0, 1, 16, 4, 12, 6, 14, 8, 2, 3, 10, 11, 13, 15, 9, 17, 5 },
};
const near_mask = [_]u8{ 0x50, 0x70, 0x70, 0x75, 0x0f, 0x0f, 0x0f, 0x70, 0x70, 0x70, 0x7d, 0x2b, 0x2f, 0x0f, 0x50, 0x64, 0x67, 0x0f };

fn nearEnough(state: State) bool {
    return (near_mask[state[1]] & 0x02) != 0
        and (near_mask[state[3]] & 0x08) != 0
        and (near_mask[state[4]] & 0x10) != 0
        and (near_mask[state[5]] & 0x20) != 0
        and (near_mask[state[0]] & 0x01) != 0
        and (near_mask[state[2]] & 0x04) != 0
        and (near_mask[state[6]] & 0x40) != 0
        and (near_mask[state[7]] & 0x40) != 0
        and (near_mask[state[8]] & 0x40) != 0;
}

fn isGoal(state: State) bool {
    return state[0] == 5 and state[1] == 6 and state[2] == 12 and state[3] == 13
        and state[4] == 14 and state[5] == 15 and state[6] + state[7] + state[8] == 3;
}

fn applyMove(state: State, movement: usize, upper: bool) State {
    var next: State = undefined;
    for (0..9) |piece| {
        next[piece] = if (upper) upper_moves[movement][state[piece]] else lower_moves[movement][state[piece]];
    }
    return next;
}

fn searchDown(state: State, bound: usize, depth: usize, last_move: i32) bool;

fn searchUp(state: State, bound: usize, depth: usize, last_move: i32) bool {
    if (bound >= 4 and depth == bound - 4 and !nearEnough(state)) return false;
    if (isGoal(state)) return true;
    if (bound <= depth) return false;
    for (0..3) |movement| {
        if (@as(i32, @intCast(movement)) == last_move) continue;
        const next = applyMove(state, movement, true);
        if (searchDown(next, bound, depth + 1, @intCast(movement))) return true;
    }
    return false;
}

fn searchDown(state: State, bound: usize, depth: usize, last_move: i32) bool {
    if (bound <= depth) return false;
    for (0..3) |movement| {
        if (@as(i32, @intCast(movement)) == last_move) continue;
        const next = applyMove(state, movement, false);
        if (searchUp(next, bound, depth + 1, @intCast(movement))) return true;
    }
    return false;
}

export fn freebench_mason(input: [*c]const i64, length: usize) i64 {
    if (input == null or length != 9) return -1;
    var start: State = undefined;
    var used: u32 = 0;
    for (0..9) |piece| {
        const position = input[piece];
        if (position < 0 or position >= 18) return -1;
        const p: usize = @intCast(position);
        const bit: u32 = @as(u32, 1) << @intCast(p);
        if ((used & bit) != 0) return -1;
        used |= bit;
        start[piece] = p;
    }
    var bound: usize = 2;
    while (bound <= max_depth) : (bound += 2) {
        if (searchUp(start, bound, 0, -1)) return @intCast(bound);
    }
    return -2;
}
