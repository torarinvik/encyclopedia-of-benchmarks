#include <cstdint>

extern "C" std::int64_t imply_gate(std::uint64_t left, std::uint64_t right) {
    if (left > 1 || right > 1) return -1;
    return left == 0 || right == 1 ? 1 : 0;
}
