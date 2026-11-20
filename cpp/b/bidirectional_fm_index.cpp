#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxN = 64, MaxQ = 64, Total = 65;
bool suffix_less(const std::int64_t* s, std::size_t n, std::size_t a, std::size_t b) {
    while (a < n && b < n) { if (s[a] != s[b]) return s[a] < s[b]; ++a; ++b; }
    return a == n && b != n;
}
void build_index(const std::int64_t* s, std::size_t total, std::size_t* cumulative,
                 std::int64_t* bwt) {
    std::size_t suffixes[Total], frequency[5]{};
    for (std::size_t i = 0; i < total; ++i) suffixes[i] = i;
    for (std::size_t i = 1; i < total; ++i) {
        const auto key = suffixes[i]; auto j = i;
        while (j > 0 && suffix_less(s, total, key, suffixes[j - 1])) { suffixes[j] = suffixes[j - 1]; --j; }
        suffixes[j] = key;
    }
    for (std::size_t i = 0; i < total; ++i) { bwt[i] = s[(suffixes[i] + total - 1) % total]; ++frequency[static_cast<std::size_t>(bwt[i])]; }
    std::size_t seen = 0;
    for (std::size_t symbol = 0; symbol < 5; ++symbol) { cumulative[symbol] = seen; seen += frequency[symbol]; }
}
std::size_t rank_before(const std::int64_t* bwt, std::size_t end, std::size_t symbol) {
    std::size_t count = 0;
    for (std::size_t i = 0; i < end; ++i) if (static_cast<std::size_t>(bwt[i]) == symbol) ++count;
    return count;
}
}

extern "C" std::int64_t bidirectional_fm_index(const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > 195) return -1;
    const auto n0 = input[0], q0 = input[1];
    if (n0 < 0 || n0 > static_cast<std::int64_t>(MaxN) || q0 < 0 || q0 > static_cast<std::int64_t>(MaxQ)) return -1;
    const auto n = static_cast<std::size_t>(n0), q = static_cast<std::size_t>(q0);
    if (length != 2 + n + 2 * q) return -1;
    std::int64_t forward_text[Total]{}, reverse_text[Total]{};
    for (std::size_t i = 0; i < n; ++i) {
        const auto symbol = input[2 + i];
        if (symbol < 1 || symbol > 4) return -1;
        forward_text[i] = symbol; reverse_text[n - 1 - i] = symbol;
    }
    forward_text[n] = 0; reverse_text[n] = 0;
    for (std::size_t i = 0; i < q; ++i) {
        const auto side = input[2 + n + 2 * i], symbol = input[3 + n + 2 * i];
        if ((side != 0 && side != 1) || symbol < 1 || symbol > 4) return -1;
    }
    const auto total = n + 1;
    std::size_t forward_c[5], reverse_c[5];
    std::int64_t forward_bwt[Total]{}, reverse_bwt[Total]{};
    build_index(forward_text, total, forward_c, forward_bwt);
    build_index(reverse_text, total, reverse_c, reverse_bwt);
    std::size_t fl = 0, fr = total, rl = 0, rr = total;
    std::int64_t checksum = 0;
    for (std::size_t op = 0; op < q; ++op) {
        const auto side = static_cast<std::size_t>(input[2 + n + 2 * op]);
        const auto symbol = static_cast<std::size_t>(input[3 + n + 2 * op]);
        const auto old_fl = fl, old_fr = fr, old_rl = rl, old_rr = rr;
        if (side == 0) {
            fl = forward_c[symbol] + rank_before(forward_bwt, old_fl, symbol);
            fr = forward_c[symbol] + rank_before(forward_bwt, old_fr, symbol);
            auto start = old_rl;
            for (std::size_t smaller = 0; smaller < symbol; ++smaller) start += rank_before(forward_bwt, old_fr, smaller) - rank_before(forward_bwt, old_fl, smaller);
            const auto count = rank_before(forward_bwt, old_fr, symbol) - rank_before(forward_bwt, old_fl, symbol); rl = start; rr = start + count;
        } else {
            rl = reverse_c[symbol] + rank_before(reverse_bwt, old_rl, symbol);
            rr = reverse_c[symbol] + rank_before(reverse_bwt, old_rr, symbol);
            auto start = old_fl;
            for (std::size_t smaller = 0; smaller < symbol; ++smaller) start += rank_before(reverse_bwt, old_rr, smaller) - rank_before(reverse_bwt, old_rl, smaller);
            const auto count = rank_before(reverse_bwt, old_rr, symbol) - rank_before(reverse_bwt, old_rl, symbol); fl = start; fr = start + count;
        }
        checksum += static_cast<std::int64_t>(op + 1) * static_cast<std::int64_t>(fr - fl);
    }
    return checksum;
}
