#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_initial_points = 64;
constexpr std::size_t max_points = 128;
constexpr std::size_t max_operations = 256;
constexpr std::size_t max_parseable_input_values = 899;
constexpr std::int64_t min_coordinate = -1'000;
constexpr std::int64_t max_coordinate = 1'000;
constexpr std::int64_t checksum_offset = 1'001;

struct Point {
    std::int64_t x;
    std::int64_t y;
};

struct Node {
    std::int64_t x;
    std::int64_t y;
    int left;
    int right;
    int axis;
};

std::int64_t coordinate(Point point, int axis)
{
    return axis == 0 ? point.x : point.y;
}

void sort_points(Point *points, std::size_t start, std::size_t end, int axis)
{
    for (std::size_t index = start + 1; index < end; ++index) {
        const Point value = points[index];
        std::size_t position = index;
        while (position > start && coordinate(points[position - 1], axis) > coordinate(value, axis)) {
            points[position] = points[position - 1];
            --position;
        }
        points[position] = value;
    }
}

int build_tree(Point *points, std::size_t start, std::size_t end, std::size_t depth,
               Node *nodes, std::size_t &used)
{
    if (start >= end) return -1;
    const int axis = static_cast<int>(depth & 1u);
    sort_points(points, start, end, axis);
    const std::size_t middle = start + (end - start) / 2;
    const std::size_t node_index = used++;
    nodes[node_index].x = points[middle].x;
    nodes[node_index].y = points[middle].y;
    nodes[node_index].axis = axis;
    nodes[node_index].left = build_tree(points, start, middle, depth + 1, nodes, used);
    nodes[node_index].right = build_tree(points, middle + 1, end, depth + 1, nodes, used);
    return static_cast<int>(node_index);
}

int insert_point(Node *nodes, std::size_t &used, int root, Point point)
{
    if (root < 0) {
        const std::size_t index = used++;
        nodes[index] = Node{point.x, point.y, -1, -1, 0};
        return static_cast<int>(index);
    }
    int current = root;
    for (;;) {
        const int axis = nodes[current].axis;
        const std::int64_t point_coordinate = coordinate(point, axis);
        const std::int64_t node_coordinate = axis == 0 ? nodes[current].x : nodes[current].y;
        const bool goes_left = point_coordinate < node_coordinate;
        int &child = goes_left ? nodes[current].left : nodes[current].right;
        if (child < 0) {
            const std::size_t index = used++;
            nodes[index] = Node{point.x, point.y, -1, -1, 1 - axis};
            child = static_cast<int>(index);
            return root;
        }
        current = child;
    }
}

bool find_point(const Node *nodes, int root, Point point)
{
    if (root < 0) return false;
    const Node &node = nodes[root];
    if (node.x == point.x && node.y == point.y) return true;
    const std::int64_t query_coordinate = node.axis == 0 ? point.x : point.y;
    const std::int64_t node_coordinate = node.axis == 0 ? node.x : node.y;
    return find_point(nodes, query_coordinate < node_coordinate ? node.left : node.right, point);
}

std::int64_t distance_squared(const Node *nodes, int node_index, Point query)
{
    const std::int64_t dx = nodes[node_index].x - query.x;
    const std::int64_t dy = nodes[node_index].y - query.y;
    return dx * dx + dy * dy;
}

std::int64_t distance_except_axis(const Node *nodes, int node_index, Point query)
{
    const std::int64_t difference = nodes[node_index].axis == 0
        ? nodes[node_index].y - query.y
        : nodes[node_index].x - query.x;
    return difference * difference;
}

