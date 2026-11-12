#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t modulus = 998'244'353;
constexpr std::size_t max_length = 64;
constexpr std::size_t max_operations = 64;
constexpr std::size_t max_tree_nodes = 256;
constexpr std::size_t max_parseable_input_values = 387;

std::int64_t reduce(std::int64_t value) { return value % modulus; }

struct AffineTree {
    std::array<std::int64_t, max_tree_nodes> sum{};
    std::array<std::int64_t, max_tree_nodes> lazy_mul{};
    std::array<std::int64_t, max_tree_nodes> lazy_add{};

    AffineTree() { lazy_mul.fill(1); }

    void apply(std::size_t node, std::size_t length, std::int64_t a, std::int64_t b)
    {
        sum[node] = reduce(a * sum[node] + b * static_cast<std::int64_t>(length));
        lazy_mul[node] = reduce(a * lazy_mul[node]);
        lazy_add[node] = reduce(a * lazy_add[node] + b);
    }

    void push(std::size_t node, std::size_t left, std::size_t right)
    {
        if (right - left <= 1 || (lazy_mul[node] == 1 && lazy_add[node] == 0)) return;
        const std::size_t middle = left + (right - left) / 2;
        apply(node * 2, middle - left, lazy_mul[node], lazy_add[node]);
        apply(node * 2 + 1, right - middle, lazy_mul[node], lazy_add[node]);
        lazy_mul[node] = 1;
        lazy_add[node] = 0;
    }

    void build(const std::int64_t *values, std::size_t node, std::size_t left, std::size_t right)
    {
        if (right - left == 1) { sum[node] = values[left]; return; }
        const std::size_t middle = left + (right - left) / 2;
        build(values, node * 2, left, middle);
        build(values, node * 2 + 1, middle, right);
        sum[node] = reduce(sum[node * 2] + sum[node * 2 + 1]);
    }

    void update(std::size_t ql, std::size_t qr, std::size_t node, std::size_t left,
                std::size_t right, std::int64_t a, std::int64_t b)
    {
        if (ql <= left && right <= qr) { apply(node, right - left, a, b); return; }
        if (qr <= left || right <= ql) return;
        push(node, left, right);
        const std::size_t middle = left + (right - left) / 2;
        update(ql, qr, node * 2, left, middle, a, b);
        update(ql, qr, node * 2 + 1, middle, right, a, b);
        sum[node] = reduce(sum[node * 2] + sum[node * 2 + 1]);
    }

    std::int64_t query(std::size_t ql, std::size_t qr, std::size_t node,
                       std::size_t left, std::size_t right)
    {
        if (ql <= left && right <= qr) return sum[node];
        if (qr <= left || right <= ql) return 0;
        push(node, left, right);
        const std::size_t middle = left + (right - left) / 2;
        return reduce(query(ql, qr, node * 2, left, middle) +
                      query(ql, qr, node * 2 + 1, middle, right));
    }
};
}

extern "C" std::int64_t range_affine_range_sum_benchmark(const std::int64_t *input,
                                                           std::size_t length)
{
    if (input == nullptr || length < 2 || length > max_parseable_input_values) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_length)) return -1;
    const std::size_t n = static_cast<std::size_t>(input[0]);
    if (length < n + 2) return -1;
    std::array<std::int64_t, max_length> values{};
    for (std::size_t i = 0; i < n; ++i) {
        if (input[i + 1] < 0 || input[i + 1] >= modulus) return -1;
        values[i] = input[i + 1];
    }
    if (input[n + 1] < 1 || input[n + 1] > static_cast<std::int64_t>(max_operations)) return -1;
    const std::size_t operation_count = static_cast<std::size_t>(input[n + 1]);
    AffineTree tree;
    tree.build(values.data(), 1, 0, n);
    std::size_t cursor = n + 2;
    std::int64_t checksum = 0;
    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        if (cursor >= length) return -1;
        const std::int64_t opcode = input[cursor++];
        if (opcode == 0) {
            if (cursor + 4 > length) return -1;
            const auto left = input[cursor++];
            const auto right = input[cursor++];
            const auto a = input[cursor++];
            const auto b = input[cursor++];
            if (left < 0 || left >= right || right > static_cast<std::int64_t>(n) ||
                a < 1 || a >= modulus || b < 0 || b >= modulus) return -1;
            tree.update(static_cast<std::size_t>(left), static_cast<std::size_t>(right),
                        1, 0, n, a, b);
        } else if (opcode == 1) {
            if (cursor + 2 > length) return -1;
            const auto left = input[cursor++];
            const auto right = input[cursor++];
            if (left < 0 || left >= right || right > static_cast<std::int64_t>(n)) return -1;
            const auto result = tree.query(static_cast<std::size_t>(left),
                static_cast<std::size_t>(right), 1, 0, n);
            checksum += static_cast<std::int64_t>(operation + 1) * (result + modulus);
        } else return -1;
    }
    return cursor == length ? checksum : -1;
}
