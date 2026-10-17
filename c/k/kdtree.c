#include <stddef.h>
#include <stdint.h>

#define MAX_INITIAL_POINTS 64u
#define MAX_POINTS 128u
#define MAX_OPERATIONS 256u
#define MAX_PARSEABLE_INPUT_VALUES 899u
#define MIN_COORDINATE INT64_C(-1000)
#define MAX_COORDINATE INT64_C(1000)
#define CHECKSUM_OFFSET INT64_C(1001)

typedef struct {
    int64_t x;
    int64_t y;
} Point;

typedef struct {
    int64_t x;
    int64_t y;
    int left;
    int right;
    int axis;
} Node;

static int64_t coordinate(Point point, int axis)
{
    return axis == 0 ? point.x : point.y;
}

static void sort_points(Point *points, size_t start, size_t end, int axis)
{
    for (size_t index = start + 1u; index < end; ++index) {
        const Point value = points[index];
        size_t position = index;
        while (position > start && coordinate(points[position - 1u], axis) > coordinate(value, axis)) {
            points[position] = points[position - 1u];
            --position;
        }
        points[position] = value;
    }
}

static int build_tree(Point *points, size_t start, size_t end, size_t depth,
                      Node *nodes, size_t *used)
{
    if (start >= end) return -1;
    const int axis = (int)(depth & 1u);
    sort_points(points, start, end, axis);
    const size_t middle = start + (end - start) / 2u;
    const size_t node_index = (*used)++;
    nodes[node_index].x = points[middle].x;
    nodes[node_index].y = points[middle].y;
    nodes[node_index].axis = axis;
    nodes[node_index].left = build_tree(points, start, middle, depth + 1u, nodes, used);
    nodes[node_index].right = build_tree(points, middle + 1u, end, depth + 1u, nodes, used);
    return (int)node_index;
}

static int insert_point(Node *nodes, size_t *used, int root, Point point)
{
    if (root < 0) {
        const size_t index = (*used)++;
        nodes[index].x = point.x;
        nodes[index].y = point.y;
        nodes[index].left = -1;
        nodes[index].right = -1;
        nodes[index].axis = 0;
        return (int)index;
    }

    int current = root;
    for (;;) {
        const int axis = nodes[current].axis;
        const int goes_left = coordinate(point, axis) < (axis == 0 ? nodes[current].x : nodes[current].y);
        int *child = goes_left ? &nodes[current].left : &nodes[current].right;
        if (*child < 0) {
            const size_t index = (*used)++;
            nodes[index].x = point.x;
            nodes[index].y = point.y;
            nodes[index].left = -1;
            nodes[index].right = -1;
            nodes[index].axis = 1 - axis;
            *child = (int)index;
            return root;
        }
        current = *child;
    }
}

static int find_point(const Node *nodes, int root, Point point)
{
    if (root < 0) return 0;
    const Node *node = &nodes[root];
    if (node->x == point.x && node->y == point.y) return 1;
    const int64_t query_coordinate = node->axis == 0 ? point.x : point.y;
    const int64_t node_coordinate = node->axis == 0 ? node->x : node->y;
    return find_point(nodes, query_coordinate < node_coordinate ? node->left : node->right, point);
}

static int64_t distance_squared(const Node *node, Point query)
{
    const int64_t dx = node->x - query.x;
    const int64_t dy = node->y - query.y;
    return dx * dx + dy * dy;
}

static int64_t distance_except_axis(const Node *node, Point query)
{
    const int64_t difference = node->axis == 0 ? node->y - query.y : node->x - query.x;
    return difference * difference;
}

