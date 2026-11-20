#include <array>
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t max_points = 32;
constexpr std::size_t max_input_values = 66;
constexpr std::int64_t max_coordinate = 1000;

struct Point { std::int64_t x, y; };
struct Slope { std::int64_t dy, dx; };

int compare_slope(Slope a, Slope b) {
    const auto left = a.dy * b.dx;
    const auto right = b.dy * a.dx;
    return (left > right) - (left < right);
}

void sort_ids_by_x(int* ids, std::size_t count, const Point* points) {
    for (std::size_t i = 1; i < count; ++i) {
        const int value = ids[i];
        auto j = i;
        while (j > 0 && points[ids[j - 1]].x > points[value].x) {
            ids[j] = ids[j - 1];
            --j;
        }
        ids[j] = value;
    }
}

int select_id_by_x(int* ids, std::size_t count, std::size_t rank, const Point* points) {
    if (count <= 5) {
        sort_ids_by_x(ids, count, points);
        return ids[rank];
    }
    std::array<int, max_points> medians{};
    std::size_t median_count = 0;
    for (std::size_t start = 0; start < count; start += 5) {
        const auto group = (count - start < 5) ? count - start : std::size_t{5};
        sort_ids_by_x(ids + start, group, points);
        medians[median_count++] = ids[start + (group - 1) / 2];
    }
    const int pivot = select_id_by_x(medians.data(), median_count,
                                     (median_count - 1) / 2, points);
    std::size_t lower = 0, cursor = 0, upper = count;
    while (cursor < upper) {
        if (points[ids[cursor]].x < points[pivot].x) {
            const int tmp = ids[lower]; ids[lower] = ids[cursor]; ids[cursor] = tmp;
            ++lower; ++cursor;
        } else if (points[ids[cursor]].x > points[pivot].x) {
            --upper;
            const int tmp = ids[upper]; ids[upper] = ids[cursor]; ids[cursor] = tmp;
        } else {
            ++cursor;
        }
    }
    if (rank < lower) return select_id_by_x(ids, lower, rank, points);
    if (rank < upper) return pivot;
    return select_id_by_x(ids + upper, count - upper, rank - upper, points);
}

void sort_slopes(Slope* values, std::size_t count) {
    for (std::size_t i = 1; i < count; ++i) {
        const Slope value = values[i];
        auto j = i;
        while (j > 0 && compare_slope(values[j - 1], value) > 0) {
            values[j] = values[j - 1];
            --j;
        }
        values[j] = value;
    }
}

Slope select_slope(Slope* values, std::size_t count, std::size_t rank) {
    if (count <= 5) {
        sort_slopes(values, count);
        return values[rank];
    }
    std::array<Slope, max_points> medians{};
    std::size_t median_count = 0;
    for (std::size_t start = 0; start < count; start += 5) {
        const auto group = (count - start < 5) ? count - start : std::size_t{5};
        sort_slopes(values + start, group);
        medians[median_count++] = values[start + (group - 1) / 2];
    }
    const auto pivot = select_slope(medians.data(), median_count,
                                    (median_count - 1) / 2);
    std::size_t lower = 0, cursor = 0, upper = count;
    while (cursor < upper) {
        const int order = compare_slope(values[cursor], pivot);
        if (order < 0) {
            const auto tmp = values[lower]; values[lower] = values[cursor]; values[cursor] = tmp;
            ++lower; ++cursor;
        } else if (order > 0) {
            --upper;
            const auto tmp = values[upper]; values[upper] = values[cursor]; values[cursor] = tmp;
        } else {
            ++cursor;
        }
    }
    if (rank < lower) return select_slope(values, lower, rank);
    if (rank < upper) return pivot;
    return select_slope(values + upper, count - upper, rank - upper);
}

Slope pair_slope(int first, int second, const Point* points) {
    if (points[first].x > points[second].x) {
        const int tmp = first; first = second; second = tmp;
    }
    return {points[second].y - points[first].y,
            points[second].x - points[first].x};
}

void upper_bridge(const Point* points, int* candidates, std::size_t& candidate_count,
                  std::int64_t separator, int& left_out, int& right_out) {
    auto count = candidate_count;
    while (count > 2) {
        const auto pair_count = count / 2;
        std::array<Slope, max_points> slopes{};
        for (std::size_t pair = 0; pair < pair_count; ++pair)
            slopes[pair] = pair_slope(candidates[2 * pair], candidates[2 * pair + 1], points);
        const auto median = select_slope(slopes.data(), pair_count, (pair_count - 1) / 2);

        auto maximum = std::numeric_limits<std::int64_t>::min();
        for (std::size_t i = 0; i < count; ++i) {
            const auto p = points[candidates[i]];
            const auto score = p.y * median.dx - median.dy * p.x;
            if (score > maximum) maximum = score;
        }
        int left = -1, right = -1;
        for (std::size_t i = 0; i < count; ++i) {
            const int id = candidates[i];
            const auto p = points[id];
            if (p.y * median.dx - median.dy * p.x == maximum) {
                if (left < 0 || p.x < points[left].x) left = id;
                if (right < 0 || p.x > points[right].x) right = id;
            }
        }
        if (points[left].x <= separator && separator < points[right].x) {
            left_out = left; right_out = right; candidate_count = count;
            return;
        }

        const bool support_is_left = points[right].x <= separator;
        std::array<int, max_points> next{};
        std::size_t next_count = 0;
        for (std::size_t pair = 0; pair < pair_count; ++pair) {
            const int first = candidates[2 * pair], second = candidates[2 * pair + 1];
            const int order = compare_slope(pair_slope(first, second, points), median);
            bool keep_first, keep_second;
            if (support_is_left) {
                keep_first = keep_second = order < 0;
                if (order >= 0) {
                    keep_first = points[first].x > points[second].x;
                    keep_second = points[second].x > points[first].x;
                }
            } else {
                keep_first = keep_second = order > 0;
                if (order <= 0) {
                    keep_first = points[first].x < points[second].x;
                    keep_second = points[second].x < points[first].x;
                }
            }
            if (keep_first) next[next_count++] = first;
            if (keep_second) next[next_count++] = second;
        }
        if (count % 2 != 0) next[next_count++] = candidates[count - 1];
        for (std::size_t i = 0; i < next_count; ++i) candidates[i] = next[i];
        count = next_count;
    }
    if (points[candidates[0]].x < points[candidates[1]].x) {
        left_out = candidates[0]; right_out = candidates[1];
    } else {
        left_out = candidates[1]; right_out = candidates[0];
    }
    candidate_count = count;
}

