module stanford_towers;

const long DISK_COUNT = 14;
const int MAX_CELLS = 18;
const long MAX_RUNS = 100;
const usz MAX_OUTPUT_BYTES = 600;
const usz STAGING_BYTES = 2400;

struct Cell { int disc_size; int next; }
struct TowerState {
    int[4] stack;
    Cell[MAX_CELLS + 1] cells;
    int free_list;
    int moves_done;
}

fn int get_element(TowerState* state) {
    if (state.free_list <= 0) return 0;
    int element = state.free_list;
    state.free_list = state.cells[element].next;
    return element;
}

fn void push(TowerState* state, int disc_size, int peg) {
    if (state.stack[peg] > 0 && state.cells[state.stack[peg]].disc_size <= disc_size) return;
    int element = get_element(state);
    if (element <= 0) return;
    state.cells[element].next = state.stack[peg];
    state.stack[peg] = element;
    state.cells[element].disc_size = disc_size;
}

fn void initialize_peg(TowerState* state, int peg, int disks) {
    state.stack[peg] = 0;
    for (int disk = disks; disk >= 1; --disk) push(state, disk, peg);
}

fn int pop(TowerState* state, int peg) {
    if (state.stack[peg] <= 0) return 0;
    int element = state.stack[peg];
    int disc_size = state.cells[element].disc_size;
    state.stack[peg] = state.cells[element].next;
    state.cells[element].next = state.free_list;
    state.free_list = element;
    return disc_size;
}

fn void move(TowerState* state, int source, int destination) {
    int disc_size = pop(state, source);
    push(state, disc_size, destination);
    state.moves_done++;
}

fn void tower(TowerState* state, int source, int destination, int disks) {
    if (disks == 1) {
        move(state, source, destination);
    } else {
        int auxiliary = 6 - source - destination;
        tower(state, source, auxiliary, disks - 1);
        move(state, source, destination);
        tower(state, auxiliary, destination, disks - 1);
    }
}

fn int run_towers() {
    TowerState state;
    for (int index = 1; index <= MAX_CELLS; ++index) state.cells[index].next = index - 1;
    state.free_list = MAX_CELLS;
    initialize_peg(&state, 1, (int)DISK_COUNT);
    state.stack[2] = 0;
    state.stack[3] = 0;
    state.moves_done = 0;
    tower(&state, 1, 2, (int)DISK_COUNT);
    return state.moves_done;
}

fn usz append_text(char* buffer, usz used, const char* text) {
    while (*text != '\0') buffer[used++] = *text++;
    return used;
}

fn usz append_integer(char* buffer, usz used, int value) {
    char[12] reverse;
    usz count = 0;
    if (value < 0) { buffer[used++] = '-'; value = -value; }
    do { reverse[count++] = (char)('0' + value % 10); value /= 10; } while (value != 0);
    while (count > 0) buffer[used++] = reverse[--count];
    return used;
}

fn long stanford_towers(long runs, char* output, usz output_capacity)
    @export("stanford_towers") {
    if (runs < 1 || runs > MAX_RUNS) return -1;
    if (output == null) return -2;
    char[STAGING_BYTES] staged;
    usz used = 0;
    for (long run = 0; run < runs; ++run) {
        int moves_done = run_towers();
        if (moves_done != 16383) used = append_text(&staged[0], used, " Error in Towers.\n");
        used = append_integer(&staged[0], used, moves_done);
        used = append_text(&staged[0], used, "\n");
    }
    if (used > MAX_OUTPUT_BYTES || output_capacity < used) return -2;
    for (usz index = 0; index < used; ++index) output[index] = staged[index];
    return (long)used;
}
