#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_leaves = 8;
constexpr std::size_t max_nodes = 15;
constexpr std::size_t max_candidates = 256;
constexpr std::size_t max_input = 32;
constexpr std::size_t output_bytes = 32;
struct Candidate { std::int64_t height, width; std::uint64_t mask; };
struct Node {
    int op = -1, left = -1, right = -1;
    std::int64_t cell_height = 0, cell_width = 0;
    std::size_t leaf_index = 0, count = 0;
    Candidate candidates[max_candidates]{};
};

bool mask_lex_less(std::uint64_t a, std::uint64_t b, std::size_t leaves) {
    for (std::size_t bit = 0; bit < leaves; ++bit) {
        const auto av = (a >> bit) & 1U, bv = (b >> bit) & 1U;
        if (av != bv) return av < bv;
    }
    return false;
}

void prune(Node &node, std::size_t leaves) {
    bool dominated[max_candidates]{};
    for (std::size_t i = 0; i < node.count; ++i) {
        const Candidate a = node.candidates[i];
        for (std::size_t j = 0; j < node.count; ++j) {
            if (i == j) continue;
            const Candidate b = node.candidates[j];
            if (b.height <= a.height && b.width <= a.width
                && (b.height < a.height || b.width < a.width
                    || mask_lex_less(b.mask, a.mask, leaves)
                    || (b.mask == a.mask && j < i))) {
                dominated[i] = true;
                break;
            }
        }
    }
    std::size_t kept = 0;
    for (std::size_t i = 0; i < node.count; ++i)
        if (!dominated[i]) node.candidates[kept++] = node.candidates[i];
    node.count = kept;
}

void store_i64_le(std::uint8_t *output, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
} // namespace

extern "C" std::int64_t slicing_floorplan_stockmeyer(const std::int64_t *input,
        std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 4 || length > max_input
        || input[0] < 1 || input[0] > static_cast<std::int64_t>(max_leaves)) return -1;
    const auto leaves = static_cast<std::size_t>(input[0]);
    Node nodes[max_nodes]{};
    int stack[max_nodes]{};
    std::size_t stack_size = 0, node_count = 0, leaf_count = 0, internal_count = 0;
    std::size_t position = 1;
    while (position < length) {
        const auto token = input[position++];
        if (token == 2) {
            if (position + 2 > length || leaf_count >= leaves || node_count >= max_nodes) return -1;
            const auto height = input[position++], width = input[position++];
            if (height < 1 || height > 20 || width < 1 || width > 20) return -1;
            Node &node = nodes[node_count];
            node.op = 2; node.cell_height = height; node.cell_width = width; node.leaf_index = leaf_count++;
            node.candidates[0] = {height, width, 0};
            node.candidates[1] = {width, height, std::uint64_t{1} << node.leaf_index};
            node.count = 2;
            prune(node, leaves);
            stack[stack_size++] = static_cast<int>(node_count++);
        } else if (token == 0 || token == 1) {
            if (stack_size < 2 || internal_count >= leaves - 1 || node_count >= max_nodes) return -1;
            const int right = stack[--stack_size], left = stack[--stack_size];
            if (nodes[right].op == token) return -1;
            Node &node = nodes[node_count];
            node.op = static_cast<int>(token); node.left = left; node.right = right;
            for (std::size_t i = 0; i < nodes[left].count; ++i) {
                for (std::size_t j = 0; j < nodes[right].count; ++j) {
                    if (node.count >= max_candidates) return -1;
                    const Candidate a = nodes[left].candidates[i], b = nodes[right].candidates[j];
                    Candidate c{};
                    c.mask = a.mask | b.mask;
                    if (token == 0) {
                        c.height = a.height > b.height ? a.height : b.height;
                        c.width = a.width + b.width;
                    } else {
                        c.height = a.height + b.height;
                        c.width = a.width > b.width ? a.width : b.width;
                    }
                    node.candidates[node.count++] = c;
                }
            }
            prune(node, leaves);
            stack[stack_size++] = static_cast<int>(node_count++);
            ++internal_count;
        } else return -1;
    }
    if (position != length || leaf_count != leaves || internal_count != leaves - 1
        || node_count != 2 * leaves - 1 || stack_size != 1) return -1;
    const Node &root = nodes[stack[0]];
    if (root.count == 0) return -1;
    Candidate best = root.candidates[0];
    for (std::size_t i = 1; i < root.count; ++i) {
        const Candidate c = root.candidates[i];
        const auto area = c.height * c.width, best_area = best.height * best.width;
        if (area < best_area || (area == best_area && (c.height < best.height
            || (c.height == best.height && (c.width < best.width
            || (c.width == best.width && mask_lex_less(c.mask, best.mask, leaves))))))) best = c;
    }
    if (output == nullptr || capacity < output_bytes) return -2;
    std::uint8_t staged[output_bytes];
    store_i64_le(staged, best.height * best.width);
    store_i64_le(staged + 8, best.height);
    store_i64_le(staged + 16, best.width);
    store_i64_le(staged + 24, static_cast<std::int64_t>(best.mask));
    for (std::size_t i = 0; i < output_bytes; ++i) output[i] = staged[i];
    return output_bytes;
}
