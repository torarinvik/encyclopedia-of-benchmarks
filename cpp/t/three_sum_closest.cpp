/* Closest three-value sum, using a private heapsorted copy. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_ITEMS = 512;
constexpr std::size_t SHORT_ITEMS = 16;
constexpr std::int64_t INVALID_RESULT = -9000000000000000000LL;

bool fits_i32(std::int64_t value)
{
    return value >= INT32_MIN && value <= INT32_MAX;
}

void sift_down(std::int32_t *values, std::size_t root, std::size_t count)
{
    const std::int32_t value = values[root];
    while (root < count / 2) {
        std::size_t child = root * 2 + 1;
        if (child + 1 < count && values[child] < values[child + 1]) ++child;
        if (value >= values[child]) break;
        values[root] = values[child];
        root = child;
    }
    values[root] = value;
}

std::int64_t sum_rank(std::int64_t sum, std::int64_t target)
{
    const std::int64_t delta = sum - target;
    return delta < 0 ? -2 * delta : 2 * delta + 1;
}

std::int64_t ranked_sum(std::int64_t rank, std::int64_t target)
{
    return (rank & 1) ? target + rank / 2 : target - rank / 2;
}

std::int64_t closest_sorted(const std::int32_t *values, std::size_t count, std::int64_t target)
{
    const std::int64_t smallest = static_cast<std::int64_t>(values[0]) + values[1] + values[2];
    if (target <= smallest) return smallest;
    const std::int64_t last_pair = static_cast<std::int64_t>(values[count - 1]) + values[count - 2];
    const std::int64_t largest = last_pair + values[count - 3];
    if (target >= largest) return largest;

    std::int64_t best_rank = sum_rank(smallest, target);
    for (std::size_t first = 0; first + 2 < count; ++first) {
        const std::int64_t fixed = values[first];
        if (first > 0 && fixed == values[first - 1]) continue;
        const std::int64_t minimum = fixed + values[first + 1] + values[first + 2];
        if (minimum >= target)
            return sum_rank(minimum, target) < best_rank ? minimum : ranked_sum(best_rank, target);
        const std::int64_t maximum = fixed + last_pair;
        if (maximum <= target) {
            const std::int64_t rank = sum_rank(maximum, target);
            if (rank < best_rank) best_rank = rank;
            continue;
        }
        std::size_t left = first + 1, right = count - 1;
        while (left < right) {
            const std::int64_t sum = fixed + values[left] + values[right];
            const std::int64_t rank = sum_rank(sum, target);
            if (rank < best_rank) best_rank = rank;
            if (sum < target) ++left;
            else if (sum > target) --right;
            else return sum;
        }
    }
    return ranked_sum(best_rank, target);
}

std::int64_t sort_and_find(const std::int64_t *input, std::size_t count, std::int64_t target, std::int32_t *values)
{
    for (std::size_t i = 0; i < count; ++i) {
        const std::int64_t value = input[i + 2];
        if (!fits_i32(value)) return INVALID_RESULT;
        values[i] = static_cast<std::int32_t>(value);
    }
    for (std::size_t start = count / 2; start > 0; --start) sift_down(values, start - 1, count);
    for (std::size_t end = count; end > 1;) {
        --end;
        const std::int32_t value = values[0];
        values[0] = values[end];
        values[end] = value;
        sift_down(values, 0, end);
    }
    return closest_sorted(values, count, target);
}

}

extern "C" std::int64_t three_sum_closest(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length < 5 || length > MAX_ITEMS + 2) return INVALID_RESULT;
    const std::int64_t target = input[0], count_value = input[1];
    if (!fits_i32(target) || count_value < 3 || count_value > static_cast<std::int64_t>(MAX_ITEMS)) return INVALID_RESULT;
    const std::size_t count = static_cast<std::size_t>(count_value);
    if (length != count + 2) return INVALID_RESULT;
    if (count == 3) {
        const std::int64_t first = input[2], second = input[3], third = input[4];
        return fits_i32(first) && fits_i32(second) && fits_i32(third)
            ? first + second + third : INVALID_RESULT;
    }
    if (count <= SHORT_ITEMS) {
        std::int32_t values[SHORT_ITEMS];
        return sort_and_find(input, count, target, values);
    }
    std::int32_t values[MAX_ITEMS];
    return sort_and_find(input, count, target, values);
}
