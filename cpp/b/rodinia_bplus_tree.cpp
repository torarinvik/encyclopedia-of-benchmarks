/* Rodinia B+ tree point-search profile; see package README and LICENSE.txt. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t rodinia_bplus_tree(const std::int64_t *input, std::size_t length) noexcept {
    constexpr std::size_t max_leaf = 3, max_queries = 16;
    if (input == nullptr || length < 7 || length > 31) return -1;
    if (input[0] < 1 || input[0] > 3 || input[1] < 1 || input[1] > 3 ||
        input[2] < 1 || input[2] > static_cast<std::int64_t>(max_queries)) return -1;
    const auto left_n = static_cast<std::size_t>(input[0]);
    const auto right_n = static_cast<std::size_t>(input[1]);
    const auto query_n = static_cast<std::size_t>(input[2]);
    if (length != 3 + 2 * (left_n + right_n) + query_n) return -1;
    std::int64_t keys[2][max_leaf]{}, values[2][max_leaf]{};
    const std::size_t counts[2] = {left_n, right_n};
    std::size_t cursor = 3;
    for (std::size_t leaf = 0; leaf < 2; ++leaf) {
        for (std::size_t slot = 0; slot < counts[leaf]; ++slot) {
            const auto key = input[cursor++], value = input[cursor++];
            if (key < -1000000 || key > 1000000 || value < 0 || value > 1000000 ||
                (slot != 0 && key <= keys[leaf][slot - 1])) return -1;
            keys[leaf][slot] = key; values[leaf][slot] = value;
        }
    }
    if (keys[0][left_n - 1] >= keys[1][0]) return -1;
    std::int64_t answer = 0;
    for (std::size_t query_index = 0; query_index < query_n; ++query_index) {
        const auto query = input[cursor++];
        if (query < -1000000 || query > 1000000) return -1;
        const std::size_t leaf = query < keys[1][0] ? 0 : 1;
        for (std::size_t slot = 0; slot < counts[leaf]; ++slot)
            if (keys[leaf][slot] == query) { answer += static_cast<std::int64_t>(query_index + 1) * (values[leaf][slot] + 1); break; }
    }
    return answer;
}
