/* Direct permutation port of TheAlgorithms/Python Project Euler 43. */
#include <algorithm>
#include <array>
#include <cstdint>

extern "C" std::int64_t problem43(std::int64_t n) noexcept {
    if (n != 10) return -1;
    std::array<int, 10> digits{0,1,2,3,4,5,6,7,8,9};
    constexpr int divisors[4] = {7,11,13,17};
    std::int64_t total = 0;
    do {
        if (digits[3] % 2 || (digits[2]+digits[3]+digits[4]) % 3 || digits[5] % 5) continue;
        bool valid = true;
        for (int i=0; i<4; ++i) if ((digits[i+4]*100+digits[i+5]*10+digits[i+6]) % divisors[i]) valid=false;
        if (valid) { std::int64_t value=0; for (int digit: digits) value=value*10+digit; total+=value; }
    } while (std::next_permutation(digits.begin(), digits.end()));
    return total;
}
