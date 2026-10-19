const DISK_COUNT: i32 = 14;
const MAX_CELLS: usize = 18;
const MAX_RUNS: i64 = 100;
const MAX_OUTPUT_BYTES: usize = 600;
const STAGING_BYTES: usize = 2400;

const Cell = struct { disc_size: i32, next: i32 };
const TowerState = struct {
    stack: [4]i32,
    cells: [MAX_CELLS + 1]Cell,
    free_list: i32,
    moves_done: i32,
};

fn getElement(state: *TowerState) i32 {
    if (state.free_list <= 0) return 0;
    const element = state.free_list;
    state.free_list = state.cells[@intCast(element)].next;
    return element;
}

fn push(state: *TowerState, disc_size: i32, peg: usize) void {
    if (state.stack[peg] > 0 and state.cells[@intCast(state.stack[peg])].disc_size <= disc_size) return;
    const element = getElement(state);
    if (element <= 0) return;
    state.cells[@intCast(element)].next = state.stack[peg];
    state.stack[peg] = element;
    state.cells[@intCast(element)].disc_size = disc_size;
}

fn initializePeg(state: *TowerState, peg: usize, disks: i32) void {
    state.stack[peg] = 0;
    var disk = disks;
    while (disk >= 1) : (disk -= 1) push(state, disk, peg);
}

fn pop(state: *TowerState, peg: usize) i32 {
    if (state.stack[peg] <= 0) return 0;
    const element = state.stack[peg];
    const disc_size = state.cells[@intCast(element)].disc_size;
    state.stack[peg] = state.cells[@intCast(element)].next;
    state.cells[@intCast(element)].next = state.free_list;
    state.free_list = element;
    return disc_size;
}

fn doMove(state: *TowerState, source: usize, destination: usize) void {
    const disc_size = pop(state, source);
    push(state, disc_size, destination);
    state.moves_done += 1;
}

fn tower(state: *TowerState, source: usize, destination: usize, disks: i32) void {
    if (disks == 1) {
        doMove(state, source, destination);
    } else {
        const auxiliary = 6 - source - destination;
        tower(state, source, auxiliary, disks - 1);
        doMove(state, source, destination);
        tower(state, auxiliary, destination, disks - 1);
    }
}

fn runTowers() i32 {
    var state = TowerState{
        .stack = [_]i32{0} ** 4,
        .cells = [_]Cell{.{ .disc_size = 0, .next = 0 }} ** (MAX_CELLS + 1),
        .free_list = 0,
        .moves_done = 0,
    };
    for (1..MAX_CELLS + 1) |index| state.cells[index].next = @intCast(index - 1);
    state.free_list = @intCast(MAX_CELLS);
    initializePeg(&state, 1, DISK_COUNT);
    state.stack[2] = 0;
    state.stack[3] = 0;
    state.moves_done = 0;
    tower(&state, 1, 2, DISK_COUNT);
    return state.moves_done;
}

fn appendText(buffer: *[STAGING_BYTES]u8, used: *usize, text: []const u8) void {
    for (text) |byte| { buffer[used.*] = byte; used.* += 1; }
}

fn appendInteger(buffer: *[STAGING_BYTES]u8, used: *usize, value: i32) void {
    var remaining = value;
    if (remaining < 0) { buffer[used.*] = '-'; used.* += 1; remaining = -remaining; }
    var reverse: [12]u8 = undefined;
    var count: usize = 0;
    while (true) {
        reverse[count] = @intCast('0' + @mod(remaining, 10));
        count += 1;
        remaining = @divTrunc(remaining, 10);
        if (remaining == 0) break;
    }
    while (count > 0) { count -= 1; buffer[used.*] = reverse[count]; used.* += 1; }
}

export fn stanford_towers(runs: i64, output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (runs < 1 or runs > MAX_RUNS) return -1;
    if (output_opt == null) return -2;
    var staged: [STAGING_BYTES]u8 = undefined;
    var used: usize = 0;
    for (0..@intCast(runs)) |_| {
        const moves_done = runTowers();
        if (moves_done != 16383) appendText(&staged, &used, " Error in Towers.\n");
        appendInteger(&staged, &used, moves_done);
        appendText(&staged, &used, "\n");
    }
    if (used > MAX_OUTPUT_BYTES or output_capacity < used) return -2;
    const output = output_opt.?;
    for (0..used) |index| output[index] = staged[index];
    return @intCast(used);
}
