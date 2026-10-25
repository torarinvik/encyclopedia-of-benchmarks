/* Clean-room bounded MUMmerGPU maximal exact-match query; see package LICENSE.txt. */
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr int kMaxRef = 32, kMaxQuery = 32, kAlphabet = 5;
constexpr int kMaxNodes = 1 + kMaxRef * (kMaxRef + 3) / 2;
constexpr int kMaxInput = 3 + kMaxRef + kMaxQuery;
constexpr int kMaxMatches = kMaxRef * kMaxQuery;
int child_index(int node, int symbol) { return node * kAlphabet + symbol; }
bool suffix_less(const std::int64_t *reference, int length, int left, int right) {
    int a = left, b = right;
    while (a < length && b < length && reference[a] == reference[b]) { ++a; ++b; }
    if (a == length && b == length) return false;
    if (a == length) return false; // End marker 4 sorts after DNA bases.
    if (b == length) return true;
    return reference[a] < reference[b];
}
void put_i64(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t rodinia_mummergpu(const std::int64_t *input, std::size_t length,
                                            std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 5 || length > kMaxInput) return -1;
    if (input[0] < 1 || input[0] > kMaxRef || input[1] < 1 || input[1] > kMaxQuery || input[2] < 1 || input[2] > kMaxQuery) return -1;
    const int ref_len = static_cast<int>(input[0]), query_len = static_cast<int>(input[1]), min_len = static_cast<int>(input[2]);
    if (length != static_cast<std::size_t>(3 + ref_len + query_len)) return -1;
    std::int64_t reference[kMaxRef], query[kMaxQuery];
    for (int i = 0; i < ref_len; ++i) { const auto code = input[3 + i]; if (code < 0 || code > 3) return -1; reference[i] = code; }
    for (int i = 0; i < query_len; ++i) { const auto code = input[3 + ref_len + i]; if (code < 0 || code > 3) return -1; query[i] = code; }

    int children[kMaxNodes * kAlphabet];
    int path_node[kMaxRef * (kMaxRef + 1)];
    int suffix_order[kMaxRef];
    for (auto &child : children) child = -1;
    for (auto &path : path_node) path = -1;
    int node_count = 1;
    for (int start = 0; start < ref_len; ++start) {
        int node = 0, depth = 0;
        path_node[start * (kMaxRef + 1)] = 0;
        for (int pos = start; pos < ref_len; ++pos) {
            const int slot = child_index(node, static_cast<int>(reference[pos]));
            if (children[slot] < 0) {
                const int fresh = node_count++;
                children[slot] = fresh;
                for (int symbol = 0; symbol < kAlphabet; ++symbol) children[child_index(fresh, symbol)] = -1;
            }
            node = children[slot];
            path_node[start * (kMaxRef + 1) + ++depth] = node;
        }
        const int terminal_slot = child_index(node, 4);
        if (children[terminal_slot] < 0) {
            const int fresh = node_count++;
            children[terminal_slot] = fresh;
            for (int symbol = 0; symbol < kAlphabet; ++symbol) children[child_index(fresh, symbol)] = -1;
        }
    }
    for (int i = 0; i < ref_len; ++i) suffix_order[i] = i;
    for (int i = 1; i < ref_len; ++i) {
        const int key = suffix_order[i]; int j = i;
        while (j > 0 && suffix_less(reference, ref_len, key, suffix_order[j - 1])) { suffix_order[j] = suffix_order[j - 1]; --j; }
        suffix_order[j] = key;
    }

    std::int64_t records[kMaxMatches * 3];
    std::size_t match_count = 0;
    for (int qstart = 0; qstart < query_len; ++qstart) {
        int candidate[kMaxRef]; for (int r = 0; r < ref_len; ++r) candidate[r] = -1;
        int node = 0, depth = 0;
        for (;;) {
            const bool query_has_next = qstart + depth < query_len;
            for (int rstart = 0; rstart < ref_len; ++rstart) {
                if (path_node[rstart * (kMaxRef + 1) + depth] != node) continue;
                const bool suffix_ends = rstart + depth == ref_len;
                if (suffix_ends || !query_has_next || reference[rstart + depth] != query[qstart + depth]) candidate[rstart] = depth;
            }
            if (!query_has_next) break;
            const int slot = child_index(node, static_cast<int>(query[qstart + depth]));
            if (children[slot] < 0) break;
            node = children[slot]; ++depth;
        }
        for (int order = 0; order < ref_len; ++order) {
            const int rstart = suffix_order[order], match_len = candidate[rstart];
            if (match_len < min_len) continue;
            if (qstart > 0 && rstart > 0 && query[qstart - 1] == reference[rstart - 1]) continue;
            records[3 * match_count] = rstart + 1;
            records[3 * match_count + 1] = qstart + 1;
            records[3 * match_count + 2] = match_len;
            ++match_count;
        }
    }
    const std::size_t output_bytes = match_count * 24;
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t i = 0; i < 3 * match_count; ++i) put_i64(output, i * 8, records[i]);
    return static_cast<std::int64_t>(output_bytes);
}
