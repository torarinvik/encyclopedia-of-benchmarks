#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define ANT_LIMIT 64
#define ITERATION_LIMIT 64
#define INVALID_RESULT (-1.0e300)

static double city_distance(const int64_t cities[3][2], size_t first, size_t second)
{
    const double dx = (double)cities[first][0] - (double)cities[second][0];
    const double dy = (double)cities[first][1] - (double)cities[second][1];
    return sqrt(dx * dx + dy * dy);
}

static double next_random_fraction(int64_t *state)
{
    *state = (*state * INT64_C(48271)) % INT64_C(2147483647);
    return (double)*state / 2147483647.0;
}

static size_t select_next_city(size_t current, unsigned visited,
                               const int64_t cities[3][2], const double pheromones[3][3],
                               int64_t *random_state)
{
    double scores[3] = {0.0, 0.0, 0.0};
    double total = 0.0;
    for (size_t city = 0; city < 3; ++city) {
        if ((visited & (1u << city)) != 0) continue;
        const double heuristic = 1.0 / city_distance(cities, current, city);
        const double heuristic_squared = heuristic * heuristic;
        const double heuristic_fifth = heuristic_squared * heuristic_squared * heuristic;
        scores[city] = pheromones[current][city] * heuristic_fifth;
        total += scores[city];
    }
    const double roll = next_random_fraction(random_state) * total;
    double cumulative = 0.0;
    size_t fallback = 0;
    for (size_t city = 0; city < 3; ++city) {
        if ((visited & (1u << city)) != 0) continue;
        fallback = city;
        cumulative += scores[city];
        if (cumulative >= roll) return city;
    }
    return fallback;
}

double ant_colony_optimization(const int64_t *input, size_t length)
{
    if (input == NULL || length != 8) return INVALID_RESULT;
    if (input[0] < 1 || input[0] > ANT_LIMIT || input[1] < 1 || input[1] > ITERATION_LIMIT) return INVALID_RESULT;
    int64_t cities[3][2];
    for (size_t city = 0; city < 3; ++city) {
        cities[city][0] = input[2 + 2 * city];
        cities[city][1] = input[3 + 2 * city];
        if (cities[city][0] < -100000 || cities[city][0] > 100000 ||
            cities[city][1] < -100000 || cities[city][1] > 100000) return INVALID_RESULT;
        for (size_t previous = 0; previous < city; ++previous) {
            if (cities[city][0] == cities[previous][0] && cities[city][1] == cities[previous][1])
                return INVALID_RESULT;
        }
    }

    const size_t ant_count = (size_t)input[0];
    const size_t iteration_count = (size_t)input[1];
    double pheromones[3][3] = {{1.0, 1.0, 1.0}, {1.0, 1.0, 1.0}, {1.0, 1.0, 1.0}};
    size_t routes[ANT_LIMIT][4];
    int64_t random_state = 1;
    double best_distance = INFINITY;

    for (size_t iteration = 0; iteration < iteration_count; ++iteration) {
        for (size_t ant = 0; ant < ant_count; ++ant) {
            routes[ant][0] = 0;
            size_t current = 0;
            unsigned visited = 1u;
            for (size_t step = 1; step < 3; ++step) {
                current = select_next_city(current, visited, cities, pheromones, &random_state);
                routes[ant][step] = current;
                visited |= 1u << current;
            }
            routes[ant][3] = 0;
            double distance = 0.0;
            for (size_t edge = 0; edge < 3; ++edge)
                distance += city_distance(cities, routes[ant][edge], routes[ant][edge + 1]);
            if (distance < best_distance) best_distance = distance;
        }

        for (size_t from = 0; from < 3; ++from)
            for (size_t to = 0; to < 3; ++to)
                pheromones[from][to] *= 0.7;
        for (size_t ant = 0; ant < ant_count; ++ant) {
            double distance = 0.0;
            for (size_t edge = 0; edge < 3; ++edge)
                distance += city_distance(cities, routes[ant][edge], routes[ant][edge + 1]);
            const double deposit = 10.0 / distance;
            for (size_t edge = 0; edge < 3; ++edge) {
                const size_t from = routes[ant][edge];
                const size_t to = routes[ant][edge + 1];
                pheromones[from][to] += deposit;
                pheromones[to][from] += deposit;
            }
        }
    }
    return best_distance;
}
