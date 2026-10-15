// Deterministic divide-and-conquer closest pair over bounded integer points.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_points = 1024;

struct PairResult {
    bool valid;
    std::uint64_t distance_squared;
    std::size_t first;
    std::size_t second;
};

bool before(std::size_t left, std::size_t right, const std::int64_t *points, bool by_y) noexcept
{
    if (by_y) {
        if (points[2 * left + 1] != points[2 * right + 1]) return points[2 * left + 1] < points[2 * right + 1];
        if (points[2 * left] != points[2 * right]) return points[2 * left] < points[2 * right];
    } else {
        if (points[2 * left] != points[2 * right]) return points[2 * left] < points[2 * right];
        if (points[2 * left + 1] != points[2 * right + 1]) return points[2 * left + 1] < points[2 * right + 1];
    }
    return left < right;
}

void sort_indices(std::size_t *indices, std::size_t *scratch, std::size_t begin, std::size_t end,
                  const std::int64_t *points, bool by_y) noexcept
{
    if (end - begin < 2) return;
    const auto middle = begin + (end - begin) / 2;
    sort_indices(indices, scratch, begin, middle, points, by_y);
    sort_indices(indices, scratch, middle, end, points, by_y);
    std::size_t left = begin, right = middle, out = begin;
    while (left < middle && right < end) {
        if (before(indices[right], indices[left], points, by_y)) scratch[out++] = indices[right++];
        else scratch[out++] = indices[left++];
    }
    while (left < middle) scratch[out++] = indices[left++];
    while (right < end) scratch[out++] = indices[right++];
    for (std::size_t index = begin; index < end; ++index) indices[index] = scratch[index];
}

std::uint64_t squared_distance(std::size_t left, std::size_t right, const std::int64_t *points) noexcept
{
    const auto dx = points[2 * left] - points[2 * right];
    const auto dy = points[2 * left + 1] - points[2 * right + 1];
    return static_cast<std::uint64_t>(dx * dx) + static_cast<std::uint64_t>(dy * dy);
}

PairResult choose(PairResult left, PairResult right) noexcept
{
    if (!left.valid) return right;
    if (!right.valid) return left;
    if (left.distance_squared < right.distance_squared) return left;
    if (right.distance_squared < left.distance_squared) return right;
    if (left.first < right.first || (left.first == right.first && left.second <= right.second)) return left;
    return right;
}

PairResult candidate(std::size_t left, std::size_t right, const std::int64_t *points) noexcept
{
    if (left > right) {
        const auto temporary = left;
        left = right;
        right = temporary;
    }
    return {true, squared_distance(left, right, points), left, right};
}

PairResult search(const std::size_t *x_order, std::size_t begin, std::size_t end,
                  const std::size_t *y_order, std::size_t y_count,
                  const std::size_t *rank, const std::int64_t *points) noexcept
{
    const auto count = end - begin;
    if (count <= 3) {
        PairResult best{false, 0, 0, 0};
        for (std::size_t i = begin; i < end; ++i)
            for (std::size_t j = i + 1; j < end; ++j)
                best = choose(best, candidate(x_order[i], x_order[j], points));
        return best;
    }

    const auto middle = begin + count / 2;
    std::size_t y_left[max_points], y_right[max_points];
    std::size_t left_count = 0, right_count = 0;
    for (std::size_t i = 0; i < y_count; ++i) {
        const auto point = y_order[i];
        if (rank[point] < middle) y_left[left_count++] = point;
        else y_right[right_count++] = point;
    }

    auto best = choose(search(x_order, begin, middle, y_left, left_count, rank, points),
                       search(x_order, middle, end, y_right, right_count, rank, points));

    std::size_t strip[max_points];
    std::size_t strip_count = 0;
    const auto middle_x = points[2 * x_order[middle]];
    for (std::size_t i = 0; i < y_count; ++i) {
        const auto point = y_order[i];
        const auto dx = points[2 * point] - middle_x;
        if (static_cast<std::uint64_t>(dx * dx) <= best.distance_squared) strip[strip_count++] = point;
    }
    for (std::size_t i = 0; i < strip_count; ++i) {
        for (std::size_t j = i + 1; j < strip_count; ++j) {
            const auto dy = points[2 * strip[j] + 1] - points[2 * strip[i] + 1];
            if (static_cast<std::uint64_t>(dy * dy) > best.distance_squared) break;
            best = choose(best, candidate(strip[i], strip[j], points));
        }
    }
    return best;
}

void write_pair(std::uint8_t *output, const PairResult &pair) noexcept
{
    const auto first = static_cast<std::uint32_t>(pair.first);
    const auto second = static_cast<std::uint32_t>(pair.second);
    for (std::size_t byte = 0; byte < 4; ++byte) {
        output[byte] = static_cast<std::uint8_t>(first >> (byte * 8));
        output[4 + byte] = static_cast<std::uint8_t>(second >> (byte * 8));
    }
}
}

extern "C" std::int64_t closest_pair_divide_and_conquer(
    const std::int64_t *values, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (length > 2 * max_points || length % 2 != 0 || (length != 0 && values == nullptr)) return -1;
    const auto point_count = length / 2;

    std::size_t x_order[max_points], y_order[max_points], rank[max_points], scratch[max_points];
    for (std::size_t i = 0; i < point_count; ++i) {
        const auto x = values[2 * i], y = values[2 * i + 1];
        if (x < -1'000'000'000 || x > 1'000'000'000 || y < -1'000'000'000 || y > 1'000'000'000) return -1;
        x_order[i] = i;
        y_order[i] = i;
    }
    if (point_count < 2) return 0;
    sort_indices(x_order, scratch, 0, point_count, values, false);
    for (std::size_t i = 0; i < point_count; ++i) rank[x_order[i]] = i;

    PairResult duplicate{false, 0, 0, 0};
    for (std::size_t begin = 0; begin < point_count;) {
        std::size_t end = begin + 1;
        const auto anchor = x_order[begin];
        while (end < point_count && values[2 * x_order[end]] == values[2 * anchor] &&
               values[2 * x_order[end] + 1] == values[2 * anchor + 1]) ++end;
        if (end - begin > 1) {
            std::size_t first = max_points, second = max_points;
            for (std::size_t i = begin; i < end; ++i) {
                const auto id = x_order[i];
                if (id < first) { second = first; first = id; }
                else if (id < second) second = id;
            }
            duplicate = choose(duplicate, {true, 0, first, second});
        }
        begin = end;
    }

    PairResult best;
    if (duplicate.valid) {
        best = duplicate;
    } else {
        sort_indices(y_order, scratch, 0, point_count, values, true);
        best = search(x_order, 0, point_count, y_order, point_count, rank, values);
    }
    if (!best.valid) return -1;
    if (output == nullptr || output_capacity < 8) return -2;
    write_pair(output, best);
    return 2;
}
