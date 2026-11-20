#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int N = 7, Q = 105, NODE_CAP = 13;
struct Triple { int a, b, c; };

void put_i64(std::uint8_t *out, std::size_t at, std::int64_t value)
{
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t i = 0; i < 8; ++i) out[at + i] = static_cast<std::uint8_t>(bits >> (8 * i));
}

bool construct(const std::array<Triple, Q> &triples, std::size_t q, int n,
               std::array<int, NODE_CAP> &kind, std::array<int, NODE_CAP> &value,
               std::size_t &node_count)
{
    std::array<unsigned char, NODE_CAP> pending{};
    std::size_t top = 1;
    pending[0] = static_cast<unsigned char>((1u << n) - 1u);
    node_count = 0;
    while (top != 0) {
        const unsigned char subset = pending[--top];
        if ((subset & static_cast<unsigned char>(subset - 1)) == 0) {
            int label = 0;
            while ((subset & (1u << label)) == 0) ++label;
            kind[node_count] = 1;
            value[node_count++] = label;
            continue;
        }

        std::array<std::array<bool, N>, N> edge{};
        for (std::size_t i = 0; i < q; ++i) {
            const auto &t = triples[i];
            const unsigned char needed = static_cast<unsigned char>((1u << t.a) | (1u << t.b) | (1u << t.c));
            if ((subset & needed) == needed) edge[t.a][t.b] = edge[t.b][t.a] = true;
        }
        unsigned char visited = 0;
        std::array<unsigned char, N> components{};
        std::size_t count = 0;
        for (int start = 0; start < n; ++start) {
            const unsigned char bit = static_cast<unsigned char>(1u << start);
            if ((subset & bit) == 0 || (visited & bit) != 0) continue;
            std::array<int, N> queue{};
            std::size_t head = 0, tail = 0;
            unsigned char component = 0;
            queue[tail++] = start;
            visited |= bit;
            while (head < tail) {
                const int current = queue[head++];
                component |= static_cast<unsigned char>(1u << current);
                for (int other = 0; other < n; ++other) {
                    const unsigned char other_bit = static_cast<unsigned char>(1u << other);
                    if (edge[current][other] && (subset & other_bit) && !(visited & other_bit)) {
                        visited |= other_bit;
                        queue[tail++] = other;
                    }
                }
            }
            components[count++] = component;
        }
        if (count == 1) return false;
        kind[node_count] = 0;
        value[node_count++] = static_cast<int>(count);
        for (std::size_t i = count; i > 0; --i) pending[top++] = components[i - 1];
    }
    return true;
}
}

extern "C" std::int64_t aho_build_rooted_triplet_tree(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept
{
    if (input == nullptr || length < 2 || length > 318 || input[0] < 1 || input[0] > N || input[1] < 0) return -1;
    const int n = static_cast<int>(input[0]);
    const auto q_limit = static_cast<std::size_t>(n * (n - 1) * (n - 2) / 2);
    if (static_cast<std::uint64_t>(input[1]) > q_limit) return -1;
    const auto q = static_cast<std::size_t>(input[1]);
    if (length != 2 + 3 * q) return -1;

    std::array<Triple, Q> triples{};
    for (std::size_t i = 0; i < q; ++i) {
        const auto a0 = input[2 + 3 * i], b0 = input[3 + 3 * i], c0 = input[4 + 3 * i];
        if (a0 < 0 || a0 >= n || b0 < 0 || b0 >= n || c0 < 0 || c0 >= n || a0 == b0 || a0 == c0 || b0 == c0) return -1;
        int a = static_cast<int>(a0), b = static_cast<int>(b0);
        if (a > b) { const int t = a; a = b; b = t; }
        for (std::size_t j = 0; j < i; ++j)
            if (triples[j].a == a && triples[j].b == b && triples[j].c == c0) return -1;
        triples[i] = {a, b, static_cast<int>(c0)};
    }

    std::array<int, NODE_CAP> kind{}, value{};
    std::size_t node_count = 0;
    const bool compatible = construct(triples, q, n, kind, value, node_count);
    std::array<std::int64_t, 1 + NODE_CAP> words{};
    std::size_t count = 1;
    if (compatible) {
        words[0] = static_cast<std::int64_t>(node_count);
        for (std::size_t i = 0; i < node_count; ++i)
            words[i + 1] = kind[i] ? -static_cast<std::int64_t>(value[i] + 1) : value[i];
        count += node_count;
    }
    const auto bytes = count * 8;
    if (output == nullptr || capacity < bytes) return -2;
    for (std::size_t i = 0; i < count; ++i) put_i64(output, i * 8, words[i]);
    return static_cast<std::int64_t>(bytes);
}
