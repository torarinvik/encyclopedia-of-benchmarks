#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t base = 1'000'000'000;
constexpr std::size_t max_limbs = 8;
using Limbs = std::array<std::int64_t, max_limbs>;

std::size_t trim(const Limbs& x, std::size_t n) {
    while (n > 0 && x[n - 1] == 0) --n;
    return n;
}

std::size_t parse(const std::int64_t* text, std::size_t length, Limbs& x) {
    std::size_t n = 0;
    for (std::size_t k = 0; k < length; ++k) {
        std::int64_t carry = text[k] - 48;
        for (std::size_t i = 0; i < n; ++i) {
            carry += x[i] * 10;
            x[i] = carry % base;
            carry /= base;
        }
        if (carry != 0) x[n++] = carry;
        if (n == 0) n = 1;
    }
    return trim(x, n);
}

int compare(const Limbs& a, std::size_t na, const Limbs& b, std::size_t nb) {
    if (na != nb) return na > nb ? 1 : -1;
    while (na > 0) { --na; if (a[na] != b[na]) return a[na] > b[na] ? 1 : -1; }
    return 0;
}

void divide(const Limbs& a, std::size_t na, const Limbs& b, std::size_t nb,
            Limbs& q, std::size_t& nq, Limbs& r, std::size_t& nr) {
    nq = nr = 0;
    if (na == 0) return;
    if (compare(a, na, b, nb) < 0) { r = a; nr = na; return; }
    if (nb == 1) {
        std::int64_t rem = 0;
        for (std::size_t i = na; i > 0; --i) {
            const auto cur = rem * base + a[i - 1]; q[i - 1] = cur / b[0]; rem = cur % b[0];
        }
        nq = trim(q, na); if (rem != 0) { r[0] = rem; nr = 1; } return;
    }
    std::array<std::int64_t, max_limbs> v{};
    std::array<std::int64_t, max_limbs + 1> u{};
    const auto scale = base / (b[nb - 1] + 1);
    std::int64_t carry = 0;
    for (std::size_t i = 0; i < nb; ++i) { const auto cur = b[i] * scale + carry; v[i] = cur % base; carry = cur / base; }
    carry = 0;
    for (std::size_t i = 0; i < na; ++i) { const auto cur = a[i] * scale + carry; u[i] = cur % base; carry = cur / base; }
    u[na] = carry;
    const std::size_t width = na - nb + 1;
    for (std::size_t step = width; step > 0; --step) {
        const auto j = step - 1;
        const auto numerator = u[j + nb] * base + u[j + nb - 1];
        auto estimate = numerator / v[nb - 1];
        auto rem_estimate = numerator % v[nb - 1];
        if (estimate >= base) { estimate = base - 1; rem_estimate = numerator - estimate * v[nb - 1]; }
        while (rem_estimate < base && estimate * v[nb - 2] > rem_estimate * base + u[j + nb - 2]) {
            --estimate; rem_estimate += v[nb - 1];
        }
        std::int64_t borrow = 0;
        for (std::size_t i = 0; i < nb; ++i) {
            const auto product = estimate * v[i] + borrow;
            const auto low = product % base; borrow = product / base;
            auto diff = u[j + i] - low;
            if (diff < 0) { diff += base; ++borrow; }
            u[j + i] = diff;
        }
        const auto top = u[j + nb] - borrow;
        if (top < 0) {
            --estimate; carry = 0;
            for (std::size_t i = 0; i < nb; ++i) {
                auto sum = u[j + i] + v[i] + carry;
                if (sum >= base) { sum -= base; carry = 1; } else carry = 0;
                u[j + i] = sum;
            }
            u[j + nb] = top + carry;
        } else u[j + nb] = top;
        q[j] = estimate;
    }
    nq = trim(q, width); carry = 0;
    for (std::size_t i = nb; i > 0; --i) { const auto cur = carry * base + u[i - 1]; r[i - 1] = cur / scale; carry = cur % scale; }
    nr = trim(r, nb);
}

std::size_t emit(const Limbs& x, std::size_t n, std::uint8_t* out, std::size_t at) {
    n = trim(x, n);
    if (n == 0) { out[at++] = 48; return at; }
    auto value = x[n - 1], power = std::int64_t(1);
    while (value / power >= 10) power *= 10;
    while (power > 0) { out[at++] = std::uint8_t(48 + value / power % 10); power /= 10; }
    while (--n > 0) { value = x[n - 1]; power = base / 10; while (power > 0) { out[at++] = std::uint8_t(48 + value / power % 10); power /= 10; } }
    return at;
}
}

extern "C" std::int64_t knuth_big_integer_division(const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 4 || length > 130 || input[0] < 1 || input[0] > 64 || input[1] < 1 || input[1] > 64) return -1;
    const auto na_text = std::size_t(input[0]), nb_text = std::size_t(input[1]);
    if (length != 2 + na_text + nb_text) return -1;
    const auto* a_text = input + 2; const auto* b_text = input + 2 + na_text;
    for (std::size_t i = 0; i < na_text; ++i) if (a_text[i] < 48 || a_text[i] > 57) return -1;
    for (std::size_t i = 0; i < nb_text; ++i) if (b_text[i] < 48 || b_text[i] > 57) return -1;
    if ((na_text > 1 && a_text[0] == 48) || (nb_text > 1 && b_text[0] == 48) || (nb_text == 1 && b_text[0] == 48)) return -1;
    Limbs a{}, b{}, q{}, r{};
    const auto na = parse(a_text, na_text, a), nb = parse(b_text, nb_text, b);
    std::size_t nq = 0, nr = 0; divide(a, na, b, nb, q, nq, r, nr);
    std::array<std::uint8_t, 129> result{};
    auto bytes = emit(q, nq, result.data(), 0); result[bytes++] = 58; bytes = emit(r, nr, result.data(), bytes);
    if (output == nullptr || capacity < bytes) return -2;
    for (std::size_t i = 0; i < bytes; ++i) output[i] = result[i];
    return std::int64_t(bytes);
}
