module kdtree;

const usz MAX_INITIAL_POINTS = 64;
const usz MAX_POINTS = 128;
const usz MAX_OPERATIONS = 256;
const usz MAX_PARSEABLE_INPUT_VALUES = 899;
const long MIN_COORDINATE = -1_000;
const long MAX_COORDINATE = 1_000;
const long CHECKSUM_OFFSET = 1_001;

struct Point { long x; long y; }
struct Node { long x; long y; int left; int right; int axis; }

fn long coordinate(Point point, int axis) {
    return axis == 0 ? point.x : point.y;
}

fn void sort_points(Point* points, usz start, usz end, int axis) {
    for (usz index = start + 1; index < end; index++) {
        Point value = points[index];
        usz position = index;
        while (position > start && coordinate(points[position - 1], axis) > coordinate(value, axis)) {
            points[position] = points[position - 1];
            position--;
        }
        points[position] = value;
    }
}

fn int build_tree(Point* points, usz start, usz end, usz depth, Node* nodes, usz* used) {
    if (start >= end) return -1;
    int axis = (int)(depth & 1);
    sort_points(points, start, end, axis);
    usz middle = start + (end - start) / 2;
    int node_index = (int)*used;
    *used = *used + 1;
    nodes[node_index].x = points[middle].x;
    nodes[node_index].y = points[middle].y;
    nodes[node_index].axis = axis;
    nodes[node_index].left = build_tree(points, start, middle, depth + 1, nodes, used);
    nodes[node_index].right = build_tree(points, middle + 1, end, depth + 1, nodes, used);
    return node_index;
}

fn int insert_point(Node* nodes, usz* used, int root, Point point) {
    if (root < 0) {
        int index = (int)*used;
        *used = *used + 1;
        nodes[index].x = point.x;
        nodes[index].y = point.y;
        nodes[index].left = -1;
        nodes[index].right = -1;
        nodes[index].axis = 0;
        return index;
    }
    int current = root;
    while (true) {
        int axis = nodes[current].axis;
        long point_coordinate = coordinate(point, axis);
        long node_coordinate = axis == 0 ? nodes[current].x : nodes[current].y;
        bool goes_left = point_coordinate < node_coordinate;
        int child = goes_left ? nodes[current].left : nodes[current].right;
        if (child < 0) {
            int index = (int)*used;
            *used = *used + 1;
            nodes[index].x = point.x;
            nodes[index].y = point.y;
            nodes[index].left = -1;
            nodes[index].right = -1;
            nodes[index].axis = 1 - axis;
            if (goes_left) nodes[current].left = index;
            else nodes[current].right = index;
            return root;
        }
        current = child;
    }
}

fn bool find_point(Node* nodes, int root, Point point) {
    if (root < 0) return false;
    if (nodes[root].x == point.x && nodes[root].y == point.y) return true;
    int axis = nodes[root].axis;
    long point_coordinate = coordinate(point, axis);
    long node_coordinate = axis == 0 ? nodes[root].x : nodes[root].y;
    int child = point_coordinate < node_coordinate ? nodes[root].left : nodes[root].right;
    return find_point(nodes, child, point);
}

fn long distance_squared(Node* nodes, int node_index, Point query) {
    long dx = nodes[node_index].x - query.x;
    long dy = nodes[node_index].y - query.y;
    return dx * dx + dy * dy;
}

fn long distance_except_axis(Node* nodes, int node_index, Point query) {
    long difference = nodes[node_index].axis == 0
        ? nodes[node_index].y - query.y
        : nodes[node_index].x - query.x;
    return difference * difference;
}

