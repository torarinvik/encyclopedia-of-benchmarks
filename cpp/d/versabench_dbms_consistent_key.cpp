#include <cstddef>
#include <cstdint>

extern "C" std::int64_t versabench_dbms_consistent_key(const std::int64_t *values, std::size_t length) {
    if (values == nullptr || length < 1 || length > 17 || length != 16) return -1;
    for (std::size_t box = 0; box < 2; ++box) for (std::size_t d = 0; d < 4; ++d) {
        const auto base = box * 8;
        const auto lower = values[base+d], upper = values[base+4+d];
        if (lower < -8 || lower > 8 || upper < -8 || upper > 8 || lower > upper) return -1;
    }
    for (std::size_t d = 0; d < 4; ++d) if (values[d] > values[12+d] || values[8+d] > values[4+d]) return 0;
    return 1;
}
