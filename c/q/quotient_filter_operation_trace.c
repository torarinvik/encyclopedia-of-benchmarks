#include <stddef.h>
#include <stdint.h>

enum { QF_SLOTS = 8, QF_MAX_OPS = 32, QF_MAX_ITEMS = 6 };

static size_t qf_next(size_t i) { return (i + 1) % QF_SLOTS; }
static size_t qf_prev(size_t i) { return (i + QF_SLOTS - 1) % QF_SLOTS; }

static int qf_empty(size_t i, const uint8_t rem[QF_SLOTS],
        const uint8_t occ[QF_SLOTS], const uint8_t cont[QF_SLOTS],
        const uint8_t shifted[QF_SLOTS]) {
    return rem[i] == 0 && !occ[i] && !cont[i] && !shifted[i];
}

static int qf_find_run(size_t q, const uint8_t occ[QF_SLOTS],
        const uint8_t cont[QF_SLOTS], const uint8_t shifted[QF_SLOTS],
        size_t *result) {
    if (!occ[q]) return 0;
    size_t bucket = q, steps = 0;
    while (shifted[bucket] && steps < QF_SLOTS) {
        bucket = qf_prev(bucket);
        ++steps;
    }
    if (steps >= QF_SLOTS) return -1;
    size_t slot = bucket;
    while (bucket != q) {
        slot = qf_next(slot);
        steps = 0;
        while (cont[slot] && steps < QF_SLOTS) {
            slot = qf_next(slot);
            ++steps;
        }
        if (steps >= QF_SLOTS) return -1;
        bucket = qf_next(bucket);
        steps = 0;
        while (!occ[bucket] && steps < QF_SLOTS) {
            bucket = qf_next(bucket);
            ++steps;
        }
        if (steps >= QF_SLOTS) return -1;
    }
    *result = slot;
    return 1;
}

static int qf_find_insert_position(size_t q, const uint8_t occ[QF_SLOTS],
        const uint8_t cont[QF_SLOTS],
        const uint8_t shifted[QF_SLOTS], size_t *result) {
    size_t bucket = q, steps = 0;
    while (shifted[bucket] && steps < QF_SLOTS) {
        bucket = qf_prev(bucket);
        ++steps;
    }
    if (steps >= QF_SLOTS) return 0;
    size_t slot = bucket;
    while (bucket != q) {
        steps = 0;
        do {
            slot = qf_next(slot);
            ++steps;
        } while (cont[slot] && steps < QF_SLOTS);
        if (steps >= QF_SLOTS) return 0;
        bucket = qf_next(bucket);
        steps = 0;
        while (bucket != q && !occ[bucket] && steps < QF_SLOTS) {
            bucket = qf_next(bucket);
            ++steps;
        }
        if (steps >= QF_SLOTS) return 0;
    }
    *result = slot;
    return 1;
}

static int qf_next_occupied(size_t q, const uint8_t occ[QF_SLOTS], size_t *result) {
    size_t bucket = qf_next(q);
    for (size_t i = 0; i < QF_SLOTS; ++i) {
        if (occ[bucket]) { *result = bucket; return 1; }
        bucket = qf_next(bucket);
    }
    return 0;
}

static int qf_insert_at(size_t position, size_t q, uint8_t remainder,
        int has_run, size_t run_start, uint8_t rem[QF_SLOTS],
        uint8_t occ[QF_SLOTS], uint8_t cont[QF_SLOTS],
        uint8_t shifted[QF_SLOTS]) {
    int new_cont = has_run && position != run_start;
    if (has_run && position == run_start) cont[position] = 1;
    size_t empty = position;
    for (size_t i = 0; i < QF_SLOTS; ++i) {
        if (qf_empty(empty, rem, occ, cont, shifted)) break;
        empty = qf_next(empty);
    }
    if (!qf_empty(empty, rem, occ, cont, shifted)) return 0;
    size_t slot = empty;
    while (slot != position) {
        size_t previous = qf_prev(slot);
        rem[slot] = rem[previous];
        cont[slot] = cont[previous];
        shifted[slot] = 1;
        slot = previous;
    }
    rem[position] = remainder;
    cont[position] = (uint8_t)new_cont;
    shifted[position] = (uint8_t)(position != q);
    occ[q] = 1;
    return 1;
}