fn int find_nearest(Node* nodes, int root, Point query, int nearest) {
    if (root < 0) return nearest;
    if (nodes[root].x == query.x && nodes[root].y == query.y) return root;
    if (distance_squared(nodes, root, query) < distance_squared(nodes, nearest, query)) nearest = root;

    int axis = nodes[root].axis;
    long query_coordinate = coordinate(query, axis);
    long node_coordinate = axis == 0 ? nodes[root].x : nodes[root].y;
    bool query_goes_left = query_coordinate < node_coordinate;
    int near = query_goes_left ? nodes[root].left : nodes[root].right;
    int far = query_goes_left ? nodes[root].right : nodes[root].left;
    nearest = find_nearest(nodes, near, query, nearest);
    if (distance_except_axis(nodes, root, query) < distance_squared(nodes, nearest, query))
        nearest = find_nearest(nodes, far, query, nearest);
    return nearest;
}

fn long kdtree_benchmark(long* input, usz length) @export("kdtree_benchmark") {
    if (input == null || length < 2 || length > MAX_PARSEABLE_INPUT_VALUES) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_INITIAL_POINTS) return -1;
    usz initial_count = (usz)input[0];
    usz cursor = 1;
    if (cursor + 2 * initial_count + 1 > length) return -1;

    Point[MAX_INITIAL_POINTS] points = {};
    int[2001] seen_x = zeroed;
    int[2001] seen_y = zeroed;
    for (usz index = 0; index < initial_count; index++) {
        long x = input[cursor++];
        long y = input[cursor++];
        if (x < MIN_COORDINATE || x > MAX_COORDINATE || y < MIN_COORDINATE || y > MAX_COORDINATE) return -1;
        usz x_index = (usz)(x - MIN_COORDINATE);
        usz y_index = (usz)(y - MIN_COORDINATE);
        if (seen_x[x_index] != 0 || seen_y[y_index] != 0) return -1;
        seen_x[x_index] = 1;
        seen_y[y_index] = 1;
        points[index] = Point{x, y};
    }

    long operation_count_value = input[cursor++];
    if (operation_count_value < 0 || operation_count_value > (long)MAX_OPERATIONS) return -1;
    usz operation_count = (usz)operation_count_value;
    if (cursor + 3 * operation_count != length) return -1;

    Node[MAX_POINTS] nodes = {};
    usz node_count = 0;
    int root = build_tree(&points[0], 0, initial_count, 0, &nodes[0], &node_count);
    long checksum = 0;
    for (usz operation = 0; operation < operation_count; operation++) {
        long opcode = input[cursor++];
        long first = input[cursor++];
        long second = input[cursor++];
        long result = 0;
        bool has_result = true;

        if (opcode == 0 || opcode == 1 || opcode == 4) {
            if (first < MIN_COORDINATE || first > MAX_COORDINATE ||
                second < MIN_COORDINATE || second > MAX_COORDINATE) return -1;
            usz x_index = (usz)(first - MIN_COORDINATE);
            usz y_index = (usz)(second - MIN_COORDINATE);
            Point query = Point{first, second};
            if (opcode == 0) {
                if (node_count >= MAX_POINTS || seen_x[x_index] != 0 || seen_y[y_index] != 0) return -1;
                seen_x[x_index] = 1;
                seen_y[y_index] = 1;
                root = insert_point(&nodes[0], &node_count, root, query);
                has_result = false;
            } else if (opcode == 1) {
                result = find_point(&nodes[0], root, query) ? 1 : 0;
            } else {
                if (root < 0) return -1;
                int nearest = find_nearest(&nodes[0], root, query, root);
                result = distance_squared(&nodes[0], nearest, query);
            }
        } else if (opcode == 2 || opcode == 3) {
            if ((first != 0 && first != 1) || second != 0 || root < 0) return -1;
            int axis = (int)first;
            result = axis == 0 ? nodes[0].x : nodes[0].y;
            for (usz index = 1; index < node_count; index++) {
                long value = axis == 0 ? nodes[index].x : nodes[index].y;
                if (opcode == 2 ? value < result : value > result) result = value;
            }
        } else {
            return -1;
        }

        if (has_result) checksum += (long)(operation + 1) * (result + CHECKSUM_OFFSET);
    }
    return checksum;
}
