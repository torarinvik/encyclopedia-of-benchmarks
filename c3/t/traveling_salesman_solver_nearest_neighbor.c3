module traveling_salesman_solver_nearest_neighbor;

const double INVALID_RESULT = -1.0e300;
const usz MIN_CITIES = 1;
const usz MAX_CITIES = 8;
const usz MAX_INPUT_LENGTH = 68;
const long MAX_EDGE_COST = 1000L;

fn double traveling_salesman_solver_nearest_neighbor(long* input, usz length)
    @export("traveling_salesman_solver_nearest_neighbor") {
    if (input == null || length < 4 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    long selector = input[0];
    long city_count_value = input[1];
    long start_value = input[2];
    if (city_count_value < (long)MIN_CITIES || city_count_value > (long)MAX_CITIES)
        return INVALID_RESULT;
    usz city_count = (usz)city_count_value;
    if (selector < 0L || selector > (long)city_count + 1L || start_value < 0L ||
        start_value >= city_count_value || length != 3 + city_count * city_count)
        return INVALID_RESULT;

    long* matrix = &input[3];
    for (usz index = 0; index < city_count * city_count; index++)
        if (matrix[index] < 0L || matrix[index] > MAX_EDGE_COST) return INVALID_RESULT;

    usz[MAX_CITIES + 1] route = zeroed;
    bool[MAX_CITIES] visited = zeroed;
    usz start = (usz)start_value;
    usz current = start;
    route[0] = start;
    visited[start] = true;
    long total_distance = 0L;

    for (usz step = 1; step < city_count; step++) {
        long minimum_distance = 1001L;
        usz next_city = MAX_CITIES;
        for (usz city = 0; city < city_count; city++) {
            if (!visited[city]) {
                long distance = matrix[current * city_count + city];
                if (distance < minimum_distance) {
                    minimum_distance = distance;
                    next_city = city;
                }
            }
        }
        if (next_city == MAX_CITIES) return INVALID_RESULT;
        route[step] = next_city;
        visited[next_city] = true;
        total_distance += minimum_distance;
        current = next_city;
    }
    total_distance += matrix[current * city_count + start];
    route[city_count] = start;

    if (selector == 0L) return (double)total_distance;
    return (double)route[(usz)(selector - 1L)];
}
