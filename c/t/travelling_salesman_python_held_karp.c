#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MIN_CITIES 2u
#define MAX_CITIES 8u
#define MAX_INPUT_LENGTH (1u + 2u * MAX_CITIES)
#define MAX_OUTPUT_ELEMENTS (MAX_CITIES + 3u)
#define MAX_MASKS (1u << MAX_CITIES)

int64_t travelling_salesman_dynamic_programming(const double *input, size_t input_length,
                                                double *output, size_t output_capacity) {
    if (input == NULL || input_length < 1u + 2u * MIN_CITIES ||
        input_length > MAX_INPUT_LENGTH) return -1;
    for (size_t i = 0; i < input_length; ++i)
        if (!isfinite(input[i])) return -1;

    const double city_count_value = input[0];
    if (city_count_value < (double)MIN_CITIES || city_count_value > (double)MAX_CITIES ||
        city_count_value != trunc(city_count_value)) return -1;
    const size_t city_count = (size_t)city_count_value;
    if (input_length != 1u + 2u * city_count) return -1;
    for (size_t i = 0; i < 2u * city_count; ++i) {
        const double coordinate = input[i + 1u];
        if (coordinate < -16.0 || coordinate > 16.0 || coordinate != trunc(coordinate)) return -1;
    }

    const size_t result_length = city_count + 3u;
    if (output == NULL || output_capacity < result_length) return -2;

    double points[MAX_CITIES][2] = {{0.0}};
    for (size_t city = 0; city < city_count; ++city) {
        points[city][0] = input[1u + 2u * city];
        points[city][1] = input[2u + 2u * city];
    }
    double distances[MAX_CITIES][MAX_CITIES];
    for (size_t from = 0; from < city_count; ++from) {
        for (size_t to = 0; to < city_count; ++to) {
            const double dx = points[to][0] - points[from][0];
            const double dy = points[to][1] - points[from][1];
            distances[from][to] = sqrt(dx * dx + dy * dy);
        }
    }

    double dp[MAX_MASKS][MAX_CITIES];
    for (size_t mask = 0; mask < MAX_MASKS; ++mask)
        for (size_t city = 0; city < MAX_CITIES; ++city)
            dp[mask][city] = INFINITY;
    dp[1u][0] = 0.0;
    const size_t state_count = 1u << city_count;
    for (size_t mask = 0; mask < state_count; ++mask) {
        for (size_t from = 0; from < city_count; ++from) {
            if ((mask & (1u << from)) == 0) continue;
            for (size_t to = 0; to < city_count; ++to) {
                if ((mask & (1u << to)) != 0) continue;
                const size_t next_mask = mask | (1u << to);
                const double candidate = dp[mask][from] + distances[from][to];
                if (candidate < dp[next_mask][to]) dp[next_mask][to] = candidate;
            }
        }
    }

    const size_t final_mask = state_count - 1u;
    double minimum = INFINITY;
    size_t end_node = 0;
    for (size_t city = 1; city < city_count; ++city) {
        const double candidate = dp[final_mask][city] + distances[city][0];
        if (minimum > candidate) {
            minimum = candidate;
            end_node = city;
        }
    }

    size_t reverse_path[MAX_CITIES];
    size_t path_length = 0;
    size_t mask = final_mask;
    while (end_node != 0) {
        reverse_path[path_length++] = end_node;
        int found_predecessor = 0;
        for (size_t predecessor = 0; predecessor < city_count; ++predecessor) {
            if ((mask & (1u << predecessor)) != 0 &&
                dp[mask][end_node] == dp[mask ^ (1u << end_node)][predecessor] +
                    distances[predecessor][end_node]) {
                mask ^= 1u << end_node;
                end_node = predecessor;
                found_predecessor = 1;
                break;
            }
        }
        if (!found_predecessor) return -1;
    }

    double staged[MAX_OUTPUT_ELEMENTS];
    const size_t route_length = path_length + 2u;
    staged[0] = (double)route_length;
    size_t offset = 1u;
    staged[offset++] = 0.0;
    while (path_length > 0) staged[offset++] = (double)reverse_path[--path_length];
    staged[offset++] = 0.0;
    staged[offset] = minimum;
    for (size_t i = 0; i < result_length; ++i) output[i] = staged[i];
    return (int64_t)result_length;
}
