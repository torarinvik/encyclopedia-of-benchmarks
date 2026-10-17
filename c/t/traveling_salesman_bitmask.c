#include <stddef.h>
#include <stdint.h>

#define MAX_CITIES 10
#define MAX_MASKS 1024
#define MAX_INPUT_VALUES 102
#define MAX_DISTANCE INT64_C(1000)

static int64_t solve(size_t position, size_t mask, size_t city_count,
                     const int64_t *distances,
                     int64_t memo[MAX_CITIES][MAX_MASKS],
                     uint8_t seen[MAX_CITIES][MAX_MASKS]) {
    const size_t all_visited = ((size_t)1 << city_count) - 1;
    if (mask == all_visited) return distances[position * city_count];
    if (seen[position][mask]) return memo[position][mask];

    int64_t best = INT64_MAX;
    seen[position][mask] = 1;
    for (size_t city = 0; city < city_count; ++city) {
        const size_t bit = (size_t)1 << city;
        if ((mask & bit) == 0) {
            const int64_t cost = distances[position * city_count + city] +
                solve(city, mask | bit, city_count, distances, memo, seen);
            if (cost < best) best = cost;
        }
    }
    memo[position][mask] = best;
    return best;
}

int64_t traveling_salesman_bitmask(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_INPUT_VALUES) return -1;
    const int64_t city_count_value = input[0];
    if (city_count_value < 2 || city_count_value > MAX_CITIES) return -1;
    const size_t city_count = (size_t)city_count_value;
    if (length != 1 + city_count * city_count) return -1;

    int64_t distances[MAX_CITIES * MAX_CITIES];
    for (size_t index = 0; index < city_count * city_count; ++index) {
        const int64_t distance = input[1 + index];
        if (distance < 0 || distance > MAX_DISTANCE) return -1;
        if (index / city_count == index % city_count && distance != 0) return -1;
        distances[index] = distance;
    }

    int64_t memo[MAX_CITIES][MAX_MASKS] = {{0}};
    uint8_t seen[MAX_CITIES][MAX_MASKS] = {{0}};
    return solve(0, 1, city_count, distances, memo, seen);
}
