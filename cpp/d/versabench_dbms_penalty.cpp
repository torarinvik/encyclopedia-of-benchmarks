#include <algorithm>
#include <cstddef>
#include <cstdint>

extern "C" int64_t versabench_dbms_penalty(const int64_t *values, size_t length) {
    if (values == nullptr || length < 1 || length > 17 || length != 16) return -1;
    for (size_t box = 0; box < 2; ++box) for (size_t d = 0; d < 4; ++d) {
        const int64_t lo = values[box*8+d], hi = values[box*8+4+d];
        if (lo < -8 || lo > 8 || hi < -8 || hi > 8 || lo >= hi) return -1;
    }
    int64_t joined = 1, original = 1;
    for (size_t d = 0; d < 4; ++d) {
        joined *= std::max(values[4+d], values[12+d]) - std::min(values[d], values[8+d]);
        original *= values[4+d] - values[d];
    }
    return joined - original;
}
