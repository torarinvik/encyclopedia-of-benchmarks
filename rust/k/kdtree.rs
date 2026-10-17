const MAX_INITIAL_POINTS: usize = 64;
const MAX_POINTS: usize = 128;
const MAX_OPERATIONS: usize = 256;
const MAX_VALID_INPUT_LENGTH: usize = 898;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 899;
const MIN_COORDINATE: i64 = -1_000;
const MAX_COORDINATE: i64 = 1_000;
const CHECKSUM_OFFSET: i64 = 1_001;
const NONE: usize = usize::MAX;

#[derive(Clone, Copy, Default)]
struct Point { x: i64, y: i64 }

#[derive(Clone, Copy)]
struct Node { point: Point, axis: usize, left: usize, right: usize }

impl Default for Node {
    fn default() -> Self { Self { point: Point::default(), axis: 0, left: NONE, right: NONE } }
}

fn coordinate(point: Point, axis: usize) -> i64 { if axis == 0 { point.x } else { point.y } }

fn build(points: &mut [Point; MAX_INITIAL_POINTS], start: usize, length: usize, depth: usize,
         nodes: &mut [Node; MAX_POINTS], node_count: &mut usize) -> usize {
    if length == 0 { return NONE; }
    let axis = depth % 2;
    for index in start + 1..start + length {
        let value = points[index];
        let mut position = index;
        while position > start && coordinate(points[position - 1], axis) > coordinate(value, axis) {
            points[position] = points[position - 1];
            position -= 1;
        }
        points[position] = value;
    }
    let median = length / 2;
    let root = *node_count;
    *node_count += 1;
    nodes[root] = Node { point: points[start + median], axis, left: NONE, right: NONE };
    let left = build(points, start, median, depth + 1, nodes, node_count);
    let right = build(points, start + median + 1, length - median - 1, depth + 1, nodes, node_count);
    nodes[root].left = left;
    nodes[root].right = right;
    root
}

fn insert(nodes: &mut [Node; MAX_POINTS], node_count: &mut usize, root: usize, point: Point, depth: usize) -> usize {
    if root == NONE {
        let index = *node_count;
        *node_count += 1;
        nodes[index] = Node { point, axis: depth % 2, left: NONE, right: NONE };
        return index;
    }
    let axis = nodes[root].axis;
    let child = if coordinate(point, axis) < coordinate(nodes[root].point, axis) { nodes[root].left } else { nodes[root].right };
    let inserted = insert(nodes, node_count, child, point, depth + 1);
    if coordinate(point, axis) < coordinate(nodes[root].point, axis) { nodes[root].left = inserted; } else { nodes[root].right = inserted; }
    root
}

fn search(nodes: &[Node; MAX_POINTS], root: usize, point: Point) -> bool {
    if root == NONE { return false; }
    if nodes[root].point.x == point.x && nodes[root].point.y == point.y { return true; }
    let axis = nodes[root].axis;
    let child = if coordinate(point, axis) < coordinate(nodes[root].point, axis) { nodes[root].left } else { nodes[root].right };
    search(nodes, child, point)
}

fn distance_squared(left: Point, right: Point) -> i64 {
    let dx = left.x - right.x;
    let dy = left.y - right.y;
    dx * dx + dy * dy
}

fn nearest(nodes: &[Node; MAX_POINTS], root: usize, query: Point, mut best: usize) -> usize {
    if root == NONE { return best; }
    if nodes[root].point.x == query.x && nodes[root].point.y == query.y { return root; }
    let node_point = nodes[root].point;
    let axis = nodes[root].axis;
    let distance = distance_squared(node_point, query);
    let dx = node_point.x - query.x;
    let dy = node_point.y - query.y;
    let distance_except_axis = if axis == 0 { dy * dy } else { dx * dx };
    if distance < distance_squared(nodes[best].point, query) { best = root; }
    let query_left = coordinate(query, axis) < coordinate(node_point, axis);
    let near = if query_left { nodes[root].left } else { nodes[root].right };
    let far = if query_left { nodes[root].right } else { nodes[root].left };
    best = nearest(nodes, near, query, best);
    if distance_except_axis < distance_squared(nodes[best].point, query) { best = nearest(nodes, far, query, best); }
    best
}

#[no_mangle]
pub unsafe extern "C" fn kdtree_benchmark(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 0 || values[0] > MAX_INITIAL_POINTS as i64 { return -1; }
    let initial_count = values[0] as usize;
    let operation_count_index = 1 + 2 * initial_count;
    if operation_count_index >= length { return -1; }
    let operation_count_value = values[operation_count_index];
    if operation_count_value < 0 || operation_count_value > MAX_OPERATIONS as i64 { return -1; }
    let operation_count = operation_count_value as usize;
    if length != operation_count_index + 1 + 3 * operation_count || length > MAX_VALID_INPUT_LENGTH { return -1; }

    let mut points = [Point::default(); MAX_INITIAL_POINTS];
    for index in 0..initial_count {
        let point = Point { x: values[1 + 2 * index], y: values[2 + 2 * index] };
        if !(MIN_COORDINATE..=MAX_COORDINATE).contains(&point.x) || !(MIN_COORDINATE..=MAX_COORDINATE).contains(&point.y) { return -1; }
        for previous in 0..index {
            if points[previous].x == point.x || points[previous].y == point.y { return -1; }
        }
        points[index] = point;
    }

    let mut nodes = [Node::default(); MAX_POINTS];
    let mut point_count = 0_usize;
    let mut root = build(&mut points, 0, initial_count, 0, &mut nodes, &mut point_count);
    let mut checksum = 0_i64;
    let operations_start = operation_count_index + 1;
    for operation in 0..operation_count {
        let position = operations_start + operation * 3;
        let opcode = values[position];
        let first = values[position + 1];
        let second = values[position + 2];
        let mut result = 0_i64;
        if opcode == 0 || opcode == 1 || opcode == 4 {
            if !(MIN_COORDINATE..=MAX_COORDINATE).contains(&first) || !(MIN_COORDINATE..=MAX_COORDINATE).contains(&second) { return -1; }
            let point = Point { x: first, y: second };
            if opcode == 0 {
                if point_count >= MAX_POINTS { return -1; }
                for index in 0..point_count { if nodes[index].point.x == first || nodes[index].point.y == second { return -1; } }
                root = insert(&mut nodes, &mut point_count, root, point, 0);
                continue;
            } else if opcode == 1 {
                result = if search(&nodes, root, point) { 1 } else { 0 };
            } else {
                if root == NONE { return -1; }
                let closest = nearest(&nodes, root, point, root);
                result = distance_squared(nodes[closest].point, point);
            }
        } else if opcode == 2 || opcode == 3 {
            if first < 0 || first > 1 || second != 0 || root == NONE { return -1; }
            let axis = first as usize;
            result = coordinate(nodes[0].point, axis);
            for index in 1..point_count {
                let value = coordinate(nodes[index].point, axis);
                if (opcode == 2 && value < result) || (opcode == 3 && value > result) { result = value; }
            }
        } else { return -1; }
        checksum += (operation as i64 + 1) * (result + CHECKSUM_OFFSET);
    }
    checksum
}
