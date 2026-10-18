module quad_tree;

import "std";

const usz MAX_POINTS = 64;
const usz MAX_CAPACITY = 8;
const usz MAX_DEPTH = 12;
const usz MAX_NODES = 1 + 4 * MAX_POINTS * MAX_DEPTH;
const usz MAX_PARSEABLE_INPUT_LENGTH = 137;
const usz MAX_OUTPUT_WORDS = 194;
const usz MAX_OUTPUT_BYTES = 1552;

struct Point { double x; double y; }
struct QuadNode {
    double center_x; double center_y; double half_width;
    usz point_count;
    usz[MAX_CAPACITY] point_indices;
    usz[4] children;
    bool divided;
}
struct Context {
    QuadNode[MAX_NODES] nodes;
    usz node_count;
    Point[MAX_POINTS] points;
    usz capacity;
    usz query_indices[MAX_POINTS];
    usz query_count;
    double query_x; double query_y; double query_half_width;
}

fn bool contains(QuadNode* node, Point point) {
    return point.x >= node.center_x - node.half_width && point.x <= node.center_x + node.half_width &&
        point.y >= node.center_y - node.half_width && point.y <= node.center_y + node.half_width;
}

fn bool intersects(QuadNode* node, Context* context) {
    return context.query_x - context.query_half_width <= node.center_x + node.half_width &&
        context.query_x + context.query_half_width >= node.center_x - node.half_width &&
        context.query_y - context.query_half_width <= node.center_y + node.half_width &&
        context.query_y + context.query_half_width >= node.center_y - node.half_width;
}

fn void subdivide(Context* context, usz node_index) {
    double child_half = context.nodes[node_index].half_width / 2.0;
    double cx = context.nodes[node_index].center_x;
    double cy = context.nodes[node_index].center_y;
    double[4] child_x = {cx - child_half, cx + child_half, cx - child_half, cx + child_half};
    double[4] child_y = {cy + child_half, cy + child_half, cy - child_half, cy - child_half};
    for (usz child = 0; child < 4; child++) {
        usz index = context.node_count++;
        context.nodes[index] = {};
        context.nodes[index].center_x = child_x[child];
        context.nodes[index].center_y = child_y[child];
        context.nodes[index].half_width = child_half;
        context.nodes[node_index].children[child] = index;
    }
    context.nodes[node_index].divided = true;
}

fn bool insert_point(Context* context, usz node_index, usz point_index) {
    Point point = context.points[point_index];
    if (!contains(&context.nodes[node_index], point)) return false;
    if (context.nodes[node_index].point_count < context.capacity) {
        usz at = context.nodes[node_index].point_count++;
        context.nodes[node_index].point_indices[at] = point_index;
        return true;
    }
    if (!context.nodes[node_index].divided) subdivide(context, node_index);
    for (usz child = 0; child < 4; child++) {
        usz child_index = context.nodes[node_index].children[child];
        if (insert_point(context, child_index, point_index)) return true;
    }
    return false;
}

fn void query_node(Context* context, usz node_index) {
    QuadNode node = context.nodes[node_index];
    if (!intersects(&node, context)) return;
    double left = context.query_x - context.query_half_width;
    double right = context.query_x + context.query_half_width;
    double bottom = context.query_y - context.query_half_width;
    double top = context.query_y + context.query_half_width;
    for (usz index = 0; index < node.point_count; index++) {
        usz point_index = node.point_indices[index];
        Point point = context.points[point_index];
        if (point.x >= left && point.x <= right && point.y >= bottom && point.y <= top)
            context.query_indices[context.query_count++] = point_index;
    }
    if (node.divided)
        for (usz child = 0; child < 4; child++) query_node(context, node.children[child]);
}

fn void write_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 0xff);
        bits >>= 8;
    }
}

long quad_tree(long* input, usz input_length, char* output, usz capacity) @export("quad_tree") {
    if (input == null || input_length < 8 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < -2048 || input[0] > 2048 || input[1] < -2048 || input[1] > 2048 ||
        input[2] < 1 || input[2] > 1024 || input[3] < 1 || input[3] > (long)MAX_CAPACITY ||
        input[4] < 0 || input[4] > (long)MAX_POINTS) return -1;
    usz point_count = (usz)input[4];
    if (input_length != 8 + 2 * point_count) return -1;
    usz query_offset = 5 + 2 * point_count;
    if (input[query_offset] < -8192 || input[query_offset] > 8192 ||
        input[query_offset + 1] < -8192 || input[query_offset + 1] > 8192 ||
        input[query_offset + 2] < 0 || input[query_offset + 2] > 8192) return -1;

    Context context = {};
    context.node_count = 1;
    context.capacity = (usz)input[3];
    context.query_x = (double)input[query_offset];
    context.query_y = (double)input[query_offset + 1];
    context.query_half_width = (double)input[query_offset + 2];
    context.nodes[0].center_x = (double)input[0];
    context.nodes[0].center_y = (double)input[1];
    context.nodes[0].half_width = (double)input[2];
    for (usz point = 0; point < point_count; point++) {
        long x = input[5 + 2 * point];
        long y = input[6 + 2 * point];
        if (x < -8192 || x > 8192 || y < -8192 || y > 8192) return -1;
        for (usz earlier = 0; earlier < point; earlier++)
            if (context.points[earlier].x == (double)x && context.points[earlier].y == (double)y) return -1;
        context.points[point].x = (double)x;
        context.points[point].y = (double)y;
    }

    long[MAX_OUTPUT_WORDS] words = {};
    words[0] = (long)point_count;
    for (usz point = 0; point < point_count; point++)
        words[1 + point] = insert_point(&context, 0, point) ? 1 : 0;
    query_node(&context, 0);
    usz word_count = 2 + point_count + 2 * context.query_count;
    words[1 + point_count] = (long)context.query_count;
    for (usz index = 0; index < context.query_count; index++) {
        Point point = context.points[context.query_indices[index]];
        words[2 + point_count + 2 * index] = (long)point.x;
        words[3 + point_count + 2 * index] = (long)point.y;
    }
    usz output_bytes = word_count * 8;
    if (output_bytes > MAX_OUTPUT_BYTES) return -1;
    if (output == null || capacity < output_bytes) return -2;
    for (usz index = 0; index < word_count; index++) write_i64_le(output, index * 8, words[index]);
    return (long)output_bytes;
}
