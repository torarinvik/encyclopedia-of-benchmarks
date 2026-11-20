module graphai_gnns_hill_climbing;

const long MAX_N = 16;
const long MAX_D = 4;
const long MAX_INPUT = 89;
const long MAX_PARSEABLE = 90;
const long COORD_LIMIT = 100;

fn long graphai_gnns_hill_climbing(long* input, usz length) @export("graphai_gnns_hill_climbing") {
    if (input == null || length < 5 || length > MAX_PARSEABLE.usz()) return -1;
    long n_value = input[0], d_value = input[1], start_value = input[2];
    long e_value = input[3], t_value = input[4];
    if (n_value < 2 || n_value > MAX_N || d_value < 1 || d_value > MAX_D ||
        start_value < 0 || start_value >= n_value || e_value < 1 || e_value >= n_value ||
        t_value < 0 || t_value > 16) return -1;
    usz n = (usz)n_value, d = (usz)d_value;
    if (length != 5 + n * d + n + d || length > MAX_INPUT.usz()) return -1;

    long[64] coordinates = zeroed;
    for (usz i = 0; i < n * d; i++) {
        coordinates[i] = input[5 + i];
        if (coordinates[i] < -COORD_LIMIT || coordinates[i] > COORD_LIMIT) return -1;
    }
    usz mask_offset = 5 + n * d;
    long[16] masks = zeroed;
    long allowed = (1 << n) - 1;
    for (usz vertex = 0; vertex < n; vertex++) {
        long mask = input[mask_offset + vertex];
        if (mask < 0 || (mask & ~allowed) != 0 || (mask & (1 << vertex)) != 0) return -1;
        masks[vertex] = mask;
    }
    long[4] query = zeroed;
    for (usz axis = 0; axis < d; axis++) {
        query[axis] = input[mask_offset + n + axis];
        if (query[axis] < -COORD_LIMIT || query[axis] > COORD_LIMIT) return -1;
    }

    usz current = (usz)start_value;
    long current_distance = 0;
    for (usz axis = 0; axis < d; axis++) {
        long delta = coordinates[current * d + axis] - query[axis];
        current_distance += delta * delta;
    }
    long evaluations = 1, moves = 0;
    for (long step = 0; step < t_value; step++) {
        usz best_vertex = current;
        long best_distance = current_distance;
        long inspected = 0;
        for (usz vertex = 0; vertex < n; vertex++) {
            if ((masks[current] & (1 << vertex)) == 0) continue;
            long distance = 0;
            for (usz axis = 0; axis < d; axis++) {
                long delta = coordinates[vertex * d + axis] - query[axis];
                distance += delta * delta;
            }
            evaluations++;
            inspected++;
            if (distance < best_distance || (distance == best_distance && vertex < best_vertex)) {
                best_vertex = vertex;
                best_distance = distance;
            }
            if (inspected == e_value.usz()) break;
        }
        if (best_distance >= current_distance) break;
        current = best_vertex;
        current_distance = best_distance;
        moves++;
    }
    return (((evaluations * 17 + moves) * 16 + current.long()) * 160001 + current_distance);
}
