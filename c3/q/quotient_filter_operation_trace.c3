module quotient_filter_operation_trace;

const usz SLOTS = 8;
const usz MAX_OPS = 32;
const usz MAX_ITEMS = 6;

fn usz next_slot(usz i) { return (i + 1) % SLOTS; }
fn usz prev_slot(usz i) { return (i + SLOTS - 1) % SLOTS; }

fn bool empty_slot(usz i, char* rem, bool* occ, bool* cont, bool* shifted) {
    return rem[i] == 0 && !occ[i] && !cont[i] && !shifted[i];
}

fn int find_run(usz q, bool* occ, bool* cont, bool* shifted, usz* result) {
    if (!occ[q]) return 0;
    usz bucket = q, steps = 0;
    while (shifted[bucket] && steps < SLOTS) { bucket = prev_slot(bucket); steps++; }
    if (steps >= SLOTS) return -1;
    usz slot = bucket;
    while (bucket != q) {
        slot = next_slot(slot);
        steps = 0;
        while (cont[slot] && steps < SLOTS) { slot = next_slot(slot); steps++; }
        if (steps >= SLOTS) return -1;
        bucket = next_slot(bucket);
        steps = 0;
        while (!occ[bucket] && steps < SLOTS) { bucket = next_slot(bucket); steps++; }
        if (steps >= SLOTS) return -1;
    }
    *result = slot;
    return 1;
}

fn bool find_insert_position(usz q, bool* occ, bool* cont, bool* shifted, usz* result) {
    usz bucket = q, steps = 0;
    while (shifted[bucket] && steps < SLOTS) { bucket = prev_slot(bucket); steps++; }
    if (steps >= SLOTS) return false;
    usz slot = bucket;
    while (bucket != q) {
        steps = 0;
        do { slot = next_slot(slot); steps++; } while (cont[slot] && steps < SLOTS);
        if (steps >= SLOTS) return false;
        bucket = next_slot(bucket);
        steps = 0;
        while (bucket != q && !occ[bucket] && steps < SLOTS) { bucket = next_slot(bucket); steps++; }
        if (steps >= SLOTS) return false;
    }
    *result = slot;
    return true;
}

fn bool next_occupied(usz q, bool* occ, usz* result) {
    usz bucket = next_slot(q);
    for (usz i = 0; i < SLOTS; i++) {
        if (occ[bucket]) { *result = bucket; return true; }
        bucket = next_slot(bucket);
    }
    return false;
}

fn bool insert_at(usz position, usz q, char r, bool has_run, usz run_start,
        char* rem, bool* occ, bool* cont, bool* shifted) {
    bool new_cont = has_run && position != run_start;
    if (has_run && position == run_start) cont[position] = true;
    usz empty = position;
    bool found_empty = false;
    for (usz i = 0; i < SLOTS; i++) {
        if (empty_slot(empty, rem, occ, cont, shifted)) { found_empty = true; break; }
        empty = next_slot(empty);
    }
    if (!found_empty) return false;
    usz slot = empty;
    while (slot != position) {
        usz previous = prev_slot(slot);
        rem[slot] = rem[previous];
        cont[slot] = cont[previous];
        shifted[slot] = true;
        slot = previous;
    }
    rem[position] = r;
    cont[position] = new_cont;
    shifted[position] = position != q;
    occ[q] = true;
    return true;
}