static int find_nearest(const Node *nodes, int root, Point query, int nearest)
{
    if (root < 0) return nearest;
    const Node *node = &nodes[root];
    if (node->x == query.x && node->y == query.y) return root;

    if (distance_squared(node, query) < distance_squared(&nodes[nearest], query)) nearest = root;
    const int64_t query_coordinate = node->axis == 0 ? query.x : query.y;
    const int64_t node_coordinate = node->axis == 0 ? node->x : node->y;
    const int query_goes_left = query_coordinate < node_coordinate;
    const int near = query_goes_left ? node->left : node->right;
    const int far = query_goes_left ? node->right : node->left;
    nearest = find_nearest(nodes, near, query, nearest);
    if (distance_except_axis(node, query) < distance_squared(&nodes[nearest], query))
        nearest = find_nearest(nodes, far, query, nearest);
    return nearest;
}

int64_t kdtree_benchmark(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2u || length > MAX_PARSEABLE_INPUT_VALUES) return -1;
    if (input[0] < 0 || input[0] > (int64_t)MAX_INITIAL_POINTS) return -1;
    const size_t initial_count = (size_t)input[0];
    size_t cursor = 1u;
    if (cursor + 2u * initial_count + 1u > length) return -1;

    Point points[MAX_INITIAL_POINTS] = {{0, 0}};
    int seen_x[2001] = {0};
    int seen_y[2001] = {0};
    for (size_t index = 0u; index < initial_count; ++index) {
        const int64_t x = input[cursor++];
        const int64_t y = input[cursor++];
        if (x < MIN_COORDINATE || x > MAX_COORDINATE || y < MIN_COORDINATE || y > MAX_COORDINATE)
            return -1;
        const size_t x_index = (size_t)(x - MIN_COORDINATE);
        const size_t y_index = (size_t)(y - MIN_COORDINATE);
        if (seen_x[x_index] || seen_y[y_index]) return -1;
        seen_x[x_index] = 1;
        seen_y[y_index] = 1;
        points[index] = (Point){x, y};
    }

    const int64_t operation_count_value = input[cursor++];
    if (operation_count_value < 0 || operation_count_value > (int64_t)MAX_OPERATIONS) return -1;
    const size_t operation_count = (size_t)operation_count_value;
    if (cursor + 3u * operation_count != length) return -1;

    Node nodes[MAX_POINTS] = {{0, 0, -1, -1, 0}};
    size_t node_count = 0u;
    int root = build_tree(points, 0u, initial_count, 0u, nodes, &node_count);
    int64_t checksum = 0;

    for (size_t operation = 0u; operation < operation_count; ++operation) {
        const int64_t opcode = input[cursor++];
        const int64_t first = input[cursor++];
        const int64_t second = input[cursor++];
        int64_t result = 0;
        int has_result = 1;

        if (opcode == 0 || opcode == 1 || opcode == 4) {
            if (first < MIN_COORDINATE || first > MAX_COORDINATE ||
                second < MIN_COORDINATE || second > MAX_COORDINATE) return -1;
            const size_t x_index = (size_t)(first - MIN_COORDINATE);
            const size_t y_index = (size_t)(second - MIN_COORDINATE);
            const Point query = {first, second};
            if (opcode == 0) {
                if (node_count >= MAX_POINTS || seen_x[x_index] || seen_y[y_index]) return -1;
                seen_x[x_index] = 1;
                seen_y[y_index] = 1;
                root = insert_point(nodes, &node_count, root, query);
                has_result = 0;
            } else if (opcode == 1) {
                result = find_point(nodes, root, query);
            } else {
                if (root < 0) return -1;
                const int nearest = find_nearest(nodes, root, query, root);
                result = distance_squared(&nodes[nearest], query);
            }
        } else if (opcode == 2 || opcode == 3) {
            if ((first != 0 && first != 1) || second != 0 || root < 0) return -1;
            const int axis = (int)first;
            result = axis == 0 ? nodes[0].x : nodes[0].y;
            for (size_t index = 1u; index < node_count; ++index) {
                const int64_t value = axis == 0 ? nodes[index].x : nodes[index].y;
                if (opcode == 2 ? value < result : value > result) result = value;
            }
        } else {
            return -1;
        }

        if (has_result) result += CHECKSUM_OFFSET;
        if (has_result) checksum += (int64_t)(operation + 1u) * result;
    }
    return checksum;
}
