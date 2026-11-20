// Uncompiled multiword bit-vector global edit-distance draft.
#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t myers_bitvector_edit_distance(const std::int64_t* input, std::size_t length) {
    if (!input || length < 2 || length > 515) return -1;
    const auto nr = input[0], mr = input[1];
    if (nr < 0 || nr > 256 || mr < 0 || mr > 256 ||
        length != static_cast<std::size_t>(2+nr+mr)) return -1;
    const auto n = static_cast<std::size_t>(nr), m = static_cast<std::size_t>(mr);
    for (std::size_t i = 2; i < length; ++i)
        if (input[i] < 0 || input[i] > 255) return -1;
    if (!n) return static_cast<std::int64_t>(m);
    std::array<std::array<std::uint64_t,4>,256> masks{};
    std::array<std::uint64_t,4> pv{}, mv{};
    const auto words = (n+63)/64;
    for (std::size_t i = 0; i < words; ++i) pv[i] = UINT64_MAX;
    for (std::size_t i = 0; i < n; ++i)
        masks[static_cast<std::size_t>(input[2+i])][i/64] |= UINT64_C(1) << (i%64);
    std::int64_t score = nr;
    const auto top = UINT64_C(1) << ((n-1)%64);
    for (std::size_t i = 0; i < m; ++i) {
        const auto symbol = static_cast<std::size_t>(input[2+n+i]);
        std::uint64_t add_carry = 0, ph_carry = 1, mh_carry = 0;
        for (std::size_t j = 0; j < words; ++j) {
            const auto eq = masks[symbol][j], p = pv[j], v = mv[j];
            const auto term = eq & p, first = term+p, sum = first+add_carry;
            add_carry = (first < term) | (sum < first);
            const auto xh = (sum ^ p) | eq, xv = eq | v;
            auto ph = v | ~(xh | p), mh = p & xh;
            if (j == words-1) {
                if (ph & top) ++score;
                if (mh & top) --score;
            }
            const auto next_ph = ph >> 63, next_mh = mh >> 63;
            ph = (ph << 1) | ph_carry;
            mh = (mh << 1) | mh_carry;
            ph_carry = next_ph; mh_carry = next_mh;
            pv[j] = mh | ~(xv | ph);
            mv[j] = ph & xv;
        }
    }
    return score;
}
