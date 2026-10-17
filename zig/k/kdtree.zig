const MAX_INITIAL_POINTS: usize = 64;
const MAX_POINTS: usize = 128;
const MAX_OPERATIONS: usize = 256;
const MAX_VALID_INPUT_LENGTH: usize = 898;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 899;
const MIN_COORDINATE: i64 = -1_000;
const MAX_COORDINATE: i64 = 1_000;
const CHECKSUM_OFFSET: i64 = 1_001;
const NONE: usize = MAX_POINTS;

const Point = struct { x: i64 = 0, y: i64 = 0 };
const Node = struct { point: Point = .{}, axis: usize = 0, left: usize = NONE, right: usize = NONE };

fn coordinate(point: Point, axis: usize) i64 { return if (axis == 0) point.x else point.y; }

fn build(points: *[MAX_INITIAL_POINTS]Point, start: usize, length: usize, depth: usize,
         nodes: *[MAX_POINTS]Node, node_count: *usize) usize {
    if (length == 0) return NONE;
    const axis = depth % 2;
    for (start + 1..start + length) |index| {
        const value = points[index];
        var position = index;
        while (position > start and coordinate(points[position - 1], axis) > coordinate(value, axis)) {
            points[position] = points[position - 1];
            position -= 1;
        }
        points[position] = value;
    }
    const median = length / 2;
    const root = node_count.*;
    node_count.* += 1;
    nodes[root] = .{ .point = points[start + median], .axis = axis, .left = NONE, .right = NONE };
    const left = build(points, start, median, depth + 1, nodes, node_count);
    const right = build(points, start + median + 1, length - median - 1, depth + 1, nodes, node_count);
    nodes[root].left = left;
    nodes[root].right = right;
    return root;
}

fn insert(nodes: *[MAX_POINTS]Node, node_count: *usize, root: usize, point: Point, depth: usize) usize {
    if (root == NONE) {
        const index = node_count.*;
        node_count.* += 1;
        nodes[index] = .{ .point = point, .axis = depth % 2, .left = NONE, .right = NONE };
        return index;
    }
    const axis = nodes[root].axis;
    if (coordinate(point, axis) < coordinate(nodes[root].point, axis)) {
        nodes[root].left = insert(nodes, node_count, nodes[root].left, point, depth + 1);
    } else {
        nodes[root].right = insert(nodes, node_count, nodes[root].right, point, depth + 1);
    }
    return root;
}

fn search(nodes: *const [MAX_POINTS]Node, root: usize, point: Point) bool {
    if (root == NONE) return false;
    if (nodes[root].point.x == point.x and nodes[root].point.y == point.y) return true;
    const axis = nodes[root].axis;
    if (coordinate(point, axis) < coordinate(nodes[root].point, axis)) return search(nodes, nodes[root].left, point);
    return search(nodes, nodes[root].right, point);
}

fn distanceSquared(left: Point, right: Point) i64 {
    const dx = left.x - right.x;
    const dy = left.y - right.y;
    return dx * dx + dy * dy;
}

fn nearest(nodes: *const [MAX_POINTS]Node, root: usize, query: Point, best_arg: usize) usize {
    if (root == NONE) return best_arg;
    if (nodes[root].point.x == query.x and nodes[root].point.y == query.y) return root;
    const point = nodes[root].point;
    const axis = nodes[root].axis;
    const distance = distanceSquared(point, query);
    const dx = point.x - query.x;
    const dy = point.y - query.y;
    const distance_except_axis = if (axis == 0) dy * dy else dx * dx;
    var best = best_arg;
    if (distance < distanceSquared(nodes[best].point, query)) best = root;
    const query_left = coordinate(query, axis) < coordinate(point, axis);
    const near = if (query_left) nodes[root].left else nodes[root].right;
    const far = if (query_left) nodes[root].right else nodes[root].left;
    best = nearest(nodes, near, query, best);
    if (distance_except_axis < distanceSquared(nodes[best].point, query)) best = nearest(nodes, far, query, best);
    return best;
}

export fn kdtree_benchmark(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > MAX_INITIAL_POINTS) return -1;
    const initial_count: usize = @intCast(input[0]);
    const operation_count_index = 1 + 2 * initial_count;
    if (operation_count_index >= length) return -1;
    const operation_count_value = input[operation_count_index];
    if (operation_count_value < 0 or operation_count_value > MAX_OPERATIONS) return -1;
    const operation_count: usize = @intCast(operation_count_value);
    if (length != operation_count_index + 1 + 3 * operation_count or length > MAX_VALID_INPUT_LENGTH) return -1;

    var points: [MAX_INITIAL_POINTS]Point = @splat(.{});
    for (0..initial_count) |index| {
        const point = Point{ .x = input[1 + 2 * index], .y = input[2 + 2 * index] };
        if (point.x < MIN_COORDINATE or point.x > MAX_COORDINATE or point.y < MIN_COORDINATE or point.y > MAX_COORDINATE) return -1;
        for (0..index) |previous| if (points[previous].x == point.x or points[previous].y == point.y) return -1;
        points[index] = point;
    }
    var nodes: [MAX_POINTS]Node = @splat(.{});
    var point_count: usize = 0;
    var root = NONE;
    if (initial_count > 0) root = build(&points, 0, initial_count, 0, &nodes, &point_count);

    var checksum: i64 = 0;
    const operations_start = operation_count_index + 1;
    for (0..operation_count) |operation| {
        const position = operations_start + 3 * operation;
        const opcode = input[position];
        const first = input[position + 1];
        const second = input[position + 2];
        var result: i64 = 0;
        if (opcode == 0 or opcode == 1 or opcode == 4) {
            if (first < MIN_COORDINATE or first > MAX_COORDINATE or second < MIN_COORDINATE or second > MAX_COORDINATE) return -1;
            const point = Point{ .x = first, .y = second };
            if (opcode == 0) {
                if (point_count >= MAX_POINTS) return -1;
                for (0..point_count) |index| if (nodes[index].point.x == first or nodes[index].point.y == second) return -1;
                root = insert(&nodes, &point_count, root, point, 0);
                continue;
            } else if (opcode == 1) {
                if (search(&nodes, root, point)) result = 1;
            } else {
                if (root == NONE) return -1;
                const closest = nearest(&nodes, root, point, root);
                result = distanceSquared(nodes[closest].point, point);
            }
        } else if (opcode == 2 or opcode == 3) {
            if (first < 0 or first > 1 or second != 0 or root == NONE) return -1;
            const axis: usize = @intCast(first);
            result = coordinate(nodes[0].point, axis);
            for (1..point_count) |index| {
                const value = coordinate(nodes[index].point, axis);
                if ((opcode == 2 and value < result) or (opcode == 3 and value > result)) result = value;
            }
        } else return -1;
        checksum += (@as(i64, @intCast(operation)) + 1) * (result + CHECKSUM_OFFSET);
    }
    return checksum;
}
