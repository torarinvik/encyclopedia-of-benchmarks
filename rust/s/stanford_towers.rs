const DISK_COUNT: i32 = 14;
const MAX_CELLS: usize = 18;
const MAX_RUNS: i64 = 100;
const MAX_OUTPUT_BYTES: usize = 600;
const STAGING_BYTES: usize = 2400;

#[derive(Clone, Copy, Default)]
struct Cell { disc_size: i32, next: i32 }
struct TowerState {
    stack: [i32; 4],
    cells: [Cell; MAX_CELLS + 1],
    free_list: i32,
    moves_done: i32,
}

fn get_element(state: &mut TowerState) -> i32 {
    if state.free_list <= 0 { return 0; }
    let element = state.free_list;
    state.free_list = state.cells[element as usize].next;
    element
}

fn push(state: &mut TowerState, disc_size: i32, peg: usize) {
    if state.stack[peg] > 0 && state.cells[state.stack[peg] as usize].disc_size <= disc_size { return; }
    let element = get_element(state);
    if element <= 0 { return; }
    state.cells[element as usize].next = state.stack[peg];
    state.stack[peg] = element;
    state.cells[element as usize].disc_size = disc_size;
}

fn initialize_peg(state: &mut TowerState, peg: usize, disks: i32) {
    state.stack[peg] = 0;
    for disk in (1..=disks).rev() { push(state, disk, peg); }
}

fn pop(state: &mut TowerState, peg: usize) -> i32 {
    if state.stack[peg] <= 0 { return 0; }
    let element = state.stack[peg];
    let disc_size = state.cells[element as usize].disc_size;
    state.stack[peg] = state.cells[element as usize].next;
    state.cells[element as usize].next = state.free_list;
    state.free_list = element;
    disc_size
}

fn do_move(state: &mut TowerState, source: usize, destination: usize) {
    let disc_size = pop(state, source);
    push(state, disc_size, destination);
    state.moves_done += 1;
}

fn tower(state: &mut TowerState, source: usize, destination: usize, disks: i32) {
    if disks == 1 {
        do_move(state, source, destination);
    } else {
        let auxiliary = 6 - source - destination;
        tower(state, source, auxiliary, disks - 1);
        do_move(state, source, destination);
        tower(state, auxiliary, destination, disks - 1);
    }
}

fn run_towers() -> i32 {
    let mut state = TowerState {
        stack: [0; 4],
        cells: [Cell::default(); MAX_CELLS + 1],
        free_list: 0,
        moves_done: 0,
    };
    for index in 1..=MAX_CELLS { state.cells[index].next = index as i32 - 1; }
    state.free_list = MAX_CELLS as i32;
    initialize_peg(&mut state, 1, DISK_COUNT);
    state.stack[2] = 0;
    state.stack[3] = 0;
    state.moves_done = 0;
    tower(&mut state, 1, 2, DISK_COUNT);
    state.moves_done
}

fn append_text(buffer: &mut [u8; STAGING_BYTES], used: &mut usize, text: &[u8]) {
    for &byte in text { buffer[*used] = byte; *used += 1; }
}

fn append_integer(buffer: &mut [u8; STAGING_BYTES], used: &mut usize, value: i32) {
    let mut remaining = value;
    if remaining < 0 { buffer[*used] = b'-'; *used += 1; remaining = -remaining; }
    let mut reverse = [0_u8; 12];
    let mut count = 0;
    loop {
        reverse[count] = b'0' + (remaining % 10) as u8;
        count += 1;
        remaining /= 10;
        if remaining == 0 { break; }
    }
    while count > 0 { count -= 1; buffer[*used] = reverse[count]; *used += 1; }
}

#[no_mangle]
pub unsafe extern "C" fn stanford_towers(runs: i64, output: *mut u8,
    output_capacity: usize) -> i64 {
    if !(1..=MAX_RUNS).contains(&runs) { return -1; }
    if output.is_null() { return -2; }
    let mut staged = [0_u8; STAGING_BYTES];
    let mut used = 0;
    for _ in 0..runs {
        let moves_done = run_towers();
        if moves_done != 16383 { append_text(&mut staged, &mut used, b" Error in Towers.\n"); }
        append_integer(&mut staged, &mut used, moves_done);
        append_text(&mut staged, &mut used, b"\n");
    }
    if used > MAX_OUTPUT_BYTES || output_capacity < used { return -2; }
    for index in 0..used { *output.add(index) = staged[index]; }
    used as i64
}
