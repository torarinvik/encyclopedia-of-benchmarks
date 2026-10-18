#include <stddef.h>
#include <stdint.h>

#define MAX_CITIES 8
#define MAX_INPUT_LENGTH 66
#define JAVA_INT_MIN INT64_C(-2147483648)
#define JAVA_INT_MAX INT64_C(2147483647)
#define MAX_EDGE_COST INT64_C(1000)

static void evaluate_permutation(const int64_t *matrix, size_t city_count,
                                 const size_t *order, int64_t *best)
{
    int64_t cost = 0;
    size_t previous = 0;
    for (size_t i = 0; i < city_count - 1; ++i) {
        const size_t city = order[i];
        const int64_t edge = matrix[previous * city_count + city];
        if (edge == JAVA_INT_MAX) return;
        cost += edge;
        previous = city;
    }
    const int64_t return_edge = matrix[previous * city_count];
    if (return_edge == JAVA_INT_MAX) return;
    cost += return_edge;
    if (cost < *best) *best = cost;
}

static void enumerate_permutations(const int64_t *matrix, size_t city_count,
                                   size_t *order, size_t position, int64_t *best)
{
    if (position == city_count - 1) {
        evaluate_permutation(matrix, city_count, order, best);
        return;
    }
    for (size_t index = position; index < city_count - 1; ++index) {
        const size_t temporary = order[position];
        order[position] = order[index];
        order[index] = temporary;
        enumerate_permutations(matrix, city_count, order, position + 1, best);
        order[index] = order[position];
        order[position] = temporary;
    }
}

int64_t traveling_salesman(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t city_count_value = input[0];
    if (city_count_value < 0 || city_count_value > MAX_CITIES) return -1;
    const size_t city_count = (size_t)city_count_value;
    if (length != 1 + city_count * city_count) return -1;

    for (size_t index = 0; index < city_count * city_count; ++index) {
        const int64_t value = input[1 + index];
        if (value < JAVA_INT_MIN || value > JAVA_INT_MAX) return -1;
    }
    if (city_count <= 1) return 0;

    for (size_t row = 0; row < city_count; ++row) {
        for (size_t column = 0; column < city_count; ++column) {
            if (row == column) continue;
            const int64_t edge = input[1 + row * city_count + column];
            if (edge != JAVA_INT_MAX && (edge < 0 || edge > MAX_EDGE_COST)) return -1;
        }
    }

    size_t order[MAX_CITIES - 1];
    for (size_t city = 1; city < city_count; ++city) order[city - 1] = city;
    int64_t best = JAVA_INT_MAX;
    enumerate_permutations(input + 1, city_count, order, 0, &best);
    return best;
}
