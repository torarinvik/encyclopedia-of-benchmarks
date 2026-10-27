#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_TEXT = 12, MAX_INPUT = 14, MAX_OUTPUT = 1592;
std::size_t minimum(std::size_t a, std::size_t b) { return a < b ? a : b; }

std::size_t edit_distance(const std::int64_t *text, std::size_t a, std::size_t a_len,
                          std::size_t b, std::size_t b_len) {
    std::size_t row[MAX_TEXT + 1];
    for (std::size_t j = 0; j <= b_len; ++j) row[j] = j;
    for (std::size_t i = 1; i <= a_len; ++i) {
        auto diagonal = row[0];
        row[0] = i;
        for (std::size_t j = 1; j <= b_len; ++j) {
            const auto above = row[j];
            const auto deletion = above + 1;
            const auto insertion = row[j - 1] + 1;
            const auto substitution = diagonal + (text[a + i - 1] != text[b + j - 1]);
            row[j] = minimum(minimum(deletion, insertion), substitution);
            diagonal = above;
        }
    }
    return row[b_len];
}

std::size_t minimum_edit_cost(const std::int64_t *text, std::size_t start, std::size_t length) {
    std::size_t best = 1000;
    std::size_t piece_start[MAX_TEXT], piece_length[MAX_TEXT];
    for (std::size_t prefix = 0; prefix <= length; ++prefix) {
        for (std::size_t suffix = 0; suffix + prefix <= length; ++suffix) {
            const auto middle = length - prefix - suffix;
            if (middle < 2) continue;
            const auto end_mask = std::uint32_t{1} << (middle - 1);
            for (std::uint32_t mask = 1; mask < end_mask; ++mask) {
                std::size_t segments = 0, previous = 0;
                for (std::size_t cut = 1; cut < middle; ++cut) {
                    if ((mask & (std::uint32_t{1} << (cut - 1))) != 0) {
                        piece_start[segments] = start + prefix + previous;
                        piece_length[segments++] = cut - previous;
                        previous = cut;
                    }
                }
                piece_start[segments] = start + prefix + previous;
                piece_length[segments++] = middle - previous;
                std::size_t left = 1000, right = 1000, internal = 0;
                for (std::size_t fragment = 0; fragment <= piece_length[0]; ++fragment) {
                    const auto cost = edit_distance(text, start, prefix,
                        piece_start[0] + piece_length[0] - fragment, fragment);
                    if (cost < left) left = cost;
                }
                const auto last = segments - 1;
                for (std::size_t fragment = 0; fragment <= piece_length[last]; ++fragment) {
                    const auto cost = edit_distance(text, piece_start[last], fragment,
                        start + length - suffix, suffix);
                    if (cost < right) right = cost;
                }
                for (std::size_t i = 0; i + 1 < segments; ++i)
                    internal += edit_distance(text, piece_start[i], piece_length[i],
                                              piece_start[i + 1], piece_length[i + 1]);
                const auto total = left + internal + right;
                if (total < best) best = total;
            }
        }
    }
    return best;
}

std::size_t count_records(const std::int64_t *text, std::size_t n, std::size_t budget) {
    std::size_t count = 0;
    for (std::size_t start = 0; start < n; ++start)
        for (std::size_t length = 2; length <= n - start; ++length)
            count += minimum_edit_cost(text, start, length) <= budget;
    return count;
}
void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) { output[offset + byte] = static_cast<std::uint8_t>(bits & 255u); bits >>= 8; }
}
}

extern "C" std::int64_t approximate_tandem_k_edit_repeats(
    const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (!input || length < 4 || length > MAX_INPUT) return -1;
    const auto n0 = input[0], budget0 = input[1];
    if (n0 < 2 || n0 > MAX_TEXT || budget0 < 0 || budget0 > 4 || length != static_cast<std::size_t>(n0) + 2) return -1;
    const auto n = static_cast<std::size_t>(n0), budget = static_cast<std::size_t>(budget0);
    const auto *text = input + 2;
    for (std::size_t i = 0; i < n; ++i) if (text[i] < 0 || text[i] > 3) return -1;
    const auto count = count_records(text, n, budget);
    const auto bytes = 8 * (1 + 3 * count);
    if (bytes > MAX_OUTPUT) return -1;
    if (!output || capacity < bytes) return -2;
    store_i64_le(output, 0, static_cast<std::int64_t>(count));
    std::size_t record = 0;
    for (std::size_t start = 0; start < n; ++start)
        for (std::size_t factor_length = 2; factor_length <= n - start; ++factor_length) {
            const auto cost = minimum_edit_cost(text, start, factor_length);
            if (cost <= budget) {
                const auto offset = 8 * (1 + 3 * record++);
                store_i64_le(output, offset, static_cast<std::int64_t>(start));
                store_i64_le(output, offset + 8, static_cast<std::int64_t>(factor_length));
                store_i64_le(output, offset + 16, static_cast<std::int64_t>(cost));
            }
        }
    return static_cast<std::int64_t>(bytes);
}
