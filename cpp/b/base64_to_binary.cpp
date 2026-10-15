#include <cstddef>
#include <cstdint>
namespace {
bool edge_space(std::int64_t v) { return (v >= 9 && v <= 13) || v == 32; }
int digit(std::int64_t c) {
    if (c >= 'A' && c <= 'Z') return int(c - 'A');
    if (c >= 'a' && c <= 'z') return int(c - 'a' + 26);
    if (c >= '0' && c <= '9') return int(c - '0' + 52);
    if (c == '+') return 62;
    if (c == '/') return 63;
    return -1;
}
}
extern "C" std::int64_t base64_to_binary(const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (!input || length < 1 || input[0] < 0 || input[0] > 256) return -1;
    const auto n = std::size_t(input[0]);
    if (length != n + 1) return -1;
    for (std::size_t i = 0; i < n; ++i) if (input[i + 1] < 0 || input[i + 1] > 127) return -1;
    std::size_t begin = 0, end = n;
    while (begin < end && edge_space(input[begin + 1])) ++begin;
    while (end > begin && edge_space(input[end])) --end;
    if (begin == end) return -1;
    const bool negative = input[begin + 1] == '-';
    if (negative) ++begin;
    for (std::size_t i = begin; i < end; ++i) if (digit(input[i + 1]) < 0) return -1;
    const auto out_len = (end - begin) * 6 + (negative ? 1 : 0);
    if (capacity < out_len || !output) return -2;
    std::size_t offset = 0;
    if (negative) output[offset++] = '-';
    for (std::size_t i = begin; i < end; ++i) {
        const auto value = unsigned(digit(input[i + 1]));
        for (int bit = 5; bit >= 0; --bit) output[offset++] = std::uint8_t('0' + ((value >> bit) & 1));
    }
    return std::int64_t(out_len);
}
