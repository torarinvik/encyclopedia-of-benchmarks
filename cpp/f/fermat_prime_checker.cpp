#include <cstdint>

namespace {
int32_t dotnet_sample(int32_t seed[56], int32_t& next, int32_t& next_p) {
    if (++next >= 56) next = 1;
    if (++next_p >= 56) next_p = 1;
    int32_t value = seed[next] - seed[next_p];
    if (value == 2147483647) --value;
    if (value < 0) value += 2147483647;
    seed[next] = value;
    return value;
}
int64_t mod_pow(int64_t base, int64_t exponent, int64_t modulus) {
    int64_t result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}
}

extern "C" int64_t fermat_prime_checker(int64_t number, int64_t times_to_check) {
    if (number < 2 || number > 1000000 || times_to_check < 2 || times_to_check > 64) return -1;
    int32_t seed[56] = {};
    int32_t mj = 161803398, mk = 1;
    seed[55] = mj;
    for (int32_t i = 1; i < 55; ++i) {
        int32_t index = (21 * i) % 55;
        seed[index] = mk;
        mk = mj - mk;
        if (mk < 0) mk += 2147483647;
        mj = seed[index];
    }
    for (int32_t pass = 0; pass < 4; ++pass)
        for (int32_t i = 1; i < 56; ++i) {
            seed[i] -= seed[1 + (i + 30) % 55];
            if (seed[i] < 0) seed[i] += 2147483647;
        }
    int32_t next = 0, next_p = 21;
    for (int64_t iteration = 1; iteration < times_to_check; ++iteration) {
        int32_t sample = dotnet_sample(seed, next, next_p);
        int64_t base = static_cast<int64_t>(static_cast<double>(sample) / 2147483647.0 * static_cast<double>(number - 1)) + 1;
        if (mod_pow(base, number - 1, number) != 1) return 0;
    }
    return 1;
}
