#include <cstdint>

namespace {
constexpr std::int64_t max_n = 15;
}

extern "C" std::int64_t nestedloop(std::int64_t input) noexcept {
    if (input < 0 || input > max_n) return -1;
    const int n = static_cast<int>(input);
    int x = 0;
    for (int a = 0; a < n; ++a)
        for (int b = 0; b < n; ++b)
            for (int c = 0; c < n; ++c)
                for (int d = 0; d < n; ++d)
                    for (int e = 0; e < n; ++e)
                        for (int f = 0; f < n; ++f)
                            ++x;
    return x;
}
