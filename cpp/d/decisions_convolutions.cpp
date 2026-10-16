#include <cstddef>
#include <cstdint>

extern "C" std::int64_t decisions_convolutions(const std::int64_t *input, std::size_t length) noexcept
{
    constexpr std::size_t max_decisions=64, max_criteria=16;
    constexpr std::int64_t max_value=100000;
    if (!input || length<3) return -1;
    const auto method=input[0], n_arg=input[1], m_arg=input[2];
    if ((method!=0 && method!=1) || n_arg<1 || n_arg>static_cast<std::int64_t>(max_decisions)
        || m_arg<1 || m_arg>static_cast<std::int64_t>(max_criteria)) return -1;
    const auto n=static_cast<std::size_t>(n_arg), m=static_cast<std::size_t>(m_arg);
    if (length!=3+m+n*m) return -1;
    for (std::size_t j=0;j<m;j++) if (input[3+j]<-max_value || input[3+j]>max_value) return -1;
    for (std::size_t i=0;i<n*m;i++) if (input[3+m+i]<-max_value || input[3+m+i]>max_value) return -1;
    std::int64_t best_score=0; std::size_t best_index=0;
    for (std::size_t i=0;i<n;i++) {
        std::int64_t score=0;
        for (std::size_t j=0;j<m;j++) {
            const auto product=input[3+m+i*m+j]*input[3+j];
            if (method==0) score+=product;
            else if (j==0 || product<score) score=product;
        }
        if (i==0 || score>best_score) { best_score=score; best_index=i; }
    }
    return static_cast<std::int64_t>(best_index);
}
