#include <cstddef>
#include <cstdint>

extern "C" std::int64_t multiplexer(const std::int64_t *values, std::size_t length) {
    if (values == nullptr || length != 3) return -1;
    const auto input0 = values[0];
    const auto input1 = values[1];
    const auto select = values[2];
    if ((input0 != 0 && input0 != 1) || (input1 != 0 && input1 != 1) ||
        (select != 0 && select != 1)) return -1;
    return select == 1 ? input1 : input0;
}
