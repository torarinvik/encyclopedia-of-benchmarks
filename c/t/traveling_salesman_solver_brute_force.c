#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
#define MIN_CITIES 2
#define MAX_CITIES 8
#define MAX_INPUT_LENGTH 67
#define MAX_EDGE_COST INT64_C(1000)

static void evaluate_route(const int64_t *matrix, size_t city_count,
                           const size_t *order, int64_t *best_distance,
                           size_t *best_route)
{
    size_t route[MAX_CITIES + 1];
    route[0] = 0;
    for (size_t index = 0; index < city_count - 1; ++index)
        route[index + 1] = order[index];
    route[city_count] = 0;

    int64_t distance = 0;
    for (size_t index = 0; index < city_count; ++index)
        distance += matrix[route[index] * city_count + route[index + 1]];
    if (distance < *best_distance) {
        *best_distance = distance;
        for (size_t index = 0; index <= city_count; ++index)
            best_route[index] = route[index];
    }
}

static void enumerate_routes(const int64_t *matrix, size_t city_count,
                             size_t *order, size_t position, uint8_t *used,
                             int64_t *best_distance, size_t *best_route)
{
    if (position == city_count - 1) {
        evaluate_route(matrix, city_count, order, best_distance, best_route);
        return;
    }
    for (size_t city = 1; city < city_count; ++city) {
        if (used[city]) continue;
        used[city] = 1;
        order[position] = city;
        enumerate_routes(matrix, city_count, order, position + 1, used,
                         best_distance, best_route);
        used[city] = 0;
    }
}

double traveling_salesman_solver_brute_force(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const int64_t selector = input[0];
    const int64_t city_count_value = input[1];
    if (city_count_value < MIN_CITIES || city_count_value > MAX_CITIES) return INVALID_RESULT;
    const size_t city_count = (size_t)city_count_value;
    if (selector < 0 || selector > (int64_t)city_count + 1 ||
        length != 2 + city_count * city_count) return INVALID_RESULT;

    const int64_t *matrix = input + 2;
    for (size_t index = 0; index < city_count * city_count; ++index)
        if (matrix[index] < 0 || matrix[index] > MAX_EDGE_COST) return INVALID_RESULT;

    size_t order[MAX_CITIES - 1];
    uint8_t used[MAX_CITIES] = {0};
    used[0] = 1;
    int64_t best_distance = INT64_C(8001);
    size_t best_route[MAX_CITIES + 1] = {0};
    enumerate_routes(matrix, city_count, order, 0, used, &best_distance, best_route);
    if (selector == 0) return (double)best_distance;
    return (double)best_route[(size_t)(selector - 1)];
}
