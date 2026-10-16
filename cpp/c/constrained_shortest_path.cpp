#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t max_nodes = 16;
constexpr std::size_t max_edges = 64;
constexpr std::size_t max_resource = 32;
constexpr std::int64_t inf = std::numeric_limits<std::int64_t>::max();
}

extern "C" std::int64_t constrained_shortest_path(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 5) return -2;
    const auto n_raw = input[0], m_raw = input[1];
    const auto start = input[2], target = input[3], limit_raw = input[4];
    if (n_raw < 1 || n_raw > static_cast<std::int64_t>(max_nodes) ||
        m_raw < 0 || m_raw > static_cast<std::int64_t>(max_edges) ||
        limit_raw < 0 || limit_raw > static_cast<std::int64_t>(max_resource)) return -2;
    const auto n = static_cast<std::size_t>(n_raw);
    const auto m = static_cast<std::size_t>(m_raw);
    const auto limit = static_cast<std::size_t>(limit_raw);
    if (length != 5 + 4 * m || start < 0 || start >= n_raw || target < 0 || target >= n_raw) return -2;
    for (std::size_t e = 0; e < m; ++e) {
        const auto p = 5 + 4 * e;
        if (input[p] < 0 || input[p] >= n_raw || input[p+1] < 0 || input[p+1] >= n_raw ||
            input[p+2] < 0 || input[p+2] > 1000 || input[p+3] < 1 || input[p+3] > static_cast<std::int64_t>(max_resource)) return -2;
    }
    std::int64_t dp[max_resource+1][max_nodes];
    for (std::size_t r=0; r<=limit; ++r) for (std::size_t u=0; u<n; ++u) dp[r][u]=inf;
    dp[0][static_cast<std::size_t>(start)]=0;
    for (std::size_t r=0; r<=limit; ++r) {
        for (std::size_t u=0; u<n; ++u) {
            if (dp[r][u]==inf) continue;
            for (std::size_t e=0; e<m; ++e) {
                const auto p=5+4*e;
                if (static_cast<std::size_t>(input[p])!=u) continue;
                const auto resource=static_cast<std::size_t>(input[p+3]);
                if (r+resource<=limit) {
                    const auto v=static_cast<std::size_t>(input[p+1]);
                    const auto candidate=dp[r][u]+input[p+2];
                    if (candidate<dp[r+resource][v]) dp[r+resource][v]=candidate;
                }
            }
        }
    }
    auto answer=inf;
    for (std::size_t r=0; r<=limit; ++r) if (dp[r][static_cast<std::size_t>(target)]<answer) answer=dp[r][static_cast<std::size_t>(target)];
    return answer==inf ? -1 : answer;
}
