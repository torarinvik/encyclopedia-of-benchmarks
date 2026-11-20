#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxWords = 16;
constexpr int kMaxQueries = 8;
constexpr int kMaxLength = 10;
constexpr int kMaxRadius = 3;
using ChildTable = std::array<std::array<int, kMaxLength + 1>, kMaxWords>;

bool valid_word(std::int64_t word) noexcept {
    if (word < 0 || (static_cast<std::uint64_t>(word) >> 44) != 0) return false;
    const int length = static_cast<int>((static_cast<std::uint64_t>(word) >> 40) & 15U);
    if (length > kMaxLength) return false;
    for (int i = 0; i < kMaxLength; ++i) {
        const int symbol = static_cast<int>((static_cast<std::uint64_t>(word) >> (4 * i)) & 15U);
        if ((i < length && symbol == 0) || (i >= length && symbol != 0)) return false;
    }
    return true;
}

int distance(std::int64_t left, std::int64_t right) noexcept {
    const int n = static_cast<int>((static_cast<std::uint64_t>(left) >> 40) & 15U);
    const int m = static_cast<int>((static_cast<std::uint64_t>(right) >> 40) & 15U);
    std::array<int, kMaxLength + 1> previous{};
    std::array<int, kMaxLength + 1> current{};
    for (int j = 0; j <= m; ++j) previous[static_cast<std::size_t>(j)] = j;
    for (int i = 1; i <= n; ++i) {
        current[0] = i;
        const auto a = (static_cast<std::uint64_t>(left) >> (4 * (i - 1))) & 15U;
        for (int j = 1; j <= m; ++j) {
            const auto b = (static_cast<std::uint64_t>(right) >> (4 * (j - 1))) & 15U;
            const int deletion = previous[static_cast<std::size_t>(j)] + 1;
            const int insertion = current[static_cast<std::size_t>(j - 1)] + 1;
            const int replacement = previous[static_cast<std::size_t>(j - 1)] + (a != b);
            current[static_cast<std::size_t>(j)] = std::min(std::min(deletion, insertion), replacement);
        }
        previous = current;
    }
    return previous[static_cast<std::size_t>(m)];
}
} // namespace

extern "C" std::int64_t bk_tree_edit_distance_search(const std::int64_t *input,
                                                       std::size_t length) noexcept {
    if (input == nullptr || length < 3 || length > 28) return -1;
    const auto n_value = input[0];
    const auto q_value = input[1];
    const auto radius_value = input[2];
    if (n_value < 0 || n_value > kMaxWords || q_value < 0 || q_value > kMaxQueries
            || radius_value < 0 || radius_value > kMaxRadius
            || length != static_cast<std::size_t>(3 + n_value + q_value)) return -1;
    const int n = static_cast<int>(n_value);
    const int q = static_cast<int>(q_value);
    const int radius = static_cast<int>(radius_value);
    const auto *words = input + 3;
    const auto *queries = words + n;
    for (int i = 0; i < n + q; ++i)
        if (!valid_word(words[i])) return -1;
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < i; ++j)
            if (words[i] == words[j]) return -1;

    ChildTable children{};
    for (auto &row : children) row.fill(-1);
    for (int node = 1; node < n; ++node) {
        int pivot = 0;
        for (;;) {
            const int edge = distance(words[node], words[pivot]);
            int &child = children[static_cast<std::size_t>(pivot)][static_cast<std::size_t>(edge)];
            if (child == -1) {
                child = node;
                break;
            }
            pivot = child;
        }
    }

    std::int64_t result = 0;
    for (int qi = 0; qi < q; ++qi) {
        int matches = 0;
        int index_sum = 0;
        if (n != 0) {
            std::array<int, kMaxWords> stack{};
            int top = 0;
            stack[static_cast<std::size_t>(top++)] = 0;
            while (top != 0) {
                const int node = stack[static_cast<std::size_t>(--top)];
                const int d = distance(queries[qi], words[node]);
                if (d <= radius) {
                    ++matches;
                    index_sum += node;
                }
                const int low = d - radius > 0 ? d - radius : 0;
                const int high = d + radius < kMaxLength ? d + radius : kMaxLength;
                for (int edge = low; edge <= high; ++edge) {
                    const int child = children[static_cast<std::size_t>(node)][static_cast<std::size_t>(edge)];
                    if (child != -1) stack[static_cast<std::size_t>(top++)] = child;
                }
            }
        }
        result += static_cast<std::int64_t>(qi + 1) * (17 * matches + index_sum);
    }
    return result;
}