int64_t quotient_filter_operation_trace(const int64_t *input, size_t length,
        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > 66) return -1;
    int64_t raw_count = input[0];
    if (raw_count < 0 || raw_count > QF_MAX_OPS) return -1;
    size_t count = (size_t)raw_count;
    if (length != 1 + 2 * count) return -1;
    for (size_t i = 0; i < count; ++i) {
        int64_t opcode = input[1 + 2 * i], fingerprint = input[2 + 2 * i];
        if (opcode < 0 || opcode > 2 || fingerprint < 0 || fingerprint > 255) return -1;
    }
    if (output == NULL || capacity < count) return -2;

    uint8_t rem[QF_SLOTS] = {0}, occ[QF_SLOTS] = {0};
    uint8_t cont[QF_SLOTS] = {0}, shifted[QF_SLOTS] = {0};
    uint8_t statuses[QF_MAX_OPS];
    size_t total = 0;

    for (size_t op = 0; op < count; ++op) {
        int64_t opcode = input[1 + 2 * op], fingerprint = input[2 + 2 * op];
        size_t q = (size_t)fingerprint >> 5;
        uint8_t remainder = (uint8_t)(fingerprint & 31);
        if (opcode == 0) {
            if (total == QF_MAX_ITEMS) { statuses[op] = 2; continue; }
            size_t position = 0;
            int found_run = qf_find_run(q, occ, cont, shifted, &position);
            if (found_run < 0) return -1;
            size_t run_start = position;
            if (found_run) {
                for (size_t n = 0; n < QF_SLOTS; ++n) {
                    if (rem[position] > remainder) break;
                    size_t next = qf_next(position);
                    position = next;
                    if (!cont[next]) break;
                }
            } else if (!qf_empty(q, rem, occ, cont, shifted)) {
                if (!qf_find_insert_position(q, occ, cont, shifted,
                        &position)) return -1;
            } else position = q;
            if (!qf_insert_at(position, q, remainder, found_run,
                    run_start, rem, occ, cont, shifted)) return -1;
            ++total;
            statuses[op] = 1;
        } else if (opcode == 1) {
            size_t position = 0;
            int found_run = qf_find_run(q, occ, cont, shifted, &position);
            if (found_run < 0) return -1;
            int found = 0;
            if (found_run) for (size_t n = 0; n < QF_SLOTS; ++n) {
                if (rem[position] == remainder) { found = 1; break; }
                if (rem[position] > remainder) break;
                size_t next = qf_next(position);
                if (!cont[next]) break;
                position = next;
            }
            statuses[op] = (uint8_t)found;
        } else {
            size_t position = 0;
            int found_run = qf_find_run(q, occ, cont, shifted, &position);
            if (found_run < 0) return -1;
            int removed = 0;
            if (found_run) for (size_t n = 0; n < QF_SLOTS; ++n) {
                if (rem[position] == remainder) { removed = 1; break; }
                if (rem[position] > remainder) break;
                size_t next = qf_next(position);
                if (!cont[next]) break;
                position = next;
            }
            if (!removed) { statuses[op] = 0; continue; }
            int was_run_start = !cont[position];
            size_t following = qf_next(position);
            int has_more_same = !qf_empty(following, rem, occ, cont, shifted)
                    && cont[following];
            if (was_run_start && !has_more_same) occ[q] = 0;
            rem[position] = 0;
            cont[position] = 0;
            shifted[position] = 0;
            size_t hole = position;
            size_t current_q = q;
            int first_shift = 1;
            for (size_t n = 0; n < QF_SLOTS - 1; ++n) {
                size_t next = qf_next(hole);
                if (qf_empty(next, rem, occ, cont, shifted) || !shifted[next]) break;
                int source_cont = cont[next];
                int promote = first_shift && was_run_start && has_more_same;
                if (!source_cont && !promote) {
                    if (!qf_next_occupied(current_q, occ, &current_q)) return -1;
                }
                rem[hole] = rem[next];
                cont[hole] = (uint8_t)(promote ? 0 : source_cont);
                shifted[hole] = (uint8_t)(cont[hole] || hole != current_q);
                rem[next] = 0;
                cont[next] = 0;
                shifted[next] = 0;
                hole = next;
                first_shift = 0;
            }
            rem[hole] = 0;
            cont[hole] = 0;
            shifted[hole] = 0;
            --total;
            statuses[op] = 1;
        }
    }

    for (size_t i = 0; i < count; ++i) output[i] = statuses[i];
    return (int64_t)count;
}
