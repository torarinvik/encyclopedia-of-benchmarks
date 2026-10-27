#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 32, MAX_Q = 32, BUCKET = 3, MAX_B = 11, MAX_WORDS = 100;
int lcp(std::uint16_t a, std::uint16_t b) {
    int n = 0;
    while (n < 16 && ((a >> (15 - n)) & 1u) == ((b >> (15 - n)) & 1u)) ++n;
    return n;
}
void put_i64(std::uint8_t* out, std::size_t pos, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t i = 0; i < 8; ++i) out[pos + i] = static_cast<std::uint8_t>(bits >> (8 * i));
}
}

extern "C" std::int64_t mmpfh_bucketing(const std::int64_t* input, std::size_t length,
                                         std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 3 || length > 66) return -1;
    const auto n0 = input[0], q0 = input[1];
    if (n0 < 1 || n0 > static_cast<std::int64_t>(MAX_N) || q0 < 1 || q0 > static_cast<std::int64_t>(MAX_Q) ||
        length != 2 + static_cast<std::size_t>(n0 + q0)) return -1;
    const auto n = static_cast<std::size_t>(n0), q = static_cast<std::size_t>(q0);
    std::array<std::uint16_t, MAX_N> keys{};
    std::array<std::uint16_t, MAX_Q> queries{};
    for (std::size_t i = 0; i < n; ++i) {
        const auto x = input[2 + i];
        if (x < 0 || x > 65535 || (i && input[1 + i] >= x)) return -1;
        keys[i] = static_cast<std::uint16_t>(x);
    }
    for (std::size_t i = 0; i < q; ++i) {
        const auto x = input[2 + n + i];
        if (x < 0 || x > 65535) return -1;
        queries[i] = static_cast<std::uint16_t>(x);
        bool found = false;
        for (std::size_t j = 0; j < n; ++j) found |= keys[j] == queries[i];
        if (!found) return -1;
    }
    const std::size_t buckets = (n + BUCKET - 1) / BUCKET;
    std::array<std::int64_t, MAX_N> d0{};
    std::array<std::int64_t, MAX_B> lengths{}, prefixes{};
    std::array<std::int64_t, MAX_Q> ranks{};
    for (std::size_t b = 0; b < buckets; ++b) {
        const auto start = b * BUCKET;
        const auto end = (start + BUCKET < n) ? start + BUCKET : n;
        const int plen = end - start == 1 ? 16 : lcp(keys[start], keys[end - 1]);
        const std::int64_t prefix = plen == 0 ? 0 : keys[start] >> (16 - plen);
        lengths[b] = plen; prefixes[b] = prefix;
        for (std::size_t i = start; i < end; ++i) d0[i] = plen;
    }
    for (std::size_t i = 0; i < q; ++i) {
        std::size_t pos = 0;
        while (keys[pos] != queries[i]) ++pos;
        const auto plen = d0[pos];
        const std::int64_t prefix = plen == 0 ? 0 : queries[i] >> (16 - plen);
        std::size_t b = 0;
        while (b < buckets && (lengths[b] != plen || prefixes[b] != prefix)) ++b;
        if (b == buckets) return -1;
        ranks[i] = static_cast<std::int64_t>(b * BUCKET + pos - b * BUCKET);
    }
    const std::size_t words = 3 + n + 3 * buckets + q;
    if (output == nullptr || capacity < words * 8) return -2;
    std::array<std::int64_t, MAX_WORDS> staged{};
    std::size_t k = 0;
    staged[k++] = static_cast<std::int64_t>(n); staged[k++] = static_cast<std::int64_t>(buckets); staged[k++] = static_cast<std::int64_t>(q);
    for (std::size_t i = 0; i < n; ++i) staged[k++] = d0[i];
    for (std::size_t b = 0; b < buckets; ++b) { staged[k++] = lengths[b]; staged[k++] = prefixes[b]; staged[k++] = static_cast<std::int64_t>(b); }
    for (std::size_t i = 0; i < q; ++i) staged[k++] = ranks[i];
    for (std::size_t i = 0; i < words; ++i) put_i64(output, i * 8, staged[i]);
    return static_cast<std::int64_t>(words * 8);
}
