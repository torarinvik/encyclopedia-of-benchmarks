#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_CELLS 16
#define MAX_TILES 4
#define MAX_PARSEABLE_INPUT_LENGTH 56

static unsigned popcount_small(uint8_t mask)
{
    unsigned count = 0;
    while (mask != 0) {
        mask = (uint8_t)(mask & (uint8_t)(mask - 1));
        ++count;
    }
    return count;
}

static bool neighbor_of(size_t cell, size_t width, size_t height,
                        size_t direction, size_t *neighbor)
{
    const size_t row = cell / width;
    const size_t column = cell % width;
    if (direction == 0 && row != 0) { *neighbor = cell - width; return true; }
    if (direction == 1 && column + 1 < width) { *neighbor = cell + 1; return true; }
    if (direction == 2 && row + 1 < height) { *neighbor = cell + width; return true; }
    if (direction == 3 && column != 0) { *neighbor = cell - 1; return true; }
    return false;
}

static bool propagate(uint8_t *domains, const uint8_t *compatibility,
                      size_t width, size_t height, size_t tile_count,
                      size_t start_cell, bool seed_all)
{
    const size_t cell_count = width * height;
    size_t queue[MAX_CELLS] = {0};
    bool in_queue[MAX_CELLS] = {false};
    size_t head = 0, tail = 0, queued = 0;

    if (seed_all) {
        for (size_t cell = 0; cell < cell_count; ++cell) {
            queue[tail] = cell;
            tail = (tail + 1) % cell_count;
            ++queued;
            in_queue[cell] = true;
        }
    } else {
        queue[tail] = start_cell;
        tail = (tail + 1) % cell_count;
        ++queued;
        in_queue[start_cell] = true;
    }

    while (queued != 0) {
        const size_t source = queue[head];
        head = (head + 1) % cell_count;
        --queued;
        in_queue[source] = false;
        for (size_t direction = 0; direction < 4; ++direction) {
            size_t neighbor;
            if (!neighbor_of(source, width, height, direction, &neighbor)) continue;
            uint8_t supported = 0;
            for (size_t tile = 0; tile < tile_count; ++tile) {
                if ((domains[source] & (uint8_t)(1u << tile)) != 0)
                    supported = (uint8_t)(supported | compatibility[direction * tile_count + tile]);
            }
            const uint8_t reduced = (uint8_t)(domains[neighbor] & supported);
            if (reduced == domains[neighbor]) continue;
            domains[neighbor] = reduced;
            if (reduced == 0) return false;
            if (!in_queue[neighbor]) {
                queue[tail] = neighbor;
                tail = (tail + 1) % cell_count;
                ++queued;
                in_queue[neighbor] = true;
            }
        }
    }
    return true;
}

int64_t wave_function_collapse_simple_tiled(const int64_t *input, size_t length)
{
    if (input == NULL || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > 4 || input[1] < 1 || input[1] > 4 ||
        input[2] < 1 || input[2] > MAX_TILES) return -1;
    const size_t width = (size_t)input[0];
    const size_t height = (size_t)input[1];
    const size_t tile_count = (size_t)input[2];
    const size_t cell_count = width * height;
    const size_t expected_length = 3 + 2 * cell_count + 5 * tile_count;
    if (length != expected_length) return -1;

    const uint8_t full_mask = (uint8_t)((1u << tile_count) - 1u);
    uint8_t domains[MAX_CELLS] = {0};
    uint8_t weights[MAX_TILES] = {0};
    uint8_t compatibility[4 * MAX_TILES] = {0};
    uint16_t draws[MAX_CELLS] = {0};
    size_t position = 3;
    for (size_t cell = 0; cell < cell_count; ++cell) {
        if (input[position] < 1 || input[position] > full_mask) return -1;
        domains[cell] = (uint8_t)input[position++];
    }
    for (size_t tile = 0; tile < tile_count; ++tile) {
        if (input[position] < 1 || input[position] > 4) return -1;
        weights[tile] = (uint8_t)input[position++];
    }
    for (size_t direction = 0; direction < 4; ++direction) {
        for (size_t tile = 0; tile < tile_count; ++tile) {
            if (input[position] < 0 || input[position] > full_mask) return -1;
            compatibility[direction * tile_count + tile] = (uint8_t)input[position++];
        }
    }
    for (size_t cell = 0; cell < cell_count; ++cell) {
        if (input[position] < 0 || input[position] > 65535) return -1;
        draws[cell] = (uint16_t)input[position++];
    }

    for (size_t first = 0; first < tile_count; ++first) {
        for (size_t second = 0; second < tile_count; ++second) {
            const bool north = (compatibility[first] & (uint8_t)(1u << second)) != 0;
            const bool south_reverse =
                (compatibility[2 * tile_count + second] & (uint8_t)(1u << first)) != 0;
            const bool east =
                (compatibility[tile_count + first] & (uint8_t)(1u << second)) != 0;
            const bool west_reverse =
                (compatibility[3 * tile_count + second] & (uint8_t)(1u << first)) != 0;
            if (north != south_reverse || east != west_reverse) return -1;
        }
    }

    if (!propagate(domains, compatibility, width, height, tile_count, 0, true)) return -2;
    for (;;) {
        size_t best_cell = cell_count;
        unsigned best_count = MAX_TILES + 1;
        for (size_t cell = 0; cell < cell_count; ++cell) {
            const unsigned count = popcount_small(domains[cell]);
            if (count > 1 && count < best_count) {
                best_cell = cell;
                best_count = count;
            }
        }
        if (best_cell == cell_count) break;

        unsigned total_weight = 0;
        for (size_t tile = 0; tile < tile_count; ++tile)
            if ((domains[best_cell] & (uint8_t)(1u << tile)) != 0) total_weight += weights[tile];
        unsigned rank = ((unsigned)draws[best_cell] * total_weight) / 65536u;
        size_t selected = tile_count;
        for (size_t tile = 0; tile < tile_count; ++tile) {
            if ((domains[best_cell] & (uint8_t)(1u << tile)) == 0) continue;
            if (rank < weights[tile]) { selected = tile; break; }
            rank -= weights[tile];
        }
        if (selected == tile_count) return -2;
        domains[best_cell] = (uint8_t)(1u << selected);
        if (!propagate(domains, compatibility, width, height, tile_count, best_cell, false)) return -2;
    }

    uint64_t result = UINT64_C(1) << 32;
    for (size_t cell = 0; cell < cell_count; ++cell) {
        size_t tile = 0;
        while ((domains[cell] & (uint8_t)(1u << tile)) == 0) ++tile;
        result |= (uint64_t)tile << (2 * cell);
    }
    return (int64_t)result;
}
