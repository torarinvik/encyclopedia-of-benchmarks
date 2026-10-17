module k_d_tree;

extern fn double sqrt(double value);
extern fn double fabs(double value);
extern fn double floor(double value);

const usz MAX_POINTS = 15;
const usz MAX_DIMENSION = 3;
const long INVALID_RESULT = -1;
const long OUTPUT_ERROR = -2;

fn usz partition_five(double[MAX_POINTS][MAX_DIMENSION]* points, long* ids,
                     usz from, usz to, usz axis) {
    usz middle = (from + to) / 2;
    for (usz i = from; i <= middle; i++) {
        usz minimum = i;
        for (usz j = i + 1; j <= to; j++)
            if (points[ids[j]][axis] < points[ids[minimum]][axis]) minimum = j;
        long temporary = ids[i]; ids[i] = ids[minimum]; ids[minimum] = temporary;
    }
    return middle;
}

fn usz select_kth(double[MAX_POINTS][MAX_DIMENSION]* points, long* ids,
                  usz from, usz to, usz rank, usz axis);

fn usz choose_median_of_medians(double[MAX_POINTS][MAX_DIMENSION]* points, long* ids,
                                usz from, usz to, usz axis) {
    if (to - from < 5) return partition_five(points, ids, from, to, axis);
    usz medians_to = from;
    for (usz start = from; start <= to - 4; start += 5) {
        usz median = partition_five(points, ids, start, start + 4, axis);
        long temporary = ids[median]; ids[median] = ids[medians_to]; ids[medians_to] = temporary;
        medians_to++;
    }
    usz remainder = (to - from + 1) % 5;
    if (remainder == 0) {
        medians_to--;
    } else {
        usz median = partition_five(points, ids, to - remainder + 1, to, axis);
        long temporary = ids[median]; ids[median] = ids[medians_to]; ids[medians_to] = temporary;
    }
    usz medians_count = medians_to - from + 1;
    return select_kth(points, ids, from, medians_to, (medians_count + 1) / 2, axis);
}

fn usz select_kth(double[MAX_POINTS][MAX_DIMENSION]* points, long* ids,
                  usz from_input, usz to_input, usz rank_input, usz axis) {
    usz from = from_input, to = to_input, rank = rank_input;
    while (from < to) {
        usz pivot_index = choose_median_of_medians(points, ids, from, to, axis);
        double pivot = points[ids[pivot_index]][axis];
        usz i = from, j = from, k = to;
        while (j <= k) {
            double value = points[ids[j]][axis];
            if (value < pivot) {
                long temporary = ids[i]; ids[i] = ids[j]; ids[j] = temporary;
                i++; j++;
            } else if (pivot < value) {
                long temporary = ids[j]; ids[j] = ids[k]; ids[k] = temporary;
                if (k == 0) break;
                k--;
            } else {
                j++;
            }
        }
        long smaller_to = (long)i - 1;
        usz larger_from = k + 1;
        usz absolute_index = from + rank - 1;
        if (smaller_to >= 0 && (long)absolute_index <= smaller_to) {
            to = (usz)smaller_to;
        } else if (absolute_index < larger_from) {
            return absolute_index;
        } else {
            rank -= larger_from - from;
            from = larger_from;
        }
    }
    return from;
}

fn long build_tree(double[MAX_POINTS][MAX_DIMENSION]* points, long* ids, usz from, usz to,
                   usz dimension, usz depth, long* node_point, long* left,
                   long* right, usz* used) {
    if (from > to) return -1;
    usz axis = depth % dimension;
    usz count = to - from + 1;
    usz middle = select_kth(points, ids, from, to, (count + 1) / 2, axis);
    usz current = *used;
    *used += 1;
    node_point[current] = ids[middle];
    left[current] = if middle > from then build_tree(points, ids, from, middle - 1, dimension, depth + 1, node_point, left, right, used) else -1;
    right[current] = if middle < to then build_tree(points, ids, middle + 1, to, dimension, depth + 1, node_point, left, right, used) else -1;
    return (long)current;
}

