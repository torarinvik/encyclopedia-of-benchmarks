#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxStates = 4;
constexpr std::size_t kMaxInput = 26;
constexpr std::size_t kMaxAssignments = 1024;
constexpr std::size_t kMaxOutputWords = 2 + 5 * kMaxAssignments;
constexpr std::int64_t kInf = 1000000;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value)
{
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t substring_parsimony(const std::int64_t *input, std::size_t length,
                                               std::uint8_t *output, std::size_t capacity)
{
    if (input == nullptr || length < 10 || length > kMaxInput) return -1;
    const auto q_raw = input[0];
    const auto threshold = input[1];
    if (q_raw < 1 || q_raw > static_cast<std::int64_t>(kMaxStates)
        || threshold < 0 || threshold > 36) return -1;
    const auto q = static_cast<std::size_t>(q_raw);
    if (length != 9 + q * q) return -1;
    const std::int64_t child[2][2] = {{input[2], input[3]}, {input[4], input[5]}};
    for (std::size_t node = 0; node < 2; ++node)
        if (child[node][0] < 1 || child[node][0] > 4 || child[node][1] < 1 || child[node][1] > 4
            || child[node][0] == child[node][1]) return -1;
    std::int64_t root_leaf = -1;
    if (child[0][0] == 1) root_leaf = child[0][1];
    else if (child[0][1] == 1) root_leaf = child[0][0];
    if (root_leaf < 2 || root_leaf > 4) return -1;
    if (child[1][0] < 2 || child[1][0] > 4 || child[1][1] < 2 || child[1][1] > 4
        || child[1][0] == child[1][1] || child[1][0] == root_leaf || child[1][1] == root_leaf) return -1;
    for (std::int64_t leaf = 2; leaf <= 4; ++leaf)
        if (leaf != root_leaf && child[1][0] != leaf && child[1][1] != leaf) return -1;

    std::int64_t masks[3]{};
    const auto universe = (std::uint64_t{1} << q) - 1;
    for (std::size_t leaf = 0; leaf < 3; ++leaf) {
        masks[leaf] = input[6 + leaf];
        if (masks[leaf] <= 0 || static_cast<std::uint64_t>(masks[leaf]) > universe) return -1;
    }
    std::int64_t distance[kMaxStates][kMaxStates]{};
    for (std::size_t i = 0; i < q; ++i) {
        for (std::size_t j = 0; j < q; ++j) {
            const auto value = input[9 + i * q + j];
            if (value < 0 || value > 9 || (i == j && value != 0) || (i != j && value == 0)) return -1;
            distance[i][j] = value;
            if (value != input[9 + j * q + i]) return -1;
        }
    }
    for (std::size_t i = 0; i < q; ++i)
        for (std::size_t j = 0; j < q; ++j)
            for (std::size_t k = 0; k < q; ++k)
                if (distance[i][k] > distance[i][j] + distance[j][k]) return -1;

    std::int64_t dp[5][kMaxStates];
    for (std::size_t node = 0; node < 5; ++node)
        for (std::size_t state = 0; state < q; ++state) dp[node][state] = kInf;
    for (std::size_t leaf = 2; leaf <= 4; ++leaf)
        for (std::size_t state = 0; state < q; ++state)
            if ((static_cast<std::uint64_t>(masks[leaf - 2]) & (std::uint64_t{1} << state)) != 0)
                dp[leaf][state] = 0;
    for (int node = 1; node >= 0; --node) {
        for (std::size_t state = 0; state < q; ++state) {
            std::int64_t total = 0;
            for (std::size_t slot = 0; slot < 2; ++slot) {
                const auto descendant = static_cast<std::size_t>(child[node][slot]);
                std::int64_t best = kInf;
                for (std::size_t other = 0; other < q; ++other)
                    if (dp[descendant][other] + distance[state][other] < best)
                        best = dp[descendant][other] + distance[state][other];
                total += best;
            }
            dp[node][state] = total;
        }
    }
    std::int64_t optimum = kInf;
    for (std::size_t state = 0; state < q; ++state) if (dp[0][state] < optimum) optimum = dp[0][state];
    if (optimum >= kInf) return -1;

    std::int64_t staged[kMaxOutputWords]{};
    staged[0] = optimum;
    std::size_t words = 2;
    if (optimum <= threshold) {
        for (std::size_t x0 = 0; x0 < q; ++x0)
            for (std::size_t x1 = 0; x1 < q; ++x1)
                for (std::size_t x2 = 0; x2 < q; ++x2) {
                    if ((static_cast<std::uint64_t>(masks[0]) & (std::uint64_t{1} << x2)) == 0) continue;
                    for (std::size_t x3 = 0; x3 < q; ++x3) {
                        if ((static_cast<std::uint64_t>(masks[1]) & (std::uint64_t{1} << x3)) == 0) continue;
                        for (std::size_t x4 = 0; x4 < q; ++x4) {
                            if ((static_cast<std::uint64_t>(masks[2]) & (std::uint64_t{1} << x4)) == 0) continue;
                            const std::size_t label[5] = {x0, x1, x2, x3, x4};
                            std::int64_t score = 0;
                            for (std::size_t node = 0; node < 2; ++node)
                                for (std::size_t slot = 0; slot < 2; ++slot)
                                    score += distance[label[node]][label[static_cast<std::size_t>(child[node][slot])]];
                            if (score == optimum)
                                for (std::size_t node = 0; node < 5; ++node) staged[words++] = static_cast<std::int64_t>(label[node]);
                        }
                    }
                }
    }
    staged[1] = static_cast<std::int64_t>((words - 2) / 5);
    const auto bytes = words * 8;
    if (output == nullptr || capacity < bytes) return -2;
    for (std::size_t word = 0; word < words; ++word) store_i64_le(output, word * 8, staged[word]);
    return static_cast<std::int64_t>(bytes);
}
