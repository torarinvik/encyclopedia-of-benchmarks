#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 12;
constexpr std::size_t kMaxInput = 15;
constexpr std::size_t kWidth = kMaxN + 1;
constexpr std::int64_t kInf = 1000;

std::int64_t run_cost(int kept) {
    if (kept == 1) return 1;
    int digits = 0;
    while (kept > 0) { ++digits; kept /= 10; }
    return 1 + digits;
}
}

extern "C" std::int64_t string_compression_ii(const std::int64_t* input,
                                               std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > kMaxInput) return -1;
    const std::int64_t raw_n = input[0], raw_k = input[1];
    if (raw_n < 0 || raw_n > static_cast<std::int64_t>(kMaxN) || raw_k < 0 || raw_k > raw_n)
        return -1;
    const auto n = static_cast<std::size_t>(raw_n);
    const auto budget = static_cast<std::size_t>(raw_k);
    if (length != n + 2) return -1;
    for (std::size_t i = 0; i < n; ++i) if (input[i + 2] < 0 || input[i + 2] > 25) return -1;

    std::int64_t dp[kWidth][kWidth];
    for (auto& row : dp) for (auto& cell : row) cell = kInf;
    dp[0][0] = 0;
    for (std::size_t start = 0; start < n; ++start) {
        for (std::size_t used = 0; used <= budget; ++used) {
            const auto prefix_cost = dp[start][used];
            if (prefix_cost == kInf) continue;
            if (used < budget && prefix_cost < dp[start + 1][used + 1])
                dp[start + 1][used + 1] = prefix_cost;
            int same = 0;
            for (std::size_t end = start; end < n; ++end) {
                if (input[end + 2] == input[start + 2]) ++same;
                const int span = static_cast<int>(end - start + 1);
                for (int kept = 1; kept <= same; ++kept) {
                    const auto total_deleted = used + static_cast<std::size_t>(span - kept);
                    if (total_deleted > budget) continue;
                    const auto candidate = prefix_cost + run_cost(kept);
                    if (candidate < dp[end + 1][total_deleted])
                        dp[end + 1][total_deleted] = candidate;
                }
            }
        }
    }
    auto answer = kInf;
    for (std::size_t deleted = 0; deleted <= budget; ++deleted)
        if (dp[n][deleted] < answer) answer = dp[n][deleted];
    return answer;
}
