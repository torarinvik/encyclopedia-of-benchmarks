module ant_colony_optimization;

extern fn double sqrt(double value);

const usz ANT_LIMIT = 64;
const usz ITERATION_LIMIT = 64;
const double INVALID_RESULT = -1.0e300;

fn double city_distance(long* cities, usz first, usz second) {
    double dx = (double)cities[2 * first] - (double)cities[2 * second];
    double dy = (double)cities[2 * first + 1] - (double)cities[2 * second + 1];
    return sqrt(dx * dx + dy * dy);
}

fn double next_random_fraction(long* state) {
    *state = (*state * 48271) % 2147483647;
    return (double)state[0] / 2147483647.0;
}

fn usz select_next_city(usz current, bool* visited, long* cities, double* pheromones, long* random_state) {
    double[3] scores;
    for (usz city = 0; city < 3; city++) scores[city] = 0.0;
    double total = 0.0;
    for (usz city = 0; city < 3; city++) {
        if (visited[city]) continue;
        double heuristic = 1.0 / city_distance(cities, current, city);
        double squared = heuristic * heuristic;
        double fifth = squared * squared * heuristic;
        scores[city] = pheromones[3 * current + city] * fifth;
        total += scores[city];
    }
    double roll = next_random_fraction(random_state) * total;
    double cumulative = 0.0;
    usz fallback = 0;
    for (usz city = 0; city < 3; city++) {
        if (visited[city]) continue;
        fallback = city;
        cumulative += scores[city];
        if (cumulative >= roll) return city;
    }
    return fallback;
}

fn double ant_colony_optimization(long* input, usz length) @export("ant_colony_optimization") {
    if (input == null || length != 8) return INVALID_RESULT;
    if (input[0] < 1 || input[0] > 64 || input[1] < 1 || input[1] > 64) return INVALID_RESULT;

    long[6] cities;
    for (usz index = 0; index < 6; index++) {
        cities[index] = input[index + 2];
        if (cities[index] < -100000 || cities[index] > 100000) return INVALID_RESULT;
    }
    for (usz first = 0; first < 3; first++) {
        for (usz second = 0; second < first; second++) {
            if (cities[2 * first] == cities[2 * second] && cities[2 * first + 1] == cities[2 * second + 1]) return INVALID_RESULT;
        }
    }

    usz ant_count = (usz)input[0];
    usz iteration_count = (usz)input[1];
    double[9] pheromones;
    for (usz index = 0; index < 9; index++) pheromones[index] = 1.0;
    usz[256] routes;
    long random_state = 1;
    double best_distance = 1.0e300;

    for (usz iteration = 0; iteration < iteration_count; iteration++) {
        for (usz ant = 0; ant < ant_count; ant++) {
            usz route_start = ant * 4;
            routes[route_start] = 0;
            usz current = 0;
            bool[3] visited;
            visited[0] = true;
            visited[1] = false;
            visited[2] = false;
            for (usz step = 1; step < 3; step++) {
                current = select_next_city(current, &visited[0], &cities[0], &pheromones[0], &random_state);
                routes[route_start + step] = current;
                visited[current] = true;
            }
            routes[route_start + 3] = 0;
            double distance = 0.0;
            for (usz edge = 0; edge < 3; edge++) {
                distance += city_distance(&cities[0], routes[route_start + edge], routes[route_start + edge + 1]);
            }
            if (distance < best_distance) best_distance = distance;
        }
        for (usz index = 0; index < 9; index++) pheromones[index] *= 0.7;
        for (usz ant = 0; ant < ant_count; ant++) {
            usz route_start = ant * 4;
            double distance = 0.0;
            for (usz edge = 0; edge < 3; edge++) {
                distance += city_distance(&cities[0], routes[route_start + edge], routes[route_start + edge + 1]);
            }
            double deposit = 10.0 / distance;
            for (usz edge = 0; edge < 3; edge++) {
                usz from = routes[route_start + edge];
                usz to = routes[route_start + edge + 1];
                pheromones[3 * from + to] += deposit;
                pheromones[3 * to + from] += deposit;
            }
        }
    }
    return best_distance;
}
