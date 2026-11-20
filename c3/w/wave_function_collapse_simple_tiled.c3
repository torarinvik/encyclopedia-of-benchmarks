module wave_function_collapse_simple_tiled;

const usz MAX_CELLS = 16;
const usz MAX_TILES = 4;
const usz MAX_PARSEABLE_INPUT_LENGTH = 56;

fn uint popcount_small(uint mask) {
    uint count = 0;
    while (mask != 0) { mask &= mask - 1; count++; }
    return count;
}

fn bool propagate(uint* domains, uint* compatibility, usz width, usz height,
                  usz tile_count, usz start_cell, bool seed_all) {
    usz cell_count = width * height;
    usz[MAX_CELLS] queue;
    bool[MAX_CELLS] in_queue;
    for (usz cell = 0; cell < MAX_CELLS; cell++) { queue[cell] = 0; in_queue[cell] = false; }
    usz head = 0, tail = 0, queued = 0;
    if (seed_all) {
        for (usz cell = 0; cell < cell_count; cell++) {
            queue[tail] = cell;
            tail = (tail + 1) % cell_count;
            queued++;
            in_queue[cell] = true;
        }
    } else {
        queue[tail] = start_cell;
        tail = (tail + 1) % cell_count;
        queued++;
        in_queue[start_cell] = true;
    }

    while (queued != 0) {
        usz source = queue[head];
        head = (head + 1) % cell_count;
        queued--;
        in_queue[source] = false;
        usz row = source / width, column = source % width;
        for (usz direction = 0; direction < 4; direction++) {
            usz neighbor = 0;
            bool has_neighbor = false;
            if (direction == 0 && row != 0) { neighbor = source - width; has_neighbor = true; }
            else if (direction == 1 && column + 1 < width) { neighbor = source + 1; has_neighbor = true; }
            else if (direction == 2 && row + 1 < height) { neighbor = source + width; has_neighbor = true; }
            else if (direction == 3 && column != 0) { neighbor = source - 1; has_neighbor = true; }
            if (!has_neighbor) continue;
            uint supported = 0;
            for (usz tile = 0; tile < tile_count; tile++) {
                if ((domains[source] & (1u << tile)) != 0)
                    supported |= compatibility[direction * tile_count + tile];
            }
            uint reduced = domains[neighbor] & supported;
            if (reduced == domains[neighbor]) continue;
            domains[neighbor] = reduced;
            if (reduced == 0) return false;
            if (!in_queue[neighbor]) {
                queue[tail] = neighbor;
                tail = (tail + 1) % cell_count;
                queued++;
                in_queue[neighbor] = true;
            }
        }
    }
    return true;
}

fn long wave_function_collapse_simple_tiled(long* input, usz length)
    @export("wave_function_collapse_simple_tiled") {
    if (input == null || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > 4 || input[1] < 1 || input[1] > 4 || input[2] < 1 || input[2] > 4) return -1;
    usz width = (usz)input[0], height = (usz)input[1], tile_count = (usz)input[2];
    usz cell_count = width * height;
    if (length != 3 + 2 * cell_count + 5 * tile_count) return -1;
    uint full_mask = (1u << tile_count) - 1u;
    uint[MAX_CELLS] domains;
    uint[MAX_TILES] weights;
    uint[4 * MAX_TILES] compatibility;
    uint[MAX_CELLS] draws;
    for (usz i = 0; i < MAX_CELLS; i++) domains[i] = 0;
    for (usz i = 0; i < MAX_TILES; i++) weights[i] = 0;
    for (usz i = 0; i < 4 * MAX_TILES; i++) compatibility[i] = 0;
    for (usz i = 0; i < MAX_CELLS; i++) draws[i] = 0;
    usz position = 3;
    for (usz cell = 0; cell < cell_count; cell++) {
        if (input[position] < 1 || input[position] > (long)full_mask) return -1;
        domains[cell] = (uint)input[position++];
    }
    for (usz tile = 0; tile < tile_count; tile++) {
        if (input[position] < 1 || input[position] > 4) return -1;
        weights[tile] = (uint)input[position++];
    }
    for (usz direction = 0; direction < 4; direction++) {
        for (usz tile = 0; tile < tile_count; tile++) {
            if (input[position] < 0 || input[position] > (long)full_mask) return -1;
            compatibility[direction * tile_count + tile] = (uint)input[position++];
        }
    }
    for (usz cell = 0; cell < cell_count; cell++) {
        if (input[position] < 0 || input[position] > 65535) return -1;
        draws[cell] = (uint)input[position++];
    }

    for (usz first = 0; first < tile_count; first++) {
        for (usz second = 0; second < tile_count; second++) {
            bool north = (compatibility[first] & (1u << second)) != 0;
            bool south_reverse = (compatibility[2 * tile_count + second] & (1u << first)) != 0;
            bool east = (compatibility[tile_count + first] & (1u << second)) != 0;
            bool west_reverse = (compatibility[3 * tile_count + second] & (1u << first)) != 0;
            if (north != south_reverse || east != west_reverse) return -1;
        }
    }

    if (!propagate(&domains[0], &compatibility[0], width, height, tile_count, 0, true)) return -2;
    while (true) {
        usz best_cell = cell_count;
        uint best_count = 5;
        for (usz cell = 0; cell < cell_count; cell++) {
            uint count = popcount_small(domains[cell]);
            if (count > 1 && count < best_count) { best_cell = cell; best_count = count; }
        }
        if (best_cell == cell_count) break;
        uint total_weight = 0;
        for (usz tile = 0; tile < tile_count; tile++)
            if ((domains[best_cell] & (1u << tile)) != 0) total_weight += weights[tile];
        uint rank = draws[best_cell] * total_weight / 65536u;
        usz selected = tile_count;
        for (usz tile = 0; tile < tile_count; tile++) {
            if ((domains[best_cell] & (1u << tile)) == 0) continue;
            if (rank < weights[tile]) { selected = tile; break; }
            rank -= weights[tile];
        }
        if (selected == tile_count) return -2;
        domains[best_cell] = 1u << selected;
        if (!propagate(&domains[0], &compatibility[0], width, height, tile_count, best_cell, false)) return -2;
    }
    ulong result = 1ul << 32;
    for (usz cell = 0; cell < cell_count; cell++) {
        usz tile = 0;
        while ((domains[cell] & (1u << tile)) == 0) tile++;
        result |= (ulong)tile << (2 * cell);
    }
    return (long)result;
}
