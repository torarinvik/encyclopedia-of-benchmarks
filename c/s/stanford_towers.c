#include <stddef.h>
#include <stdint.h>

enum { DISK_COUNT = 14, MAX_CELLS = 18, MAX_RUNS = 100, MAX_OUTPUT_BYTES = 600,
       STAGING_BYTES = 2400 };

typedef struct { int32_t disc_size; int32_t next; } Cell;
typedef struct {
    int32_t stack[4];
    Cell cells[MAX_CELLS + 1];
    int32_t free_list;
    int32_t moves_done;
} TowerState;

static int32_t get_element(TowerState *state) {
    if (state->free_list <= 0) return 0;
    const int32_t element = state->free_list;
    state->free_list = state->cells[element].next;
    return element;
}

static void push(TowerState *state, int32_t disc_size, int32_t peg) {
    if (state->stack[peg] > 0 && state->cells[state->stack[peg]].disc_size <= disc_size) return;
    const int32_t element = get_element(state);
    if (element <= 0) return;
    state->cells[element].next = state->stack[peg];
    state->stack[peg] = element;
    state->cells[element].disc_size = disc_size;
}

static void initialize_peg(TowerState *state, int32_t peg, int32_t disks) {
    state->stack[peg] = 0;
    for (int32_t disk = disks; disk >= 1; --disk) push(state, disk, peg);
}

static int32_t pop(TowerState *state, int32_t peg) {
    if (state->stack[peg] <= 0) return 0;
    const int32_t element = state->stack[peg];
    const int32_t disc_size = state->cells[element].disc_size;
    state->stack[peg] = state->cells[element].next;
    state->cells[element].next = state->free_list;
    state->free_list = element;
    return disc_size;
}

static void move(TowerState *state, int32_t source, int32_t destination) {
    const int32_t disc_size = pop(state, source);
    push(state, disc_size, destination);
    ++state->moves_done;
}

static void tower(TowerState *state, int32_t source, int32_t destination, int32_t disks) {
    if (disks == 1) {
        move(state, source, destination);
    } else {
        const int32_t auxiliary = 6 - source - destination;
        tower(state, source, auxiliary, disks - 1);
        move(state, source, destination);
        tower(state, auxiliary, destination, disks - 1);
    }
}

static int32_t run_towers(void) {
    TowerState state = {0};
    for (int32_t index = 1; index <= MAX_CELLS; ++index) state.cells[index].next = index - 1;
    state.free_list = MAX_CELLS;
    initialize_peg(&state, 1, DISK_COUNT);
    state.stack[2] = 0;
    state.stack[3] = 0;
    state.moves_done = 0;
    tower(&state, 1, 2, DISK_COUNT);
    return state.moves_done;
}

static size_t append_text(uint8_t *buffer, size_t used, const char *text) {
    while (*text != '\0') buffer[used++] = (uint8_t)*text++;
    return used;
}

static size_t append_integer(uint8_t *buffer, size_t used, int32_t value) {
    uint8_t reverse[12];
    size_t count = 0;
    int32_t remaining = value;
    if (remaining < 0) { buffer[used++] = (uint8_t)'-'; remaining = -remaining; }
    do { reverse[count++] = (uint8_t)('0' + remaining % 10); remaining /= 10; } while (remaining != 0);
    while (count > 0) buffer[used++] = reverse[--count];
    return used;
}

int64_t stanford_towers(int64_t runs, uint8_t *output, size_t output_capacity) {
    if (runs < 1 || runs > MAX_RUNS) return -1;
    if (output == NULL) return -2;
    uint8_t staged[STAGING_BYTES];
    size_t used = 0;
    for (int64_t run = 0; run < runs; ++run) {
        const int32_t moves_done = run_towers();
        if (moves_done != 16383) used = append_text(staged, used, " Error in Towers.\n");
        used = append_integer(staged, used, moves_done);
        used = append_text(staged, used, "\n");
    }
    if (used > MAX_OUTPUT_BYTES || output_capacity < used) return -2;
    for (size_t index = 0; index < used; ++index) output[index] = staged[index];
    return (int64_t)used;
}
