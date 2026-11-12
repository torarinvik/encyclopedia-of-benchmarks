#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_order = 8;
constexpr std::int64_t modulus = 998244353;
using Poly = std::array<std::int64_t, 2 * max_order + 1>;

void convolve(const std::int64_t* left, int left_len, const std::int64_t* right,
        int right_len, Poly& product) {
    product.fill(0);
    for (int i = 0; i < left_len; ++i)
        for (int j = 0; j < right_len; ++j)
            product[i + j] = (product[i + j] + left[i] * right[j]) % modulus;
}
}

extern "C" std::int64_t bostan_mori_recurrence_term(const std::int64_t* input,
        std::size_t length) noexcept {
    if (!input || length < 2) return -1;
    const auto order_word = input[0], index_word = input[1];
    if (order_word < 1 || order_word > max_order || index_word < 0
            || index_word > INT64_C(1000000000000000000)) return -1;
    const int order = static_cast<int>(order_word);
    if (length != static_cast<std::size_t>(2 + 2 * order)) return -1;

    std::array<std::int64_t, max_order> recurrence{}, initial{}, numerator{};
    std::array<std::int64_t, max_order + 1> denominator{};
    denominator[0] = 1;
    for (int i = 0; i < order; ++i) {
        recurrence[i] = input[2 + i];
        initial[i] = input[2 + order + i];
        if (recurrence[i] < 0 || recurrence[i] >= modulus
                || initial[i] < 0 || initial[i] >= modulus) return -1;
        denominator[i + 1] = recurrence[i] == 0 ? 0 : modulus - recurrence[i];
    }

    Poly product{};
    convolve(initial.data(), order, denominator.data(), order + 1, product);
    for (int i = 0; i < order; ++i) numerator[i] = product[i];
    auto index = static_cast<std::uint64_t>(index_word);
    while (index > 0) {
        std::array<std::int64_t, max_order + 1> denominator_negative{};
        Poly numerator_product{}, denominator_product{};
        for (int i = 0; i <= order; ++i)
            denominator_negative[i] = (i % 2 == 0 || denominator[i] == 0)
                    ? denominator[i] : modulus - denominator[i];
        convolve(numerator.data(), order, denominator_negative.data(), order + 1, numerator_product);
        convolve(denominator.data(), order + 1, denominator_negative.data(), order + 1, denominator_product);
        const int parity = static_cast<int>(index & 1U);
        for (int i = 0; i < order; ++i) numerator[i] = numerator_product[2 * i + parity];
        for (int i = 0; i <= order; ++i) denominator[i] = denominator_product[2 * i];
        index >>= 1U;
    }
    return numerator[0];
}
