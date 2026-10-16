#include <cstddef>
#include <cstdint>
namespace { constexpr std::size_t max_vertices=8, max_states=256, max_input_length=65; }
extern "C" std::int64_t hamiltonian_path_exists(const std::int64_t* input, std::size_t length) noexcept {
    if (!input || length < 1 || length > max_input_length || input[0] < 0 || input[0] > max_vertices) return -1;
    const auto n=static_cast<std::size_t>(input[0]);
    if (length != 1 + n*n) return -1;
    std::uint64_t routes[max_vertices]{};
    for (std::size_t row=0;row<n;++row) for (std::size_t col=0;col<n;++col) { const auto cell=input[1+row*n+col]; if (cell != 0 && cell != 1) return -1; if (cell) routes[row] |= std::uint64_t{1}<<col; }
    bool dp[max_states][max_vertices]{};
    for (std::size_t start=0;start<n;++start) dp[std::size_t{1}<<start][start]=true;
    const auto full=(std::size_t{1}<<n)-1;
    for (std::size_t mask=1;mask<=full;++mask) for (std::size_t last=0;last<n;++last) { if (!dp[mask][last]) continue; for (std::size_t next=0;next<n;++next) { const auto bit=std::size_t{1}<<next; if (!(mask&bit) && (routes[last]&bit)) dp[mask|bit][next]=true; } }
    for (std::size_t last=0;last<n;++last) if (dp[full][last]) return 1;
    return 0;
}
