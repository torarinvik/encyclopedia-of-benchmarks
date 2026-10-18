module traveling_salesman_solver_brute_force;

const double INVALID_RESULT = -1.0e300;
const usz MIN_CITIES = 2;
const usz MAX_CITIES = 8;
const usz MAX_INPUT_LENGTH = 67;
const long MAX_EDGE_COST = 1000L;

fn void evaluate_route(long* matrix, usz city_count, usz* order,
                       long* best_distance, usz* best_route) {
    usz[MAX_CITIES + 1] route = zeroed;
    route[0] = 0;
    for (usz index = 0; index < city_count - 1; index++)
        route[index + 1] = order[index];
    route[city_count] = 0;

    long distance = 0L;
    for (usz index = 0; index < city_count; index++)
        distance += matrix[route[index] * city_count + route[index + 1]];
    if (distance < *best_distance) {
        *best_distance = distance;
        for (usz index = 0; index <= city_count; index++) best_route[index] = route[index];
    }
}

fn void enumerate_routes(long* matrix, usz city_count, usz* order, usz position,
                         bool* used,
                         long* best_distance, usz* best_route) {
    if (position == city_count - 1) {
        evaluate_route(matrix, city_count, order, best_distance, best_route);
        return;
    }
    for (usz city = 1; city < city_count; city++) {
        if (used[city]) continue;
        used[city] = true;
        order[position] = city;
        enumerate_routes(matrix, city_count, order, position + 1, used,
                         best_distance, best_route);
        used[city] = false;
    }
}

fn double traveling_salesman_solver_brute_force(long* input, usz length)
    @export("traveling_salesman_solver_brute_force") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    long selector = input[0];
    long city_count_value = input[1];
    if (city_count_value < (long)MIN_CITIES || city_count_value > (long)MAX_CITIES)
        return INVALID_RESULT;
    usz city_count = (usz)city_count_value;
    if (selector < 0L || selector > (long)city_count + 1L ||
        length != 2 + city_count * city_count) return INVALID_RESULT;

    long* matrix = &input[2];
    for (usz index = 0; index < city_count * city_count; index++)
        if (matrix[index] < 0L || matrix[index] > MAX_EDGE_COST) return INVALID_RESULT;

    usz[MAX_CITIES - 1] order = zeroed;
    bool[MAX_CITIES] used = zeroed;
    used[0] = true;
    long best_distance = 8001L;
    usz[MAX_CITIES + 1] best_route = zeroed;
    enumerate_routes(matrix, city_count, &order[0], 0, &used[0],
                     &best_distance, &best_route[0]);
    if (selector == 0L) return (double)best_distance;
    return (double)best_route[(usz)(selector - 1L)];
}