int find_nearest(const Node *nodes, int root, Point query, int nearest)
{
    if (root < 0) return nearest;
    const Node &node = nodes[root];
    if (node.x == query.x && node.y == query.y) return root;
    if (distance_squared(nodes, root, query) < distance_squared(nodes, nearest, query)) nearest = root;

    const std::int64_t query_coordinate = node.axis == 0 ? query.x : query.y;
    const std::int64_t node_coordinate = node.axis == 0 ? node.x : node.y;
    const bool query_goes_left = query_coordinate < node_coordinate;
    const int near = query_goes_left ? node.left : node.right;
    const int far = query_goes_left ? node.right : node.left;
    nearest = find_nearest(nodes, near, query, nearest);
    if (distance_except_axis(nodes, root, query) < distance_squared(nodes, nearest, query))
        nearest = find_nearest(nodes, far, query, nearest);
    return nearest;
}
}

extern "C" std::int64_t kdtree_benchmark(const std::int64_t *input, std::size_t length)
{
    if (input == nullptr || length < 2 || length > max_parseable_input_values) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_initial_points)) return -1;
    const std::size_t initial_count = static_cast<std::size_t>(input[0]);
    std::size_t cursor = 1;
    if (cursor + 2 * initial_count + 1 > length) return -1;

    Point points[max_initial_points] = {};
    int seen_x[2001] = {};
    int seen_y[2001] = {};
    for (std::size_t index = 0; index < initial_count; ++index) {
        const std::int64_t x = input[cursor++];
        const std::int64_t y = input[cursor++];
        if (x < min_coordinate || x > max_coordinate || y < min_coordinate || y > max_coordinate) return -1;
        const std::size_t x_index = static_cast<std::size_t>(x - min_coordinate);
        const std::size_t y_index = static_cast<std::size_t>(y - min_coordinate);
        if (seen_x[x_index] || seen_y[y_index]) return -1;
        seen_x[x_index] = 1;
        seen_y[y_index] = 1;
        points[index] = Point{x, y};
    }

    const std::int64_t operation_count_value = input[cursor++];
    if (operation_count_value < 0 || operation_count_value > static_cast<std::int64_t>(max_operations)) return -1;
    const std::size_t operation_count = static_cast<std::size_t>(operation_count_value);
    if (cursor + 3 * operation_count != length) return -1;

    Node nodes[max_points] = {};
    std::size_t node_count = 0;
    int root = build_tree(points, 0, initial_count, 0, nodes, node_count);
    std::int64_t checksum = 0;
    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const std::int64_t opcode = input[cursor++];
        const std::int64_t first = input[cursor++];
        const std::int64_t second = input[cursor++];
        std::int64_t result = 0;
        bool has_result = true;

        if (opcode == 0 || opcode == 1 || opcode == 4) {
            if (first < min_coordinate || first > max_coordinate ||
                second < min_coordinate || second > max_coordinate) return -1;
            const std::size_t x_index = static_cast<std::size_t>(first - min_coordinate);
            const std::size_t y_index = static_cast<std::size_t>(second - min_coordinate);
            const Point query{first, second};
            if (opcode == 0) {
                if (node_count >= max_points || seen_x[x_index] || seen_y[y_index]) return -1;
                seen_x[x_index] = 1;
                seen_y[y_index] = 1;
                root = insert_point(nodes, node_count, root, query);
                has_result = false;
            } else if (opcode == 1) {
                result = find_point(nodes, root, query) ? 1 : 0;
            } else {
                if (root < 0) return -1;
                const int nearest = find_nearest(nodes, root, query, root);
                result = distance_squared(nodes, nearest, query);
            }
        } else if (opcode == 2 || opcode == 3) {
            if ((first != 0 && first != 1) || second != 0 || root < 0) return -1;
            const int axis = static_cast<int>(first);
            result = axis == 0 ? nodes[0].x : nodes[0].y;
            for (std::size_t index = 1; index < node_count; ++index) {
                const std::int64_t value = axis == 0 ? nodes[index].x : nodes[index].y;
                if (opcode == 2 ? value < result : value > result) result = value;
            }
        } else {
            return -1;
        }

        if (has_result) checksum += static_cast<std::int64_t>(operation + 1) * (result + checksum_offset);
    }
    return checksum;
}
