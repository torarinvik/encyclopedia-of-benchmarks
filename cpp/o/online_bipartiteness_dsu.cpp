#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 32, kMaxQ = 64;
std::size_t find_parity(std::int64_t* parent, std::int64_t* parity, std::size_t node, std::int64_t& xor_to_root) {
    auto root = node;
    std::int64_t total = 0;
    while (static_cast<std::size_t>(parent[root]) != root) { total ^= parity[root]; root = static_cast<std::size_t>(parent[root]); }
    auto current = node;
    std::int64_t accumulated = 0;
    while (static_cast<std::size_t>(parent[current]) != current) {
        const auto next = static_cast<std::size_t>(parent[current]);
        const auto edge = parity[current];
        parent[current] = static_cast<std::int64_t>(root);
        parity[current] = total ^ accumulated;
        accumulated ^= edge;
        current = next;
    }
    xor_to_root = total;
    return root;
}
}

extern "C" std::int64_t online_bipartiteness_dsu(const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > 195) return -1;
    const auto n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(kMaxN) || q_value < 0 || q_value > static_cast<std::int64_t>(kMaxQ)) return -1;
    const auto n = static_cast<std::size_t>(n_value), q = static_cast<std::size_t>(q_value);
    if (length != 2 + 3 * q) return -1;
    for (std::size_t j = 0; j < q; ++j) {
        const auto opcode = input[2 + 3 * j], a = input[3 + 3 * j], b = input[4 + 3 * j];
        if (opcode == 0) { if (a < 0 || a >= n_value || b < 0 || b >= n_value) return -1; }
        else if (opcode == 1) { if (a < 0 || a >= n_value || b != 0) return -1; }
        else return -1;
    }
    std::int64_t parent[32], size[32], parity[32], bad[32]{};
    for (std::size_t i = 0; i < n; ++i) { parent[i] = static_cast<std::int64_t>(i); size[i] = 1; parity[i] = 0; }
    std::int64_t checksum = 0, query_ordinal = 0;
    for (std::size_t j = 0; j < q; ++j) {
        const auto opcode = input[2 + 3 * j];
        const auto a = static_cast<std::size_t>(input[3 + 3 * j]);
        if (opcode == 1) {
            std::int64_t ignored = 0;
            const auto root = find_parity(parent, parity, a, ignored);
            const std::int64_t answer = bad[root] ? 0 : 1;
            checksum += (query_ordinal + 1) * (answer + 1); ++query_ordinal;
            continue;
        }
        const auto b = static_cast<std::size_t>(input[4 + 3 * j]);
        std::int64_t parity_a = 0, parity_b = 0;
        auto root_a = find_parity(parent, parity, a, parity_a);
        auto root_b = find_parity(parent, parity, b, parity_b);
        if (root_a == root_b) { if (parity_a == parity_b) bad[root_a] = 1; continue; }
        if (size[root_a] < size[root_b]) { std::swap(root_a, root_b); std::swap(parity_a, parity_b); }
        parent[root_b] = static_cast<std::int64_t>(root_a);
        parity[root_b] = parity_a ^ parity_b ^ 1;
        size[root_a] += size[root_b];
        bad[root_a] = bad[root_a] || bad[root_b];
    }
    return checksum;
}
