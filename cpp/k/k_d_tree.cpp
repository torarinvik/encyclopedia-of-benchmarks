#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <utility>
#include <vector>

namespace {
constexpr std::int64_t invalid_result = -1;
constexpr std::int64_t output_error = -2;
struct Node { std::size_t point; int left, right; };

std::size_t partition_five(std::vector<std::size_t>& ids,
                           const std::vector<std::vector<double>>& points,
                           std::size_t from, std::size_t to, std::size_t axis)
{
    const std::size_t middle = (from + to) / 2;
    for (std::size_t i = from; i <= middle; ++i) {
        std::size_t minimum = i;
        for (std::size_t j = i + 1; j <= to; ++j)
            if (points[ids[j]][axis] < points[ids[minimum]][axis]) minimum = j;
        std::swap(ids[i], ids[minimum]);
    }
    return middle;
}

std::size_t select_kth(std::vector<std::size_t>& ids,
                       const std::vector<std::vector<double>>& points,
                       std::size_t from, std::size_t to, std::size_t rank, std::size_t axis);

std::size_t choose_median_of_medians(std::vector<std::size_t>& ids,
                                     const std::vector<std::vector<double>>& points,
                                     std::size_t from, std::size_t to, std::size_t axis)
{
    if (to - from < 5) return partition_five(ids, points, from, to, axis);
    std::size_t medians_to = from;
    for (std::size_t start = from; start <= to - 4; start += 5) {
        const std::size_t median = partition_five(ids, points, start, start + 4, axis);
        std::swap(ids[median], ids[medians_to++]);
    }
    const std::size_t remainder = (to - from + 1) % 5;
    if (remainder == 0) {
        --medians_to;
    } else {
        const std::size_t median = partition_five(ids, points, to - remainder + 1, to, axis);
        std::swap(ids[median], ids[medians_to]);
    }
    const std::size_t medians_count = medians_to - from + 1;
    return select_kth(ids, points, from, medians_to, (medians_count + 1) / 2, axis);
}

std::pair<std::ptrdiff_t, std::size_t> partition_three_way(
    std::vector<std::size_t>& ids, const std::vector<std::vector<double>>& points,
    std::size_t from, std::size_t to, std::size_t pivot_index, std::size_t axis)
{
    const double pivot = points[ids[pivot_index]][axis];
    std::size_t i = from, j = from, k = to;
    while (j <= k) {
        const double value = points[ids[j]][axis];
        if (value < pivot) { std::swap(ids[i++], ids[j++]); }
        else if (pivot < value) {
            std::swap(ids[j], ids[k]);
            if (k == 0) break;
            --k;
        } else { ++j; }
    }
    return {static_cast<std::ptrdiff_t>(i) - 1, k + 1};
}

std::size_t select_kth(std::vector<std::size_t>& ids,
                       const std::vector<std::vector<double>>& points,
                       std::size_t from, std::size_t to, std::size_t rank, std::size_t axis)
{
    while (from < to) {
        const std::size_t pivot = choose_median_of_medians(ids, points, from, to, axis);
        const auto [smaller_to, larger_from] = partition_three_way(ids, points, from, to, pivot, axis);
        const std::size_t absolute_index = from + rank - 1;
        if (static_cast<std::ptrdiff_t>(absolute_index) <= smaller_to) to = static_cast<std::size_t>(smaller_to);
        else if (absolute_index < larger_from) return absolute_index;
        else { rank -= larger_from - from; from = larger_from; }
    }
    return from;
}

int build_tree(const std::vector<std::vector<double>>& points,
               const std::vector<std::size_t>& indices, std::size_t dimension,
               std::size_t depth, std::vector<Node>& nodes)
{
    if (indices.empty()) return -1;
    const std::size_t axis = depth % dimension;
    std::vector<std::size_t> ordered = indices;
    const std::size_t middle = select_kth(ordered, points, 0, ordered.size() - 1,
                                          (ordered.size() + 1) / 2, axis);
    const int current = static_cast<int>(nodes.size());
    nodes.push_back(Node{ordered[middle], -1, -1});
    std::vector<std::size_t> left(ordered.begin(), ordered.begin() + static_cast<std::ptrdiff_t>(middle));
    std::vector<std::size_t> right(ordered.begin() + static_cast<std::ptrdiff_t>(middle + 1), ordered.end());
    nodes[static_cast<std::size_t>(current)].left = build_tree(points, left, dimension, depth + 1, nodes);
    nodes[static_cast<std::size_t>(current)].right = build_tree(points, right, dimension, depth + 1, nodes);
    return current;
}

void search_tree(const std::vector<std::vector<double>>& points, const std::vector<Node>& nodes,
                 int current, std::size_t axis, const std::vector<double>& query,
                 std::size_t dimension, double& best, std::size_t& best_point)
{
    if (current < 0) return;
    const Node& node = nodes[static_cast<std::size_t>(current)];
    const auto& point = points[node.point];
    double squared = 0.0;
    for (std::size_t a = 0; a < dimension; ++a) {
        const double delta = query[a] - point[a];
        squared += delta * delta;
    }
    const double distance = std::sqrt(squared);
    if (distance < best) { best = distance; best_point = node.point; }
    const bool go_left = query[axis] <= point[axis];
    const int near = go_left ? node.left : node.right;
    const int far = go_left ? node.right : node.left;
    const std::size_t next_axis = (axis + 1) % dimension;
    search_tree(points, nodes, near, next_axis, query, dimension, best, best_point);
    if (best >= std::abs(point[axis] - query[axis]))
        search_tree(points, nodes, far, next_axis, query, dimension, best, best_point);
}
}