fn void search_tree(double[MAX_POINTS][MAX_DIMENSION]* points, long* node_point,
                    long* left, long* right, long current, usz axis, usz next_axis,
                    usz dimension, double* query, double* best, long* best_point) {
    if (current < 0) return;
    usz point_index = (usz)node_point[current];
    double squared = 0.0;
    for (usz a = 0; a < dimension; a++) {
        double delta = query[a] - points[point_index][a];
        squared += delta * delta;
    }
    double distance = sqrt(squared);
    if (distance < *best) { *best = distance; *best_point = (long)point_index; }
    bool go_left = query[axis] <= points[point_index][axis];
    long near = if go_left then left[current] else right[current];
    long far = if go_left then right[current] else left[current];
    search_tree(points, node_point, left, right, near, next_axis,
                (next_axis + 1) % dimension, dimension, query, best, best_point);
    if (*best >= fabs(points[point_index][axis] - query[axis]))
        search_tree(points, node_point, left, right, far, next_axis,
                    (next_axis + 1) % dimension, dimension, query, best, best_point);
}

fn long k_d_tree(double* input, usz length, double* output, usz capacity) @export("k_d_tree") {
    if (input == null || length < 2 || length > 51) return INVALID_RESULT;
    double dimension_value = input[0];
    if (dimension_value != dimension_value || floor(dimension_value) != dimension_value ||
        (dimension_value != 2.0 && dimension_value != 3.0)) return INVALID_RESULT;
    usz dimension = (usz)dimension_value;
    double count_value = input[1];
    if (count_value != count_value || floor(count_value) != count_value ||
        count_value < 1.0 || count_value > 15.0) return INVALID_RESULT;
    usz count = (usz)count_value;
    if (length != 2 + dimension * (count + 1)) return INVALID_RESULT;
    double query[MAX_DIMENSION] = {0.0, 0.0, 0.0};
    for (usz axis = 0; axis < dimension; axis++) {
        double value = input[2 + axis];
        if (value != value || floor(value) != value || value < -1000.0 || value > 1000.0) return INVALID_RESULT;
        query[axis] = value;
    }
    double[MAX_POINTS][MAX_DIMENSION] points;
    for (usz i = 0; i < count; i++) {
        for (usz axis = 0; axis < dimension; axis++) {
            double value = input[2 + dimension + i * dimension + axis];
            if (value != value || floor(value) != value || value < -1000.0 || value > 1000.0) return INVALID_RESULT;
            points[i][axis] = value;
        }
    }
    for (usz axis = 0; axis < dimension; axis++) {
        for (usz i = 0; i < count; i++) {
            for (usz j = i + 1; j < count; j++) if (points[i][axis] == points[j][axis]) return INVALID_RESULT;
        }
    }
    double smallest = 1.0e300;
    usz nearest_count = 0;
    for (usz i = 0; i < count; i++) {
        double squared = 0.0;
        for (usz axis = 0; axis < dimension; axis++) {
            double delta = query[axis] - points[i][axis];
            squared += delta * delta;
        }
        if (squared < smallest) { smallest = squared; nearest_count = 1; }
        else if (squared == smallest) nearest_count++;
    }
    if (nearest_count != 1) return INVALID_RESULT;
    usz output_length = dimension + 1;
    if (output == null || capacity < output_length) return OUTPUT_ERROR;
    long[MAX_POINTS] ids, node_point, left, right;
    for (usz i = 0; i < count; i++) ids[i] = (long)i;
    usz used = 0;
    long root = build_tree(&points, &ids[0], 0, count - 1, dimension, 0, &node_point[0], &left[0], &right[0], &used);
    double best = 1.0e300;
    long best_point = 0;
    search_tree(&points, &node_point[0], &left[0], &right[0], root, 0, 1 % dimension,
                dimension, &query[0], &best, &best_point);
    output[0] = best;
    for (usz axis = 0; axis < dimension; axis++) output[axis + 1] = points[(usz)best_point][axis];
    (long)output_length
}
