#include <array>
#include <cstdint>

namespace {
constexpr std::int64_t MaxInput = 100'000'000;
constexpr std::size_t SieveLimit = 10'000;
constexpr std::size_t MaxPrimes = 1'300;
constexpr std::size_t PhiCacheX = 2'048;
constexpr std::size_t PhiCacheS = 32;

struct Context {
    std::array<std::uint8_t, SieveLimit + 1> composite{};
    std::array<std::int32_t, MaxPrimes> primes{};
    std::array<std::int32_t, SieveLimit + 1> prime_count_prefix{};
    std::array<std::array<std::int32_t, PhiCacheX + 1>, PhiCacheS + 1> phi_cache{};
};

std::uint64_t integer_sqrt(std::uint64_t value) noexcept {
    std::uint64_t low = 0;
    std::uint64_t high = value + 1;
    while (low + 1 < high) {
        const auto middle = low + (high - low) / 2;
        if (middle <= value / middle) low = middle;
        else high = middle;
    }
    return low;
}

std::uint64_t integer_cuberoot(std::uint64_t value) noexcept {
    std::uint64_t low = 0;
    std::uint64_t high = value + 1;
    while (low + 1 < high) {
        const auto middle = low + (high - low) / 2;
        if (middle <= value / middle / middle) low = middle;
        else high = middle;
    }
    return low;
}

std::int64_t phi(Context& context, std::uint64_t value, std::uint32_t prime_count) {
    if (value == 0) return 0;
    if (prime_count == 0) return static_cast<std::int64_t>(value);
    if (prime_count == 1) return static_cast<std::int64_t>(value - value / 2);
    if (value < static_cast<std::uint64_t>(context.primes[prime_count - 1])) return 1;
    if (value <= PhiCacheX && prime_count <= PhiCacheS) {
        auto& cached = context.phi_cache[prime_count][value];
        if (cached != 0) return cached;
        const auto result = phi(context, value, prime_count - 1) -
            phi(context, value / static_cast<std::uint64_t>(context.primes[prime_count - 1]), prime_count - 1);
        cached = static_cast<std::int32_t>(result);
        return result;
    }
    return phi(context, value, prime_count - 1) -
        phi(context, value / static_cast<std::uint64_t>(context.primes[prime_count - 1]), prime_count - 1);
}

std::int64_t lehmer_count(Context& context, std::uint64_t value) {
    if (value <= SieveLimit) return context.prime_count_prefix[value];
    const auto a = static_cast<std::uint32_t>(context.prime_count_prefix[integer_sqrt(integer_sqrt(value))]);
    const auto b = static_cast<std::uint32_t>(context.prime_count_prefix[integer_sqrt(value)]);
    const auto c = static_cast<std::uint32_t>(context.prime_count_prefix[integer_cuberoot(value)]);
    auto result = phi(context, value, a) +
        static_cast<std::int64_t>(b + a - 2) * static_cast<std::int64_t>(b - a + 1) / 2;
    for (std::uint32_t i = a; i < b; ++i) {
        const auto quotient = value / static_cast<std::uint64_t>(context.primes[i]);
        result -= lehmer_count(context, quotient);
        if (i < c) {
            const auto limit = static_cast<std::uint32_t>(lehmer_count(context, integer_sqrt(quotient)));
            for (std::uint32_t j = i; j < limit; ++j)
                result -= lehmer_count(context, quotient / static_cast<std::uint64_t>(context.primes[j])) - j;
        }
    }
    return result;
}
} // namespace

extern "C" std::int64_t meissel_lehmer_prime_count(std::int64_t value) noexcept {
    if (value < 0 || value > MaxInput) return -1;
    Context context{};
    for (std::size_t candidate = 2; candidate * candidate <= SieveLimit; ++candidate) {
        if (context.composite[candidate] != 0) continue;
        for (std::size_t multiple = candidate * candidate; multiple <= SieveLimit; multiple += candidate)
            context.composite[multiple] = 1;
    }
    std::size_t prime_count = 0;
    for (std::size_t candidate = 2; candidate <= SieveLimit; ++candidate) {
        if (context.composite[candidate] == 0) context.primes[prime_count++] = static_cast<std::int32_t>(candidate);
        context.prime_count_prefix[candidate] = context.prime_count_prefix[candidate - 1] +
            static_cast<std::int32_t>(context.composite[candidate] == 0);
    }
    return lehmer_count(context, static_cast<std::uint64_t>(value));
}
