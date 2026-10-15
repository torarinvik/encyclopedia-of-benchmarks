// XOR-swap a bounded signed pair and pack the returned values into i64.
#include <cstdint>

extern "C" std::int64_t xor_swap_two_integers(std::int64_t first,
                                                std::int64_t second) noexcept {
    if (first < -32768 || first > 32767 || second < -32768 || second > 32767) return -1;
    std::int64_t a = first < 0 ? first + 65536 : first;
    std::int64_t b = second < 0 ? second + 65536 : second;
    a ^= b;
    b ^= a;
    a ^= b;
    const std::int64_t swapped_first = a >= 32768 ? a - 65536 : a;
    const std::int64_t swapped_second = b >= 32768 ? b - 65536 : b;
    return (swapped_first + 32768) * 65536 + (swapped_second + 32768);
}
