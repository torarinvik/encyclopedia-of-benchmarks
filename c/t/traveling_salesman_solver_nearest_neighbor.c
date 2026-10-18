#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
#define MIN_CITIES 1
#define MAX_CITIES 8
#define MAX_INPUT_LENGTH 68
#define MAX_EDGE_COST INT64_C(1000)

double traveling_salesman_solver_nearest_neighbor(const int64_t *input, size_t length)
{
    if (input == NULL || length < 4 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const int64_t selector = input[0];
    const int64_t city_count_value = input[1];
    const int64_t start_value = input[2];
    if (city_count_value < MIN_CITIES || city_count_value > MAX_CITIES) return INVALID_RESULT;
    const size_t city_count = (size_t)city_count_value;
    if (selector < 0 || selector > (int64_t)city_count + 1 || start_value < 0 ||
        start_value >= city_count_value || length != 3 + city_count * city_count)
        return INVALID_RESULT;

    const int64_t *matrix = input + 3;
    for (size_t index = 0; index < city_count * city_count; ++index)
        if (matrix[index] < 0 || matrix[index] > MAX_EDGE_COST) return INVALID_RESULT;

    size_t route[MAX_CITIES + 1] = {0};
    uint8_t visited[MAX_CITIES] = {0};
    const size_t start = (size_t)start_value;
    size_t current = start;
    route[0] = start;
    visited[start] = 1;
    int64_t total_distance = 0;

    for (size_t step = 1; step < city_count; ++step) {
        int64_t minimum_distance = INT64_C(1001);
        size_t next_city = MAX_CITIES;
        for (size_t city = 0; city < city_count; ++city) {
            if (!visited[city]) {
                const int64_t distance = matrix[current * city_count + city];
                if (distance < minimum_distance) {
                    minimum_distance = distance;
                    next_city = city;
                }
            }
        }
        if (next_city == MAX_CITIES) return INVALID_RESULT;
        route[step] = next_city;
        visited[next_city] = 1;
        total_distance += minimum_distance;
        current = next_city;
    }
    total_distance += matrix[current * city_count + start];
    route[city_count] = start;

    if (selector == 0) return (double)total_distance;
    return (double)route[(size_t)(selector - 1)];
}
