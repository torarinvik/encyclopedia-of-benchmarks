#include <array>
#include <cstdint>

namespace {
constexpr std::size_t LIMBS = 16;
constexpr std::uint64_t BASE = 1'000'000'000;
using Big = std::array<std::uint64_t, LIMBS>;
void mul_add(const Big& src, std::uint64_t factor, std::uint64_t add, Big& dst) {
    std::uint64_t carry = add;
    for (std::size_t i = 0; i < LIMBS; ++i) {
        const auto value = src[i] * factor + carry;
        dst[i] = value % BASE; carry = value / BASE;
    }
}
bool ge(const Big& left, const Big& right) {
    for (std::size_t i = LIMBS; i-- > 0;) if (left[i] != right[i]) return left[i] > right[i];
    return true;
}
void subtract(Big& left, const Big& right) {
    std::uint64_t borrow = 0;
    for (std::size_t i = 0; i < LIMBS; ++i) {
        const auto amount = right[i] + borrow;
        if (left[i] < amount) { left[i] = left[i] + BASE - amount; borrow = 1; }
        else { left[i] -= amount; borrow = 0; }
    }
}
}

extern "C" std::int64_t problem80(std::int64_t placeholder) noexcept {
    if (placeholder != 0) return -1;
    std::int64_t answer = 0;
    for (std::uint64_t number = 2; number < 100; ++number) {
        std::uint64_t integer_root = 0;
        while ((integer_root + 1) * (integer_root + 1) <= number) ++integer_root;
        if (integer_root * integer_root == number) continue;
        Big root{}, remainder{}, scaled{}, trial{};
        std::int64_t digit_sum = 0;
        for (int step = 0; step < 100; ++step) {
            mul_add(remainder, 100, step == 0 ? number : 0, remainder);
            int digit = 9;
            for (; digit >= 0; --digit) {
                mul_add(root, 20, static_cast<std::uint64_t>(digit), scaled);
                mul_add(scaled, static_cast<std::uint64_t>(digit), 0, trial);
                if (ge(remainder, trial)) break;
            }
            subtract(remainder, trial);
            mul_add(root, 10, static_cast<std::uint64_t>(digit), root);
            digit_sum += digit;
        }
        answer += digit_sum;
    }
    return answer;
}
