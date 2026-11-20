// Uncompiled duplicate-aware distinct-LCS counting draft.
#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
extern "C" std::int64_t count_distinct_lcs(const std::int64_t* input, std::size_t length) {
    constexpr std::int64_t mod = 1000000007;
    if (!input || length < 2 || length > 131) return -1;
    const auto nr = input[0], mr = input[1];
    if (nr < 0 || nr > 64 || mr < 0 || mr > 64 || length != static_cast<std::size_t>(2+nr+mr)) return -1;
    const auto n = static_cast<std::size_t>(nr), m = static_cast<std::size_t>(mr);
    for (std::size_t i = 2; i < length; ++i) if (input[i] < 0 || input[i] > 255) return -1;
    std::array<int,65> prev_len{}, curr_len{};
    std::array<std::int64_t,65> prev_count{}, curr_count{};
    prev_count.fill(1);
    for (std::size_t i = 1; i <= n; ++i) {
        curr_len[0] = 0; curr_count[0] = 1;
        for (std::size_t j = 1; j <= m; ++j) {
            if (input[1+i] == input[1+n+j]) {
                curr_len[j] = prev_len[j-1]+1; curr_count[j] = prev_count[j-1];
            } else {
                const auto best = std::max(prev_len[j], curr_len[j-1]);
                std::int64_t count = 0;
                if (prev_len[j] == best) count += prev_count[j];
                if (curr_len[j-1] == best) count += curr_count[j-1];
                if (prev_len[j-1] == best) count -= prev_count[j-1];
                curr_len[j] = best; curr_count[j] = (count+mod)%mod;
            }
        }
        prev_len = curr_len; prev_count = curr_count;
    }
    return prev_count[m];
}
