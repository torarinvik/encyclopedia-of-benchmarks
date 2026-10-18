module k_medoids;

const long INVALID_RESULT = -1;
const usz MAX_PACKED_LENGTH = 16;

fn long distance_i64(long a, long b) { return a >= b ? a - b : b - a; }

fn long k_medoids(long* packed, usz length) @export("k_medoids") {
    if (packed == null || length < 3 || length > MAX_PACKED_LENGTH) return INVALID_RESULT;
    long point_count = packed[0], medoid_count = packed[1], max_iter = packed[2];
    if (point_count < 2 || point_count > 8 || medoid_count < 1 || medoid_count > 4 || medoid_count > point_count ||
        max_iter < 1 || max_iter > 16 || length != (usz)(3 + medoid_count + point_count)) return INVALID_RESULT;
    usz n = (usz)point_count, k = (usz)medoid_count;
    long[4] medoids = zeroed;
    long[8] points = zeroed;
    long[8] labels = zeroed;
    for (usz slot = 0; slot < k; slot++) {
        medoids[slot] = packed[3 + slot];
        if (medoids[slot] < 0 || medoids[slot] >= point_count) return INVALID_RESULT;
        for (usz earlier = 0; earlier < slot; earlier++) if (medoids[earlier] == medoids[slot]) return INVALID_RESULT;
    }
    for (usz i = 0; i < n; i++) {
        points[i] = packed[3 + k + i];
        if (points[i] < -16 || points[i] > 16) return INVALID_RESULT;
        for (usz earlier = 0; earlier < i; earlier++) if (points[earlier] == points[i]) return INVALID_RESULT;
    }

    for (long iteration = 0; iteration < max_iter; iteration++) {
        for (usz i = 0; i < n; i++) {
            usz best_slot = 0;
            long best_distance = distance_i64(points[i], points[(usz)medoids[0]]);
            for (usz slot = 1; slot < k; slot++) {
                long distance = distance_i64(points[i], points[(usz)medoids[slot]]);
                if (distance < best_distance) { best_distance = distance; best_slot = slot; }
            }
            labels[i] = (long)best_slot;
        }

        long[4] updated = zeroed;
        for (usz slot = 0; slot < k; slot++) {
            usz first = n;
            for (usz i = 0; i < n; i++) if (labels[i] == (long)slot) { first = i; break; }
            if (first == n) return INVALID_RESULT;
            usz best_index = first;
            long best_cost = 0;
            for (usz i = 0; i < n; i++) if (labels[i] == (long)slot) best_cost += distance_i64(points[first], points[i]);
            for (usz candidate = first + 1; candidate < n; candidate++) {
                if (labels[candidate] != (long)slot) continue;
                long cost = 0;
                for (usz i = 0; i < n; i++) if (labels[i] == (long)slot) cost += distance_i64(points[candidate], points[i]);
                if (cost < best_cost) { best_cost = cost; best_index = candidate; }
            }
            updated[slot] = (long)best_index;
        }

        bool changed = false;
        for (usz slot = 0; slot < k; slot++) if (updated[slot] != medoids[slot]) changed = true;
        if (!changed) break;
        for (usz slot = 0; slot < k; slot++) medoids[slot] = updated[slot];
    }

    long result = 0;
    for (usz slot = 0; slot < k; slot++) result |= medoids[slot] << (3 * (long)slot);
    for (usz i = 0; i < n; i++) result |= labels[i] << (12 + 2 * (long)i);
    return result;
}
