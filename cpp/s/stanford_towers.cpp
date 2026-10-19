#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int32_t DISK_COUNT = 14;
constexpr std::int32_t MAX_CELLS = 18;
constexpr std::int64_t MAX_RUNS = 100;
constexpr std::size_t MAX_OUTPUT_BYTES = 600;
constexpr std::size_t STAGING_BYTES = 2400;

struct Cell { std::int32_t disc_size; std::int32_t next; };
struct TowerState {
    std::int32_t stack[4];
    Cell cells[MAX_CELLS + 1];
    std::int32_t free_list;
    std::int32_t moves_done;
};

std::int32_t get_element(TowerState &state) {
    if (state.free_list <= 0) return 0;
    const auto element = state.free_list;
    state.free_list = state.cells[element].next;
    return element;
}

void push(TowerState &state, std::int32_t disc_size, std::int32_t peg) {
    if (state.stack[peg] > 0 && state.cells[state.stack[peg]].disc_size <= disc_size) return;
    const auto element = get_element(state);
    if (element <= 0) return;
    state.cells[element].next = state.stack[peg];
    state.stack[peg] = element;
    state.cells[element].disc_size = disc_size;
}

void initialize_peg(TowerState &state, std::int32_t peg, std::int32_t disks) {
    state.stack[peg] = 0;
    for (auto disk = disks; disk >= 1; --disk) push(state, disk, peg);
}

std::int32_t pop(TowerState &state, std::int32_t peg) {
    if (state.stack[peg] <= 0) return 0;
    const auto element = state.stack[peg];
    const auto disc_size = state.cells[element].disc_size;
    state.stack[peg] = state.cells[element].next;
    state.cells[element].next = state.free_list;
    state.free_list = element;
    return disc_size;
}

void move(TowerState &state, std::int32_t source, std::int32_t destination) {
    const auto disc_size = pop(state, source);
    push(state, disc_size, destination);
    ++state.moves_done;
}

void tower(TowerState &state, std::int32_t source, std::int32_t destination, std::int32_t disks) {
    if (disks == 1) {
        move(state, source, destination);
    } else {
        const auto auxiliary = 6 - source - destination;
        tower(state, source, auxiliary, disks - 1);
        move(state, source, destination);
        tower(state, auxiliary, destination, disks - 1);
    }
}

std::int32_t run_towers() {
    TowerState state{};
    for (std::int32_t index = 1; index <= MAX_CELLS; ++index) state.cells[index].next = index - 1;
    state.free_list = MAX_CELLS;
    initialize_peg(state, 1, DISK_COUNT);
    state.stack[2] = 0;
    state.stack[3] = 0;
    state.moves_done = 0;
    tower(state, 1, 2, DISK_COUNT);
    return state.moves_done;
}

std::size_t append_text(std::uint8_t *buffer, std::size_t used, const char *text) {
    while (*text != '\0') buffer[used++] = static_cast<std::uint8_t>(*text++);
    return used;
}

std::size_t append_integer(std::uint8_t *buffer, std::size_t used, std::int32_t value) {
    std::uint8_t reverse[12];
    std::size_t count = 0;
    auto remaining = value;
    if (remaining < 0) { buffer[used++] = static_cast<std::uint8_t>('-'); remaining = -remaining; }
    do { reverse[count++] = static_cast<std::uint8_t>('0' + remaining % 10); remaining /= 10; } while (remaining != 0);
    while (count > 0) buffer[used++] = reverse[--count];
    return used;
}
}

extern "C" std::int64_t stanford_towers(std::int64_t runs, std::uint8_t *output,
    std::size_t output_capacity) noexcept {
    if (runs < 1 || runs > MAX_RUNS) return -1;
    if (output == nullptr) return -2;
    std::uint8_t staged[STAGING_BYTES];
    std::size_t used = 0;
    for (std::int64_t run = 0; run < runs; ++run) {
        const auto moves_done = run_towers();
        if (moves_done != 16383) used = append_text(staged, used, " Error in Towers.\n");
        used = append_integer(staged, used, moves_done);
        used = append_text(staged, used, "\n");
    }
    if (used > MAX_OUTPUT_BYTES || output_capacity < used) return -2;
    for (std::size_t index = 0; index < used; ++index) output[index] = staged[index];
    return static_cast<std::int64_t>(used);
}
