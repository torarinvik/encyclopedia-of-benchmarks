module traveling_salesman;

const usz MAX_CITIES = 8;
const usz MAX_INPUT_LENGTH = 66;
const long JAVA_INT_MIN = -2147483648L;
const long JAVA_INT_MAX = 2147483647L;
const long MAX_EDGE_COST = 1000L;

fn void evaluate_permutation(long* matrix, usz city_count, usz* order, long* best) {
    long cost = 0L;
    usz previous = 0;
    for (usz index = 0; index < city_count - 1; index++) {
        usz city = order[index];
        long edge = matrix[previous * city_count + city];
        if (edge == JAVA_INT_MAX) return;
        cost += edge;
        previous = city;
    }
    long return_edge = matrix[previous * city_count];
    if (return_edge == JAVA_INT_MAX) return;
    cost += return_edge;
    if (cost < *best) *best = cost;
}

fn void enumerate_permutations(long* matrix, usz city_count, usz* order,
                               usz position, long* best) {
    if (position == city_count - 1) {
        evaluate_permutation(matrix, city_count, order, best);
        return;
    }
    for (usz index = position; index < city_count - 1; index++) {
        usz temporary = order[position];
        order[position] = order[index];
        order[index] = temporary;
        enumerate_permutations(matrix, city_count, order, position + 1, best);
        order[index] = order[position];
        order[position] = temporary;
    }
}

fn long traveling_salesman(long* input, usz length) @export("traveling_salesman") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1L;
    long city_count_value = input[0];
    if (city_count_value < 0L || city_count_value > (long)MAX_CITIES) return -1L;
    usz city_count = (usz)city_count_value;
    if (length != 1 + city_count * city_count) return -1L;

    for (usz index = 0; index < city_count * city_count; index++) {
        long value = input[1 + index];
        if (value < JAVA_INT_MIN || value > JAVA_INT_MAX) return -1L;
    }
    if (city_count <= 1) return 0L;

    for (usz row = 0; row < city_count; row++) {
        for (usz column = 0; column < city_count; column++) {
            if (row == column) continue;
            long edge = input[1 + row * city_count + column];
            if (edge != JAVA_INT_MAX && (edge < 0L || edge > MAX_EDGE_COST)) return -1L;
        }
    }

    usz[MAX_CITIES - 1] order = zeroed;
    for (usz city = 1; city < city_count; city++) order[city - 1] = city;
    long best = JAVA_INT_MAX;
    enumerate_permutations(&input[1], city_count, &order[0], 0, &best);
    return best;
}
