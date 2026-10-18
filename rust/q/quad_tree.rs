const MAX_POINTS: usize = 64;
const MAX_CAPACITY: usize = 8;
const MAX_DEPTH: usize = 12;
const MAX_NODES: usize = 1 + 4 * MAX_POINTS * MAX_DEPTH;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 137;
const MAX_OUTPUT_WORDS: usize = 194;
const MAX_OUTPUT_BYTES: usize = 1552;

#[derive(Clone, Copy)]
struct Point { x: f64, y: f64 }

#[derive(Clone, Copy)]
struct QuadNode {
    center_x: f64,
    center_y: f64,
    half_width: f64,
    point_count: usize,
    point_indices: [usize; MAX_CAPACITY],
    children: [usize; 4],
    divided: bool,
}

impl QuadNode {
    const EMPTY: Self = Self {
        center_x: 0.0,
        center_y: 0.0,
        half_width: 0.0,
        point_count: 0,
        point_indices: [0; MAX_CAPACITY],
        children: [0; 4],
        divided: false,
    };
}

struct Context {
    nodes: [QuadNode; MAX_NODES],
    node_count: usize,
    points: [Point; MAX_POINTS],
    capacity: usize,
    query_indices: [usize; MAX_POINTS],
    query_count: usize,
    query_x: f64,
    query_y: f64,
    query_half_width: f64,
}

fn contains(node: QuadNode, point: Point) -> bool {
    point.x >= node.center_x - node.half_width && point.x <= node.center_x + node.half_width &&
        point.y >= node.center_y - node.half_width && point.y <= node.center_y + node.half_width
}

fn intersects(node: QuadNode, context: &Context) -> bool {
    context.query_x - context.query_half_width <= node.center_x + node.half_width &&
        context.query_x + context.query_half_width >= node.center_x - node.half_width &&
        context.query_y - context.query_half_width <= node.center_y + node.half_width &&
        context.query_y + context.query_half_width >= node.center_y - node.half_width
}

fn subdivide(context: &mut Context, node_index: usize) {
    let node = context.nodes[node_index];
    let child_half = node.half_width / 2.0;
    let child_x = [node.center_x - child_half, node.center_x + child_half,
        node.center_x - child_half, node.center_x + child_half];
    let child_y = [node.center_y + child_half, node.center_y + child_half,
        node.center_y - child_half, node.center_y - child_half];
    let mut child_indices = [0; 4];
    for child in 0..4 {
        let index = context.node_count;
        context.node_count += 1;
        context.nodes[index] = QuadNode {
            center_x: child_x[child],
            center_y: child_y[child],
            half_width: child_half,
            ..QuadNode::EMPTY
        };
        child_indices[child] = index;
    }
    context.nodes[node_index].children = child_indices;
    context.nodes[node_index].divided = true;
}

fn insert_point(context: &mut Context, node_index: usize, point_index: usize) -> bool {
    let node = context.nodes[node_index];
    let point = context.points[point_index];
    if !contains(node, point) { return false; }
    if node.point_count < context.capacity {
        context.nodes[node_index].point_indices[node.point_count] = point_index;
        context.nodes[node_index].point_count += 1;
        return true;
    }
    if !node.divided { subdivide(context, node_index); }
    let children = context.nodes[node_index].children;
    for child in children {
        if insert_point(context, child, point_index) { return true; }
    }
    false
}

fn query_node(context: &mut Context, node_index: usize) {
    let node = context.nodes[node_index];
    if !intersects(node, context) { return; }
    let left = context.query_x - context.query_half_width;
    let right = context.query_x + context.query_half_width;
    let bottom = context.query_y - context.query_half_width;
    let top = context.query_y + context.query_half_width;
    for index in 0..node.point_count {
        let point_index = node.point_indices[index];
        let point = context.points[point_index];
        if point.x >= left && point.x <= right && point.y >= bottom && point.y <= top {
            let result_index = context.query_count;
            context.query_indices[result_index] = point_index;
            context.query_count += 1;
        }
    }
    if node.divided {
        for child in node.children { query_node(context, child); }
    }
}

unsafe fn write_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = ((bits >> (byte * 8)) & 0xff) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn quad_tree(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 8 || input_length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    if !(-2048..=2048).contains(&values[0]) || !(-2048..=2048).contains(&values[1]) ||
        !(1..=1024).contains(&values[2]) || !(1..=MAX_CAPACITY as i64).contains(&values[3]) ||
        !(0..=MAX_POINTS as i64).contains(&values[4]) { return -1; }
    let point_count = values[4] as usize;
    if input_length != 8 + 2 * point_count { return -1; }
    let query_offset = 5 + 2 * point_count;
    if !(-8192..=8192).contains(&values[query_offset]) ||
        !(-8192..=8192).contains(&values[query_offset + 1]) ||
        !(0..=8192).contains(&values[query_offset + 2]) { return -1; }

    let mut context = Context {
        nodes: [QuadNode::EMPTY; MAX_NODES],
        node_count: 1,
        points: [Point { x: 0.0, y: 0.0 }; MAX_POINTS],
        capacity: values[3] as usize,
        query_indices: [0; MAX_POINTS],
        query_count: 0,
        query_x: values[query_offset] as f64,
        query_y: values[query_offset + 1] as f64,
        query_half_width: values[query_offset + 2] as f64,
    };
    context.nodes[0].center_x = values[0] as f64;
    context.nodes[0].center_y = values[1] as f64;
    context.nodes[0].half_width = values[2] as f64;
    for point in 0..point_count {
        let x = values[5 + 2 * point];
        let y = values[6 + 2 * point];
        if !(-8192..=8192).contains(&x) || !(-8192..=8192).contains(&y) { return -1; }
        for earlier in 0..point {
            if values[5 + 2 * earlier] == x && values[6 + 2 * earlier] == y { return -1; }
        }
        context.points[point] = Point { x: x as f64, y: y as f64 };
    }

    let mut words = [0_i64; MAX_OUTPUT_WORDS];
    words[0] = point_count as i64;
    for point in 0..point_count { words[1 + point] = if insert_point(&mut context, 0, point) { 1 } else { 0 }; }
    query_node(&mut context, 0);
    let word_count = 2 + point_count + 2 * context.query_count;
    words[1 + point_count] = context.query_count as i64;
    for index in 0..context.query_count {
        let point = context.points[context.query_indices[index]];
        words[2 + point_count + 2 * index] = point.x as i64;
        words[3 + point_count + 2 * index] = point.y as i64;
    }
    let output_bytes = word_count * 8;
    if output_bytes > MAX_OUTPUT_BYTES { return -1; }
    if output.is_null() || capacity < output_bytes { return -2; }
    for index in 0..word_count { write_i64_le(output, index * 8, words[index]); }
    output_bytes as i64
}