extern "C" std::int64_t k_d_tree(const double *input, std::size_t length,
                                  double *output, std::size_t output_capacity)
{
    if (input == nullptr || length == 0 || length > 51 || length < 2) return invalid_result;
    if (!std::isfinite(input[0]) || std::floor(input[0]) != input[0] ||
        (input[0] != 2.0 && input[0] != 3.0)) return invalid_result;
    const std::size_t dimension = static_cast<std::size_t>(input[0]);
    if (!std::isfinite(input[1]) || std::floor(input[1]) != input[1] ||
        input[1] < 1.0 || input[1] > 15.0) return invalid_result;
    const std::size_t count = static_cast<std::size_t>(input[1]);
    if (length != 2 + dimension * (count + 1)) return invalid_result;
    std::vector<double> query(dimension);
    for (std::size_t a = 0; a < dimension; ++a) {
        const double value = input[2 + a];
        if (!std::isfinite(value) || std::floor(value) != value || value < -1000.0 || value > 1000.0)
            return invalid_result;
        query[a] = value;
    }
    std::vector<std::vector<double>> points(count, std::vector<double>(dimension));
    const std::size_t offset = 2 + dimension;
    for (std::size_t i = 0; i < count; ++i) {
        for (std::size_t a = 0; a < dimension; ++a) {
            const double value = input[offset + i * dimension + a];
            if (!std::isfinite(value) || std::floor(value) != value || value < -1000.0 || value > 1000.0)
                return invalid_result;
            points[i][a] = value;
        }
    }
    for (std::size_t a = 0; a < dimension; ++a)
        for (std::size_t i = 0; i < count; ++i)
            for (std::size_t j = i + 1; j < count; ++j)
                if (points[i][a] == points[j][a]) return invalid_result;

    double smallest_squared = INFINITY;
    std::size_t nearest_count = 0;
    for (std::size_t i = 0; i < count; ++i) {
        double squared = 0.0;
        for (std::size_t a = 0; a < dimension; ++a) {
            const double delta = query[a] - points[i][a];
            squared += delta * delta;
        }
        if (squared < smallest_squared) { smallest_squared = squared; nearest_count = 1; }
        else if (squared == smallest_squared) ++nearest_count;
    }
    if (nearest_count != 1) return invalid_result;
    const std::size_t output_length = dimension + 1;
    if (output == nullptr || output_capacity < output_length) return output_error;

    std::vector<std::size_t> indices(count);
    for (std::size_t i = 0; i < count; ++i) indices[i] = i;
    std::vector<Node> nodes;
    nodes.reserve(count);
    const int root = build_tree(points, indices, dimension, 0, nodes);
    double best = INFINITY;
    std::size_t best_point = 0;
    search_tree(points, nodes, root, 0, query, dimension, best, best_point);
    output[0] = best;
    for (std::size_t a = 0; a < dimension; ++a) output[a + 1] = points[best_point][a];
    return static_cast<std::int64_t>(output_length);
}
