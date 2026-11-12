#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_m = 32, max_n = 32, max_q = 64;
constexpr std::size_t stride = max_n + 1;
constexpr std::size_t max_input = 3 + max_m + max_n + 3 * max_q;
struct Query { std::size_t a, b, c; };

void fenwick_add(int* tree, std::size_t position, std::size_t count) {
    for (std::size_t index = position + 1; index <= count; index += index & (~index + 1)) ++tree[index];
}
int fenwick_prefix(const int* tree, std::size_t exclusive) {
    int total = 0;
    for (std::size_t index = exclusive; index > 0; index -= index & (~index + 1)) total += tree[index];
    return total;
}
void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t prefix_substring_lcs(const std::int64_t* input, std::size_t length,
                                               std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 3 || length > max_input) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_m) ||
        input[1] < 1 || input[1] > static_cast<std::int64_t>(max_n) ||
        input[2] < 1 || input[2] > static_cast<std::int64_t>(max_q)) return -1;
    const auto m = static_cast<std::size_t>(input[0]);
    const auto n = static_cast<std::size_t>(input[1]);
    const auto q = static_cast<std::size_t>(input[2]);
    if (length != 3 + m + n + 3 * q) return -1;

    int s[max_m]{}, t[max_n]{};
    std::size_t offset = 3;
    for (std::size_t i = 0; i < m; ++i) {
        if (input[offset] < 97 || input[offset] > 122) return -1;
        s[i] = static_cast<int>(input[offset++]);
    }
    for (std::size_t j = 0; j < n; ++j) {
        if (input[offset] < 97 || input[offset] > 122) return -1;
        t[j] = static_cast<int>(input[offset++]);
    }
    Query queries[max_q]{};
    int query_head[stride * stride];
    int query_next[max_q]{};
    for (auto& head : query_head) head = -1;
    for (std::size_t index = 0; index < q; ++index) {
        const auto a = input[offset++], b = input[offset++], c = input[offset++];
        if (a < 0 || a > static_cast<std::int64_t>(m) || b < 0 || b > c || c > static_cast<std::int64_t>(n)) return -1;
        queries[index] = {static_cast<std::size_t>(a), static_cast<std::size_t>(b), static_cast<std::size_t>(c)};
        const auto key = queries[index].a * stride + queries[index].b;
        query_next[index] = query_head[key];
        query_head[key] = static_cast<int>(index);
    }
    const auto output_bytes = 8 * q;
    if (output == nullptr || capacity < output_bytes) return -2;

    int horizontal[stride][stride]{}, vertical[stride][stride]{};
    for (std::size_t j = 0; j <= n; ++j) horizontal[0][j] = static_cast<int>(j);
    for (std::size_t i = 1; i <= m; ++i) {
        for (std::size_t j = 1; j <= n; ++j) {
            const int above = horizontal[i - 1][j], left = vertical[i][j - 1];
            if (s[i - 1] == t[j - 1]) {
                horizontal[i][j] = left;
                vertical[i][j] = above;
            } else {
                horizontal[i][j] = above > left ? above : left;
                vertical[i][j] = above < left ? above : left;
            }
        }
    }
    int answers[max_q]{};
    for (std::size_t a = 0; a <= m; ++a) {
        int value_head[stride], value_next[stride];
        for (std::size_t value = 0; value <= n; ++value) value_head[value] = -1;
        for (std::size_t position = 0; position <= n; ++position) {
            const auto value = static_cast<std::size_t>(horizontal[a][position]);
            value_next[position] = value_head[value];
            value_head[value] = static_cast<int>(position);
        }
        int fenwick[stride + 1]{};
        for (std::size_t b = 0; b <= n; ++b) {
            for (int position = value_head[b]; position >= 0; position = value_next[position])
                fenwick_add(fenwick, static_cast<std::size_t>(position), n + 1);
            for (int qi = query_head[a * stride + b]; qi >= 0; qi = query_next[qi]) {
                const auto& query = queries[qi];
                answers[qi] = fenwick_prefix(fenwick, query.c + 1) - fenwick_prefix(fenwick, query.b + 1);
            }
        }
    }
    for (std::size_t index = 0; index < q; ++index) store_i64_le(output, 8 * index, answers[index]);
    return static_cast<std::int64_t>(output_bytes);
}