fn long quotient_filter_operation_trace(long* input, usz length,
        char* output, usz capacity) @export("quotient_filter_operation_trace") {
    if (input == null || length < 1 || length > 66) return -1;
    long raw_count = input[0];
    if (raw_count < 0 || raw_count > (long)MAX_OPS) return -1;
    usz count = (usz)raw_count;
    if (length != 1 + 2 * count) return -1;
    for (usz op = 0; op < count; op++) {
        long opcode = input[1 + 2 * op], fp = input[2 + 2 * op];
        if (opcode < 0 || opcode > 2 || fp < 0 || fp > 255) return -1;
    }
    if (output == null || capacity < count) return -2;

    char[SLOTS] rem;
    bool[SLOTS] occ, cont, shifted;
    char[MAX_OPS] statuses;
    for (usz i = 0; i < SLOTS; i++) { rem[i] = 0; occ[i] = false; cont[i] = false; shifted[i] = false; }
    usz total = 0;
    for (usz op = 0; op < count; op++) {
        long opcode = input[1 + 2 * op], fp = input[2 + 2 * op];
        usz q = (usz)fp >> 5;
        char r = (char)(fp & 31);
        if (opcode == 0) {
            if (total == MAX_ITEMS) { statuses[op] = 2; continue; }
            usz position = 0;
            int has_run = find_run(q, &occ[0], &cont[0], &shifted[0], &position);
            if (has_run < 0) return -1;
            usz run_start = position;
            if (has_run != 0) {
                for (usz n = 0; n < SLOTS; n++) {
                    if (rem[position] > r) break;
                    usz next = next_slot(position);
                    position = next;
                    if (!cont[next]) break;
                }
            } else if (!empty_slot(q, &rem[0], &occ[0], &cont[0], &shifted[0])) {
                if (!find_insert_position(q, &occ[0], &cont[0], &shifted[0], &position)) return -1;
            } else position = q;
            if (!insert_at(position, q, r, has_run != 0, run_start,
                    &rem[0], &occ[0], &cont[0], &shifted[0])) return -1;
            total++;
            statuses[op] = 1;
        } else if (opcode == 1) {
            usz position = 0;
            int has_run = find_run(q, &occ[0], &cont[0], &shifted[0], &position);
            if (has_run < 0) return -1;
            bool found = false;
            if (has_run != 0) for (usz n = 0; n < SLOTS; n++) {
                if (rem[position] == r) { found = true; break; }
                if (rem[position] > r) break;
                usz next = next_slot(position);
                if (!cont[next]) break;
                position = next;
            }
            statuses[op] = found ? 1 : 0;
        } else {
            usz position = 0;
            int has_run = find_run(q, &occ[0], &cont[0], &shifted[0], &position);
            if (has_run < 0) return -1;
            bool removed = false;
            if (has_run != 0) for (usz n = 0; n < SLOTS; n++) {
                if (rem[position] == r) { removed = true; break; }
                if (rem[position] > r) break;
                usz next = next_slot(position);
                if (!cont[next]) break;
                position = next;
            }
            if (!removed) { statuses[op] = 0; continue; }
            bool was_run_start = !cont[position];
            usz following = next_slot(position);
            bool has_more_same = !empty_slot(following, &rem[0], &occ[0], &cont[0], &shifted[0]) && cont[following];
            if (was_run_start && !has_more_same) occ[q] = false;
            rem[position] = 0; cont[position] = false; shifted[position] = false;
            usz hole = position;
            usz current_q = q;
            bool first_shift = true;
            for (usz n = 0; n < SLOTS - 1; n++) {
                usz next = next_slot(hole);
                if (empty_slot(next, &rem[0], &occ[0], &cont[0], &shifted[0]) || !shifted[next]) break;
                bool source_cont = cont[next];
                bool promote = first_shift && was_run_start && has_more_same;
                if (!source_cont && !promote && !next_occupied(current_q, &occ[0], &current_q)) return -1;
                rem[hole] = rem[next];
                cont[hole] = promote ? false : source_cont;
                shifted[hole] = cont[hole] || hole != current_q;
                rem[next] = 0; cont[next] = false; shifted[next] = false;
                hole = next;
                first_shift = false;
            }
            rem[hole] = 0; cont[hole] = false; shifted[hole] = false;
            total--;
            statuses[op] = 1;
        }
    }
    for (usz i = 0; i < count; i++) output[i] = statuses[i];
    return (long)count;
}
