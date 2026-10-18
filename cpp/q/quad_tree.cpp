#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxPoints = 64;
constexpr std::size_t MaxCapacity = 8;
constexpr std::size_t MaxDepth = 12;
constexpr std::size_t MaxNodes = 1 + 4 * MaxPoints * MaxDepth;
constexpr std::size_t MaxParseableInputLength = 137;
constexpr std::size_t MaxOutputWords = 194;
constexpr std::size_t MaxOutputBytes = 1552;

struct Point { double x; double y; };
struct QuadNode {
    double center_x = 0, center_y = 0, half_width = 0;
    std::size_t point_count = 0;
    std::array<std::size_t, MaxCapacity> point_indices{};
    std::array<std::size_t, 4> children{};
    bool divided = false;
};
struct Context {
    std::array<QuadNode, MaxNodes> nodes{};
    std::size_t node_count = 1;
    std::array<Point, MaxPoints> points{};
    std::size_t capacity = 0;
    std::size_t query_count = 0;
    std::array<std::size_t, MaxPoints> query_indices{};
    double query_x = 0, query_y = 0, query_half_width = 0;
};

bool contains(const QuadNode& node, Point point) {
    return point.x >= node.center_x - node.half_width && point.x <= node.center_x + node.half_width &&
           point.y >= node.center_y - node.half_width && point.y <= node.center_y + node.half_width;
}

bool intersects(const QuadNode& node, const Context& context) {
    return context.query_x - context.query_half_width <= node.center_x + node.half_width &&
           context.query_x + context.query_half_width >= node.center_x - node.half_width &&
           context.query_y - context.query_half_width <= node.center_y + node.half_width &&
           context.query_y + context.query_half_width >= node.center_y - node.half_width;
}

void subdivide(Context& context, std::size_t node_index) {
    const double child_half = context.nodes[node_index].half_width / 2.0;
    const double cx = context.nodes[node_index].center_x;
    const double cy = context.nodes[node_index].center_y;
    const std::array<double, 4> child_x{cx - child_half, cx + child_half, cx - child_half, cx + child_half};
    const std::array<double, 4> child_y{cy + child_half, cy + child_half, cy - child_half, cy - child_half};
    for (std::size_t child = 0; child < 4; ++child) {
        const std::size_t index = context.node_count++;
        context.nodes[index] = QuadNode{};
        context.nodes[index].center_x = child_x[child];
        context.nodes[index].center_y = child_y[child];
        context.nodes[index].half_width = child_half;
        context.nodes[node_index].children[child] = index;
    }
    context.nodes[node_index].divided = true;
}

bool insert_point(Context& context, std::size_t node_index, std::size_t point_index) {
    const Point point = context.points[point_index];
    if (!contains(context.nodes[node_index], point)) return false;
    if (context.nodes[node_index].point_count < context.capacity) {
        auto& node = context.nodes[node_index];
        node.point_indices[node.point_count++] = point_index;
        return true;
    }
    if (!context.nodes[node_index].divided) subdivide(context, node_index);
    for (std::size_t child = 0; child < 4; ++child) {
        const std::size_t child_index = context.nodes[node_index].children[child];
        if (insert_point(context, child_index, point_index)) return true;
    }
    return false;
}

void query_node(Context& context, std::size_t node_index) {
    const QuadNode node = context.nodes[node_index];
    if (!intersects(node, context)) return;
    const double left = context.query_x - context.query_half_width;
    const double right = context.query_x + context.query_half_width;
    const double bottom = context.query_y - context.query_half_width;
    const double top = context.query_y + context.query_half_width;
    for (std::size_t i = 0; i < node.point_count; ++i) {
        const std::size_t point_index = node.point_indices[i];
        const Point point = context.points[point_index];
        if (point.x >= left && point.x <= right && point.y >= bottom && point.y <= top)
            context.query_indices[context.query_count++] = point_index;
    }
    if (node.divided)
        for (std::size_t child = 0; child < 4; ++child) query_node(context, node.children[child]);
}

void write_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (unsigned int byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 0xffu);
        bits >>= 8u;
    }
}
}

extern "C" std::int64_t quad_tree(const std::int64_t* input, std::size_t input_length,
                                   std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || input_length < 8 || input_length > MaxParseableInputLength) return -1;
    if (input[0] < -2048 || input[0] > 2048 || input[1] < -2048 || input[1] > 2048 ||
        input[2] < 1 || input[2] > 1024 || input[3] < 1 || input[3] > static_cast<std::int64_t>(MaxCapacity) ||
        input[4] < 0 || input[4] > static_cast<std::int64_t>(MaxPoints)) return -1;
    const std::size_t point_count = static_cast<std::size_t>(input[4]);
    if (input_length != 8 + 2 * point_count) return -1;
    const std::size_t query_offset = 5 + 2 * point_count;
    if (input[query_offset] < -8192 || input[query_offset] > 8192 ||
        input[query_offset + 1] < -8192 || input[query_offset + 1] > 8192 ||
        input[query_offset + 2] < 0 || input[query_offset + 2] > 8192) return -1;

    Context context{};
    context.capacity = static_cast<std::size_t>(input[3]);
    context.query_x = static_cast<double>(input[query_offset]);
    context.query_y = static_cast<double>(input[query_offset + 1]);
    context.query_half_width = static_cast<double>(input[query_offset + 2]);
    context.nodes[0].center_x = static_cast<double>(input[0]);
    context.nodes[0].center_y = static_cast<double>(input[1]);
    context.nodes[0].half_width = static_cast<double>(input[2]);
    for (std::size_t point = 0; point < point_count; ++point) {
        const std::int64_t x = input[5 + point * 2];
        const std::int64_t y = input[6 + point * 2];
        if (x < -8192 || x > 8192 || y < -8192 || y > 8192) return -1;
        for (std::size_t earlier = 0; earlier < point; ++earlier)
            if (context.points[earlier].x == static_cast<double>(x) && context.points[earlier].y == static_cast<double>(y)) return -1;
        context.points[point] = {static_cast<double>(x), static_cast<double>(y)};
    }

    std::array<std::int64_t, MaxOutputWords> words{};
    words[0] = static_cast<std::int64_t>(point_count);
    for (std::size_t point = 0; point < point_count; ++point)
        words[1 + point] = insert_point(context, 0, point) ? 1 : 0;
    query_node(context, 0);
    const std::size_t word_count = 2 + point_count + 2 * context.query_count;
    words[1 + point_count] = static_cast<std::int64_t>(context.query_count);
    for (std::size_t index = 0; index < context.query_count; ++index) {
        const Point point = context.points[context.query_indices[index]];
        words[2 + point_count + 2 * index] = static_cast<std::int64_t>(point.x);
        words[3 + point_count + 2 * index] = static_cast<std::int64_t>(point.y);
    }
    const std::size_t output_bytes = word_count * 8;
    if (output_bytes > MaxOutputBytes) return -1;
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t index = 0; index < word_count; ++index)
        write_i64_le(output, index * 8, words[index]);
    return static_cast<std::int64_t>(output_bytes);
}
