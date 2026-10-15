/* Preserve the duplicate-need bookkeeping in the pinned Python demonstration. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t bankers_algorithm_python_demo(const std::int64_t *values, std::size_t length) noexcept
{
    constexpr std::size_t max_n = 16, max_m = 8;
    if (!values || length < 5 || length > 266) return -1;
    auto nv = values[0], mv = values[1];
    if (nv < 1 || nv > 16 || mv < 1 || mv > 8) return -1;
    auto n = static_cast<std::size_t>(nv), m = static_cast<std::size_t>(mv);
    auto aoff = 2 + m, moff = aoff + n * m;
    if (length != moff + n * m) return -1;
    std::int64_t work[max_m]{};
    for (std::size_t r = 0; r < m; ++r) { auto claim = values[2 + r]; if (claim < 0 || claim > 100) return -1; work[r] = claim; }
    for (std::size_t p = 0; p < n; ++p) for (std::size_t r = 0; r < m; ++r) {
        auto i = p * m + r, allocation = values[aoff + i], maximum = values[moff + i];
        if (allocation < 0 || allocation > 100 || maximum < 0 || maximum > 100 || allocation > maximum) return -1;
        work[r] -= allocation;
    }
    for (std::size_t r = 0; r < m; ++r) if (work[r] < 0) return -1;
    std::size_t first_equal[max_n]{}, remaining[max_n]{};
    for (std::size_t p = 0; p < n; ++p) {
        first_equal[p] = p; remaining[p] = p;
        for (std::size_t q = 0; q < p; ++q) {
            bool equal = true;
            for (std::size_t r = 0; r < m; ++r) { auto pi = p*m+r, qi = q*m+r; if (values[moff+pi]-values[aoff+pi] != values[moff+qi]-values[aoff+qi]) { equal = false; break; } }
            if (equal) { first_equal[p] = first_equal[q]; break; }
        }
    }
    std::size_t count = n;
    while (count) {
        std::size_t selected = count;
        for (std::size_t i = 0; i < count; ++i) { auto p = remaining[i]; bool feasible = true;
            for (std::size_t r = 0; r < m; ++r) { auto j=p*m+r; if (values[moff+j]-values[aoff+j] > work[r]) { feasible=false; break; } }
            if (feasible) { selected=i; break; }
        }
        if (selected == count) return 0;
        auto mapped = first_equal[remaining[selected]];
        for (std::size_t r=0;r<m;++r) work[r] += values[aoff+mapped*m+r];
        for (std::size_t i=selected+1;i<count;++i) remaining[i-1]=remaining[i];
        --count;
    }
    return 1;
}