void append_unique(int* chain, std::size_t& length, int point) {
    if (length == 0 || chain[length - 1] != point) chain[length++] = point;
}

void connect_upper(const Point* points, const int* candidates, std::size_t count,
                   int left_endpoint, int right_endpoint,
                   int* chain, std::size_t& chain_length) {
    if (left_endpoint == right_endpoint) {
        append_unique(chain, chain_length, left_endpoint);
        return;
    }
    std::array<int, max_points> median_ids{};
    std::array<int, max_points> mutable_candidates{};
    for (std::size_t i = 0; i < count; ++i) {
        median_ids[i] = candidates[i];
        mutable_candidates[i] = candidates[i];
    }
    const int median_point = select_id_by_x(median_ids.data(), count,
                                             (count - 1) / 2, points);
    const auto separator = points[median_point].x;
    auto mutable_count = count;
    int bridge_left, bridge_right;
    upper_bridge(points, mutable_candidates.data(), mutable_count, separator,
                 bridge_left, bridge_right);

    std::array<int, max_points> left_set{}, right_set{};
    std::size_t left_count = 0, right_count = 0;
    for (std::size_t i = 0; i < count; ++i) {
        const int id = candidates[i];
        if (points[id].x <= points[bridge_left].x) left_set[left_count++] = id;
        if (points[id].x >= points[bridge_right].x) right_set[right_count++] = id;
    }
    connect_upper(points, left_set.data(), left_count, left_endpoint, bridge_left,
                  chain, chain_length);
    append_unique(chain, chain_length, bridge_right);
    connect_upper(points, right_set.data(), right_count, bridge_right, right_endpoint,
                  chain, chain_length);
}

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t kirkpatrick_seidel_convex_hull(
    const std::int64_t* values, std::size_t length,
    std::uint8_t* output, std::size_t capacity) {
    if (values == nullptr || length < 1 || length > max_input_values) return -1;
    if (values[0] < 3 || values[0] > static_cast<std::int64_t>(max_points)) return -1;
    const auto count = static_cast<std::size_t>(values[0]);
    if (length != 1 + 2 * count) return -1;

    std::array<Point, max_points> original{}, upper_points{}, lower_points{};
    std::array<bool, 2 * max_coordinate + 1> seen_x{};
    for (std::size_t i = 0; i < count; ++i) {
        const auto x = values[1 + 2 * i], y = values[2 + 2 * i];
        if (x < -max_coordinate || x > max_coordinate ||
            y < -max_coordinate || y > max_coordinate || seen_x[x + max_coordinate]) return -1;
        seen_x[x + max_coordinate] = true;
        original[i] = {x, y}; upper_points[i] = {x, y}; lower_points[i] = {x, -y};
    }
    bool non_collinear = false;
    for (std::size_t i = 2; i < count; ++i) {
        const auto cross = (original[1].x - original[0].x) * (original[i].y - original[0].y)
                         - (original[1].y - original[0].y) * (original[i].x - original[0].x);
        if (cross != 0) { non_collinear = true; break; }
    }
    if (!non_collinear) return -1;

    std::array<int, max_points> ids{}, upper{}, lower{}, hull{};
    std::size_t left_index = 0, right_index = 0;
    for (std::size_t i = 0; i < count; ++i) {
        ids[i] = static_cast<int>(i);
        if (original[i].x < original[left_index].x) left_index = i;
        if (original[i].x > original[right_index].x) right_index = i;
    }
    std::size_t upper_count = 0, lower_count = 0;
    connect_upper(upper_points.data(), ids.data(), count, static_cast<int>(left_index),
                  static_cast<int>(right_index), upper.data(), upper_count);
    connect_upper(lower_points.data(), ids.data(), count, static_cast<int>(left_index),
                  static_cast<int>(right_index), lower.data(), lower_count);
    std::size_t hull_count = 0;
    for (std::size_t i = 0; i < lower_count; ++i) append_unique(hull.data(), hull_count, lower[i]);
    for (std::size_t i = upper_count - 1; i > 1; --i)
        append_unique(hull.data(), hull_count, upper[i - 1]);

    const auto byte_count = 16 * hull_count;
    if (output == nullptr || capacity < byte_count) return -2;
    for (std::size_t i = 0; i < hull_count; ++i) {
        const auto p = original[hull[i]];
        store_i64_le(output, 16 * i, p.x);
        store_i64_le(output, 16 * i + 8, p.y);
    }
    return static_cast<std::int64_t>(byte_count);
}
