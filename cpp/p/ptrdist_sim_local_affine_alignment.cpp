// Clean-room port of SIM's documented first-best local affine score.
#include <cstddef>
#include <cstdint>

extern "C" int64_t ptrdist_sim_local_affine_alignment(const int64_t *input, size_t length)
{
    constexpr size_t max_sequence = 64, stride = 65, cells = stride * stride;
    if (!input || length < 4 || length > 130 || input[0] < 1 || input[0] > 64) return -1;
    const size_t left = static_cast<size_t>(input[0]), right_pos = 1 + left;
    if (right_pos >= length || input[right_pos] < 1 || input[right_pos] > 64) return -1;
    const size_t right = static_cast<size_t>(input[right_pos]);
    if (length != right_pos + 1 + right) return -1;
    auto dna = [](int64_t c) { return c == 65 || c == 67 || c == 71 || c == 84; };
    for (size_t i = 0; i < left; ++i) if (!dna(input[1 + i])) return -1;
    for (size_t j = 0; j < right; ++j) if (!dna(input[right_pos + 1 + j])) return -1;
    int64_t h[cells]{}, d[cells]{}, f[cells]{};
    for (size_t j = 1; j <= right; ++j) d[j] = -60;
    for (size_t i = 1; i <= left; ++i) f[i * stride] = -60;
    int64_t best = 0;
    for (size_t i = 1; i <= left; ++i) for (size_t j = 1; j <= right; ++j) {
        const size_t p = i * stride + j;
        const int64_t do_ = h[p-stride] - 62, de = d[p-stride] - 2;
        d[p] = do_ > de ? do_ : de;
        const int64_t fo = h[p-1] - 62, fe = f[p-1] - 2;
        f[p] = fo > fe ? fo : fe;
        int64_t score = h[p-stride-1] + (input[i] == input[right_pos+j] ? 10 : -10);
        if (score < 0) score = 0;
        if (d[p] > score) score = d[p];
        if (f[p] > score) score = f[p];
        h[p] = score;
        if (score > best) best = score;
    }
    return best;
}
