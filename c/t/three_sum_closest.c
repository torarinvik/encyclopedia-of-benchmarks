/* Closest three-value sum, using a private heapsorted copy. */
#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 512
#define SHORT_ITEMS 16
#define INVALID_RESULT (-9000000000000000000LL)

static int fits_i32(int64_t value)
{
    return value >= INT32_MIN && value <= INT32_MAX;
}

static void sift_down(int32_t *values, size_t root, size_t count)
{
    const int32_t value = values[root];
    while (root < count / 2) {
        size_t child = root * 2 + 1;
        if (child + 1 < count && values[child] < values[child + 1]) ++child;
        if (value >= values[child]) break;
        values[root] = values[child];
        root = child;
    }
    values[root] = value;
}

static int64_t sum_rank(int64_t sum, int64_t target)
{
    const int64_t delta = sum - target;
    return delta < 0 ? -2 * delta : 2 * delta + 1;
}

static int64_t ranked_sum(int64_t rank, int64_t target)
{
    return (rank & 1) ? target + rank / 2 : target - rank / 2;
}

static int64_t closest_sorted(const int32_t *values, size_t count, int64_t target)
{
    const int64_t smallest = (int64_t)values[0] + values[1] + values[2];
    if (target <= smallest) return smallest;
    const int64_t last_pair = (int64_t)values[count - 1] + values[count - 2];
    const int64_t largest = last_pair + values[count - 3];
    if (target >= largest) return largest;

    int64_t best_rank = sum_rank(smallest, target);
    for (size_t first = 0; first + 2 < count; ++first) {
        const int64_t fixed = values[first];
        if (first > 0 && fixed == values[first - 1]) continue;
        const int64_t minimum = fixed + values[first + 1] + values[first + 2];
        if (minimum >= target)
            return sum_rank(minimum, target) < best_rank ? minimum : ranked_sum(best_rank, target);
        const int64_t maximum = fixed + last_pair;
        if (maximum <= target) {
            const int64_t rank = sum_rank(maximum, target);
            if (rank < best_rank) best_rank = rank;
            continue;
        }
        size_t left = first + 1, right = count - 1;
        while (left < right) {
            const int64_t sum = fixed + values[left] + values[right];
            const int64_t rank = sum_rank(sum, target);
            if (rank < best_rank) best_rank = rank;
            if (sum < target) ++left;
            else if (sum > target) --right;
            else return sum;
        }
    }
    return ranked_sum(best_rank, target);
}

static int64_t sort_and_find(const int64_t *input, size_t count, int64_t target, int32_t *values)
{
    for (size_t i = 0; i < count; ++i) {
        const int64_t value = input[i + 2];
        if (!fits_i32(value)) return INVALID_RESULT;
        values[i] = (int32_t)value;
    }
    for (size_t start = count / 2; start > 0; --start) sift_down(values, start - 1, count);
    for (size_t end = count; end > 1;) {
        --end;
        const int32_t value = values[0];
        values[0] = values[end];
        values[end] = value;
        sift_down(values, 0, end);
    }
    return closest_sorted(values, count, target);
}

int64_t three_sum_closest(const int64_t *input, size_t length)
{
    if (input == NULL || length < 5 || length > MAX_ITEMS + 2) return INVALID_RESULT;
    const int64_t target = input[0], count_value = input[1];
    if (!fits_i32(target) || count_value < 3 || count_value > MAX_ITEMS) return INVALID_RESULT;
    const size_t count = (size_t)count_value;
    if (length != count + 2) return INVALID_RESULT;
    if (count == 3) {
        const int64_t first = input[2], second = input[3], third = input[4];
        return fits_i32(first) && fits_i32(second) && fits_i32(third)
            ? first + second + third : INVALID_RESULT;
    }
    if (count <= SHORT_ITEMS) {
        int32_t values[SHORT_ITEMS];
        return sort_and_find(input, count, target, values);
    }
    int32_t values[MAX_ITEMS];
    return sort_and_find(input, count, target, values);
}
