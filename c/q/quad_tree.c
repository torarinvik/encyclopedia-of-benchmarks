#include <stddef.h>
#include <stdint.h>

enum { MAX_POINTS = 64, MAX_CAPACITY = 8, MAX_DEPTH = 12,
       MAX_NODES = 1 + 4 * MAX_POINTS * MAX_DEPTH,
       MAX_PARSEABLE_INPUT_LENGTH = 137, MAX_OUTPUT_WORDS = 194,
       MAX_OUTPUT_BYTES = 1552 };

typedef struct {
    double x, y;
} Point;

typedef struct {
    double center_x, center_y, half_width;
    size_t point_count;
    size_t point_indices[MAX_CAPACITY];
    size_t children[4];
    int divided;
} QuadNode;

typedef struct {
    QuadNode nodes[MAX_NODES];
    size_t node_count;
    Point points[MAX_POINTS];
    size_t capacity;
    size_t query_count;
    size_t query_indices[MAX_POINTS];
    double query_x, query_y, query_half_width;
} QuadContext;

static int contains(const QuadNode *node, Point point)
{
    return point.x >= node->center_x - node->half_width &&
           point.x <= node->center_x + node->half_width &&
           point.y >= node->center_y - node->half_width &&
           point.y <= node->center_y + node->half_width;
}

static int intersects(const QuadNode *node, const QuadContext *context)
{
    return context->query_x - context->query_half_width <= node->center_x + node->half_width &&
           context->query_x + context->query_half_width >= node->center_x - node->half_width &&
           context->query_y - context->query_half_width <= node->center_y + node->half_width &&
           context->query_y + context->query_half_width >= node->center_y - node->half_width;
}

static void subdivide(QuadContext *context, size_t node_index)
{
    QuadNode *node = &context->nodes[node_index];
    double child_half = node->half_width / 2.0;
    double child_x[4] = {node->center_x - child_half, node->center_x + child_half,
                         node->center_x - child_half, node->center_x + child_half};
    double child_y[4] = {node->center_y + child_half, node->center_y + child_half,
                         node->center_y - child_half, node->center_y - child_half};
    for (size_t child = 0; child < 4; ++child) {
        size_t index = context->node_count++;
        context->nodes[index] = (QuadNode){0};
        context->nodes[index].center_x = child_x[child];
        context->nodes[index].center_y = child_y[child];
        context->nodes[index].half_width = child_half;
        node->children[child] = index;
    }
    node->divided = 1;
}

static int insert_point(QuadContext *context, size_t node_index, size_t point_index)
{
    QuadNode *node = &context->nodes[node_index];
    Point point = context->points[point_index];
    if (!contains(node, point)) return 0;
    if (node->point_count < context->capacity) {
        node->point_indices[node->point_count++] = point_index;
        return 1;
    }
    if (!node->divided) subdivide(context, node_index);
    for (size_t child = 0; child < 4; ++child) {
        size_t child_index = context->nodes[node_index].children[child];
        if (insert_point(context, child_index, point_index)) return 1;
    }
    return 0;
}

static void query_node(QuadContext *context, size_t node_index)
{
    QuadNode node = context->nodes[node_index];
    if (!intersects(&node, context)) return;
    double left = context->query_x - context->query_half_width;
    double right = context->query_x + context->query_half_width;
    double bottom = context->query_y - context->query_half_width;
    double top = context->query_y + context->query_half_width;
    for (size_t index = 0; index < node.point_count; ++index) {
        size_t point_index = node.point_indices[index];
        Point point = context->points[point_index];
        if (point.x >= left && point.x <= right && point.y >= bottom && point.y <= top)
            context->query_indices[context->query_count++] = point_index;
    }
    if (node.divided) {
        for (size_t child = 0; child < 4; ++child) query_node(context, node.children[child]);
    }
}

static void write_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (unsigned int byte = 0; byte < 8u; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(0xff));
        bits >>= 8u;
    }
}

int64_t quad_tree(const int64_t *input, size_t input_length, uint8_t *output, size_t capacity)
{
    if (input == NULL || input_length < 8u || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < -2048 || input[0] > 2048 || input[1] < -2048 || input[1] > 2048 ||
        input[2] < 1 || input[2] > 1024 || input[3] < 1 || input[3] > MAX_CAPACITY ||
        input[4] < 0 || input[4] > MAX_POINTS) return -1;
    size_t point_count = (size_t)input[4];
    if (input_length != 8u + 2u * point_count) return -1;
    size_t query_offset = 5u + 2u * point_count;
    if (input[query_offset] < -8192 || input[query_offset] > 8192 ||
        input[query_offset + 1u] < -8192 || input[query_offset + 1u] > 8192 ||
        input[query_offset + 2u] < 0 || input[query_offset + 2u] > 8192) return -1;

    QuadContext context = {0};
    context.node_count = 1;
    context.capacity = (size_t)input[3];
    context.query_x = (double)input[query_offset];
    context.query_y = (double)input[query_offset + 1u];
    context.query_half_width = (double)input[query_offset + 2u];
    context.nodes[0].center_x = (double)input[0];
    context.nodes[0].center_y = (double)input[1];
    context.nodes[0].half_width = (double)input[2];
    for (size_t point = 0; point < point_count; ++point) {
        int64_t x = input[5u + point * 2u];
        int64_t y = input[6u + point * 2u];
        if (x < -8192 || x > 8192 || y < -8192 || y > 8192) return -1;
        for (size_t earlier = 0; earlier < point; ++earlier)
            if (context.points[earlier].x == (double)x && context.points[earlier].y == (double)y) return -1;
        context.points[point] = (Point){(double)x, (double)y};
    }

    int64_t words[MAX_OUTPUT_WORDS] = {0};
    words[0] = (int64_t)point_count;
    for (size_t point = 0; point < point_count; ++point)
        words[1u + point] = insert_point(&context, 0, point) ? 1 : 0;
    query_node(&context, 0);
    size_t word_count = 2u + point_count + 2u * context.query_count;
    words[1u + point_count] = (int64_t)context.query_count;
    for (size_t index = 0; index < context.query_count; ++index) {
        Point point = context.points[context.query_indices[index]];
        words[2u + point_count + 2u * index] = (int64_t)point.x;
        words[3u + point_count + 2u * index] = (int64_t)point.y;
    }
    size_t output_bytes = word_count * 8u;
    if (output_bytes > MAX_OUTPUT_BYTES) return -1;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t index = 0; index < word_count; ++index)
        write_i64_le(output, index * 8u, words[index]);
    return (int64_t)output_bytes;
}
