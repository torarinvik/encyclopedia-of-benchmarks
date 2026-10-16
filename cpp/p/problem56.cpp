#include <cstdint>
namespace {
int multiply_digits(int* digits, int length, int factor) noexcept {
    int carry = 0;
    for (int i = 0; i < length; ++i) { const int value = digits[i] * factor + carry; digits[i] = value % 10; carry = value / 10; }
    while (carry > 0) { digits[length++] = carry % 10; carry /= 10; }
    return length;
}
}
extern "C" std::int64_t problem56(std::int64_t a, std::int64_t b) noexcept {
    if (a < 1 || a > 200 || b < 1 || b > 200) return -1;
    std::int64_t best = 0;
    for (int base = 0; base < a; ++base) {
        int digits[512] = {1}; int length = 1;
        for (int power = 0; power < b; ++power) {
            std::int64_t sum = 0; for (int i = 0; i < length; ++i) sum += digits[i];
            if (sum > best) best = sum;
            if (power + 1 < b) length = multiply_digits(digits, length, base);
        }
    }
    return best;
}
