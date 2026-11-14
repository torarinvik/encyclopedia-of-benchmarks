#include <array>
#include <cstddef>
#include <cstdint>

namespace {
int popcount(unsigned value) {
    int count = 0;
    for (int bit = 0; bit < 8; ++bit) count += (value >> bit) & 1u;
    return count;
}
unsigned decode(int cls, int offset) {
    for (unsigned candidate = 0; candidate < 256; ++candidate) {
        if (popcount(candidate) == cls && offset-- == 0) return candidate;
    }
    return 0;
}
}

extern "C" std::int64_t rrr_class_offset_rank_select(const std::int64_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 3 || length > 35 || input[0] < 1 || input[0] > 63 || input[1] < 0 || input[2] < 0 || input[2] > 16) return -1;
    const int n = static_cast<int>(input[0]), q = static_cast<int>(input[2]);
    const auto bits = static_cast<std::uint64_t>(input[1]);
    if ((bits >> n) != 0 || length != static_cast<std::size_t>(3+2*q)) return -1;
    for (int i = 0; i < q; ++i) {
        const auto op = input[3+2*i], index = input[4+2*i];
        if ((op != 0 && op != 1) || index < 1 || (op == 0 && index > n) || (op == 1 && index > 64)) return -1;
    }
    if (output == nullptr || capacity < static_cast<std::size_t>(8*q)) return -2;
    std::array<int, 8> classes{}, offsets{};
    std::array<int, 9> prefix{};
    const int blocks = (n+7)/8;
    for (int block = 0; block < blocks; ++block) {
        const auto byte = static_cast<unsigned>((bits >> (8*block)) & 255u);
        classes[block] = popcount(byte);
        for (unsigned candidate = 0; candidate < byte; ++candidate) if (popcount(candidate) == classes[block]) ++offsets[block];
        prefix[block+1] = prefix[block] + classes[block];
    }
    for (int i = 0; i < q; ++i) {
        const int op = static_cast<int>(input[3+2*i]), index = static_cast<int>(input[4+2*i]);
        int answer = -1;
        if (op == 0) {
            const int block = (index-1)/8;
            const unsigned byte = decode(classes[block], offsets[block]);
            answer = prefix[block];
            for (int bit = 0; bit < index-8*block; ++bit) answer += (byte >> bit) & 1u;
        } else {
            int block = 0;
            while (block < blocks && prefix[block+1] < index) ++block;
            if (block < blocks) {
                int remaining = index-prefix[block];
                const unsigned byte = decode(classes[block], offsets[block]);
                for (int bit = 0; bit < 8 && 8*block+bit < n; ++bit) {
                    if (((byte >> bit) & 1u) && --remaining == 0) { answer = 8*block+bit+1; break; }
                }
            }
        }
        auto encoded = static_cast<std::uint64_t>(static_cast<std::int64_t>(answer));
        for (int byte = 0; byte < 8; ++byte) { output[8*i+byte] = static_cast<std::uint8_t>(encoded & 255u); encoded >>= 8; }
    }
    return 8*q;
}
