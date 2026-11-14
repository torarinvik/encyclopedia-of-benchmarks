// Uncompiled characteristic-two quadratic normal-form draft.
#include <array>
#include <bitset>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
using Vec = std::bitset<100>;
using Rows = std::array<Vec, 100>;

unsigned evaluate(const Rows& upper, std::size_t n, const Vec& x) {
    unsigned result = 0;
    for (std::size_t i = 0; i < n; ++i)
        if (x[i]) result ^= static_cast<unsigned>((upper[i] & x).count() & 1u);
    return result;
}
unsigned polar(const Rows& matrix, std::size_t n, const Vec& x, const Vec& y) {
    unsigned result = 0;
    for (std::size_t i = 0; i < n; ++i)
        if (x[i]) result ^= static_cast<unsigned>((matrix[i] & y).count() & 1u);
    return result;
}
}

extern "C" std::int64_t quadratic_form_gf2_normal_form(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) noexcept {
    if (!input || length == 0 || length > 202 || input[0] < 1 || input[0] > 100) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto words = (n + 62) / 63;
    if (length != 1 + n * words) return -1;
    Rows upper{}, bilinear{};
    for (std::size_t i = 0; i < n; ++i) {
        for (std::size_t chunk = 0; chunk < words; ++chunk) {
            const auto raw = input[1 + i * words + chunk];
            if (raw < 0) return -1;
            for (std::size_t bit = 0; bit < 63; ++bit) {
                if (((static_cast<std::uint64_t>(raw) >> bit) & 1u) == 0) continue;
                const auto j = 63 * chunk + bit;
                if (j >= n || j < i) return -1;
                upper[i].set(j);
                if (i != j) { bilinear[i].set(j); bilinear[j].set(i); }
            }
        }
    }
    const auto row_bytes = (n + 7) / 8;
    const auto needed = 3 + n * row_bytes;
    if (!output || capacity < needed) return -2;

    Rows remaining{}, scratch{}, hyper{}, anis{}, columns{};
    std::size_t count = n, hc = 0, ac = 0;
    for (std::size_t i = 0; i < n; ++i) remaining[i].set(i);
    for (;;) {
        std::size_t left = count, right = count;
        for (std::size_t i = 0; i < count && left == count; ++i)
            for (std::size_t j = i + 1; j < count; ++j)
                if (polar(bilinear, n, remaining[i], remaining[j])) {
                    left = i; right = j; break;
                }
        if (left == count) break;
        Vec u = remaining[left], v = remaining[right];
        std::size_t next = 0;
        for (std::size_t i = 0; i < count; ++i) {
            if (i == left || i == right) continue;
            Vec w = remaining[i];
            if (polar(bilinear, n, remaining[i], v)) w ^= u;
            if (polar(bilinear, n, remaining[i], u)) w ^= v;
            scratch[next++] = w;
        }
        for (std::size_t i = 0; i < next; ++i) remaining[i] = scratch[i];
        count = next;
        const auto qu = evaluate(upper, n, u), qv = evaluate(upper, n, v);
        if (qu && qv) { anis[ac++] = u; anis[ac++] = v; }
        else {
            if (qu) u ^= v; else if (qv) v ^= u;
            hyper[hc++] = u; hyper[hc++] = v;
        }
    }
    while (ac >= 4) {
        Vec b = anis[--ac], a = anis[--ac], d = anis[--ac], c = anis[--ac];
        hyper[hc++] = a ^ c; hyper[hc++] = b ^ c;
        Vec f = d ^ a ^ b;
        hyper[hc++] = f; hyper[hc++] = f ^ c;
    }
    Vec linear{};
    bool has_linear = false;
    for (std::size_t i = 0; i < count; ++i) {
        if (!evaluate(upper, n, remaining[i])) continue;
        linear = remaining[i]; has_linear = true;
        for (std::size_t j = i + 1; j < count; ++j) remaining[j - 1] = remaining[j];
        --count; break;
    }
    if (has_linear) {
        for (std::size_t i = 0; i < count; ++i)
            if (evaluate(upper, n, remaining[i])) remaining[i] ^= linear;
        if (ac) {
            hyper[hc++] = anis[0] ^ linear; hyper[hc++] = anis[1] ^ linear;
            ac = 0;
        }
    }
    std::size_t used = 0;
    for (std::size_t i = 0; i < hc; ++i) columns[used++] = hyper[i];
    for (std::size_t i = 0; i < ac; ++i) columns[used++] = anis[i];
    if (has_linear) columns[used++] = linear;
    for (std::size_t i = 0; i < count; ++i) columns[used++] = remaining[i];
    if (used != n || (hc & 1u) || (ac != 0 && ac != 2)) return -4;

    Rows matrix{}, inverse{};
    for (std::size_t i = 0; i < n; ++i) {
        inverse[i].set(i);
        for (std::size_t j = 0; j < n; ++j) if (columns[j][i]) matrix[i].set(j);
    }
    for (std::size_t col = 0; col < n; ++col) {
        std::size_t pivot = col;
        while (pivot < n && !matrix[pivot][col]) ++pivot;
        if (pivot == n) return -4;
        auto row = matrix[col]; matrix[col] = matrix[pivot]; matrix[pivot] = row;
        row = inverse[col]; inverse[col] = inverse[pivot]; inverse[pivot] = row;
        for (std::size_t i = 0; i < n; ++i) if (i != col && matrix[i][col]) {
            matrix[i] ^= matrix[col]; inverse[i] ^= inverse[col];
        }
    }
    std::array<std::uint8_t, 1303> staged{};
    staged[0] = static_cast<std::uint8_t>(hc / 2);
    staged[1] = static_cast<std::uint8_t>(ac / 2);
    staged[2] = static_cast<std::uint8_t>(has_linear);
    for (std::size_t i = 0; i < n; ++i)
        for (std::size_t j = 0; j < n; ++j)
            if (inverse[i][j]) staged[3 + i * row_bytes + j / 8] |= static_cast<std::uint8_t>(1u << (j % 8));
    std::memcpy(output, staged.data(), needed);
    return static_cast<std::int64_t>(needed);
}
