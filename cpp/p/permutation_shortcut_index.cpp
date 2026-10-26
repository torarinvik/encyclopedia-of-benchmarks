#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxN = 16;
constexpr int kMaxQueries = 16;
constexpr std::size_t kMaxInput = 52;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value)
{
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}

bool is_marked(std::uint32_t bitmap, int vertex)
{
    return (bitmap & (std::uint32_t{1} << static_cast<unsigned>(vertex))) != 0;
}

int shortcut_inverse(int target, int n, const int *successor,
                     std::uint32_t bitmap, const int *shortcuts)
{
    int marker = target;
    int steps = 0;
    while (steps < n && !is_marked(bitmap, marker)) {
        marker = successor[marker];
        ++steps;
    }
    if (!is_marked(bitmap, marker)) {
        int previous = target;
        int current = successor[target];
        while (current != target) { previous = current; current = successor[current]; }
        return previous;
    }
    int rank = 0;
    for (int vertex = 0; vertex < marker; ++vertex) rank += is_marked(bitmap, vertex);
    int current = shortcuts[rank];
    int previous = current;
    current = successor[current];
    for (steps = 0; steps < n; ++steps) {
        if (current == target) return previous;
        previous = current;
        current = successor[current];
    }
    return -1;
}
}

extern "C" std::int64_t permutation_shortcut_index(const std::int64_t *input,
                                                      std::size_t length,
                                                      std::uint8_t *output,
                                                      std::size_t capacity)
{
    if (input == nullptr || length < 4 || length > kMaxInput) return -1;
    const auto n_raw = input[0], stride_raw = input[1];
    if (n_raw < 1 || n_raw > kMaxN || stride_raw < 1 || stride_raw > kMaxN) return -1;
    const int n = static_cast<int>(n_raw), stride = static_cast<int>(stride_raw);
    const std::size_t query_at = 2 + static_cast<std::size_t>(n);
    if (length <= query_at) return -1;
    const auto query_raw = input[query_at];
    if (query_raw < 0 || query_raw > kMaxQueries
        || length != query_at + 1 + 2 * static_cast<std::size_t>(query_raw)) return -1;
    const int query_count = static_cast<int>(query_raw);
    int successor[kMaxN];
    bool seen[kMaxN]{};
    for (int vertex = 0; vertex < n; ++vertex) {
        const auto value = input[2 + static_cast<std::size_t>(vertex)];
        if (value < 1 || value > n || seen[value - 1]) return -1;
        seen[value - 1] = true;
        successor[vertex] = static_cast<int>(value) - 1;
    }
    for (int query = 0; query < query_count; ++query) {
        const auto op = input[query_at + 1 + 2 * static_cast<std::size_t>(query)];
        const auto index = input[query_at + 2 + 2 * static_cast<std::size_t>(query)];
        if ((op != 0 && op != 1) || index < 1 || index > n) return -1;
    }

    bool visited[kMaxN]{};
    int back_pointer[kMaxN];
    for (int vertex = 0; vertex < n; ++vertex) back_pointer[vertex] = -1;
    std::uint32_t bitmap = 0;
    for (int start = 0; start < n; ++start) {
        if (visited[start]) continue;
        int cycle[kMaxN];
        int cycle_length = 0;
        int current = start;
        while (!visited[current]) {
            visited[current] = true;
            cycle[cycle_length++] = current;
            current = successor[current];
        }
        if (cycle_length >= stride) {
            for (int offset = 0; offset < cycle_length; offset += stride) {
                const int vertex = cycle[offset];
                bitmap |= std::uint32_t{1} << static_cast<unsigned>(vertex);
                int back_offset = (offset - stride) % cycle_length;
                if (back_offset < 0) back_offset += cycle_length;
                back_pointer[vertex] = cycle[back_offset];
            }
        }
    }
    int shortcuts[kMaxN];
    int shortcut_count = 0;
    for (int vertex = 0; vertex < n; ++vertex)
        if (is_marked(bitmap, vertex)) shortcuts[shortcut_count++] = back_pointer[vertex];

    std::int64_t answers[kMaxQueries];
    for (int query = 0; query < query_count; ++query) {
        const auto op = input[query_at + 1 + 2 * static_cast<std::size_t>(query)];
        const int target = static_cast<int>(input[query_at + 2 + 2 * static_cast<std::size_t>(query)]) - 1;
        const int answer = op == 0 ? successor[target]
                                   : shortcut_inverse(target, n, successor, bitmap, shortcuts);
        if (answer < 0) return -1;
        answers[query] = static_cast<std::int64_t>(answer) + 1;
    }
    const auto bytes = static_cast<std::size_t>(query_count) * 8;
    if (output == nullptr || capacity < bytes) return -2;
    for (int query = 0; query < query_count; ++query)
        store_i64_le(output, static_cast<std::size_t>(query) * 8, answers[query]);
    return static_cast<std::int64_t>(bytes);
}
