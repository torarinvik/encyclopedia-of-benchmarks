/*
 * Clean-room bounded CFRAC profile based on the published
 * Morrison-Brillhart continued-fraction factorization method.
 * No code from the restricted arbitrary-precision package is included.
 */
#include <cstddef>
#include <cstdint>

namespace {
constexpr unsigned MAX_BASE = 10, MAX_ITERATIONS = 48, MAX_PRIME = 10000;

std::uint64_t gcd(std::uint64_t a, std::uint64_t b) {
    while (b != 0) { const auto r = a % b; a = b; b = r; }
    return a;
}

std::uint64_t modpow(std::uint64_t base, std::uint64_t exponent, std::uint64_t modulus) {
    std::uint64_t result = 1;
    base %= modulus;
    while (exponent != 0) {
        if (exponent & 1u) result = (result * base) % modulus;
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    return result;
}

bool is_prime(unsigned value) {
    if (value < 2) return false;
    for (unsigned divisor = 2; std::uint64_t(divisor) * divisor <= value; ++divisor)
        if (value % divisor == 0) return false;
    return true;
}

bool make_base(std::uint64_t n, unsigned requested, std::uint32_t *base) {
    unsigned count = 1;
    base[0] = 2;
    for (unsigned p = 3; p <= MAX_PRIME && count < requested; p += 2) {
        if (!is_prime(p)) continue;
        const auto residue = modpow(n % p, (p - 1) / 2, p);
        if (residue == 0) return false; // The source selects residue zero; this bounded domain rejects it.
        if (residue == 1) base[count++] = p;
    }
    return count == requested;
}

std::int64_t dependency_factor(std::uint64_t n, std::uint64_t selected, unsigned relation_count,
    const std::uint64_t *relation_a, const std::uint8_t *relation_exp,
    const std::uint32_t *base, unsigned base_count) {
    std::uint64_t x = 1, exponent_sum[MAX_BASE]{};
    for (unsigned i = 0; i < relation_count; ++i) {
        if ((selected & (std::uint64_t{1} << i)) == 0) continue;
        x = (x * relation_a[i]) % n;
        for (unsigned j = 0; j < base_count; ++j) exponent_sum[j] += relation_exp[i * MAX_BASE + j];
    }
    std::uint64_t y = 1;
    for (unsigned j = 0; j < base_count; ++j) y = (y * modpow(base[j], exponent_sum[j] / 2, n)) % n;
    const auto minus = gcd(x >= y ? x - y : y - x, n);
    if (minus > 1 && minus < n) return static_cast<std::int64_t>(minus);
    const auto plus = gcd(x + y, n);
    if (plus > 1 && plus < n) return static_cast<std::int64_t>(plus);
    return 0;
}
}

extern "C" std::int64_t mallocbench_cfrac(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length != 3) return -1;
    const auto n_value = input[0], base_value = input[1], iteration_value = input[2];
    if (n_value < 15 || n_value > 1000000 || (n_value & 1) == 0 ||
        base_value < 2 || base_value > MAX_BASE || iteration_value < 1 || iteration_value > MAX_ITERATIONS) return -1;
    const auto n = static_cast<std::uint64_t>(n_value);
    std::uint64_t root = 0;
    while (root + 1 <= n / (root + 1)) ++root;
    if (root * root == n) return -1;
    const auto base_count = static_cast<unsigned>(base_value);
    const auto iteration_limit = static_cast<unsigned>(iteration_value);
    std::uint32_t base[MAX_BASE]{};
    if (!make_base(n, base_count, base)) return -1;

    std::uint64_t basis_vector[MAX_BASE + 1]{}, basis_combo[MAX_BASE + 1]{};
    bool basis_used[MAX_BASE + 1]{};
    std::uint64_t relation_a[MAX_ITERATIONS]{};
    std::uint8_t relation_exp[MAX_ITERATIONS * MAX_BASE]{};
    unsigned relation_count = 0;
    std::int64_t u = static_cast<std::int64_t>(2 * root), previous_u = static_cast<std::int64_t>(2 * root);
    std::int64_t q_value = 0, q_denominator = 1, previous_denominator = static_cast<std::int64_t>(n - root * root);
    std::int64_t a_value = 1, previous_a = static_cast<std::int64_t>(root);
    unsigned sign = 0;

    for (unsigned iteration = 0; iteration < iteration_limit; ++iteration) {
        const auto old_a = a_value;
        a_value = (q_value * a_value + previous_a) % static_cast<std::int64_t>(n);
        previous_a = old_a;
        const auto old_denominator = q_denominator;
        q_denominator = q_value * (previous_u - u) + previous_denominator;
        previous_denominator = old_denominator;
        previous_u = u;
        if (q_denominator <= 0) return static_cast<std::int64_t>(n);
        q_value = 1;
        auto remainder = u - q_denominator;
        if (remainder >= q_denominator) {
            q_value = u / q_denominator;
            remainder = u % q_denominator;
        }
        u = static_cast<std::int64_t>(2 * root) - remainder;
        sign ^= 1u;
        if (q_denominator == 1) return static_cast<std::int64_t>(n);

        auto residual = static_cast<std::uint64_t>(q_denominator);
        std::uint8_t exponents[MAX_BASE]{};
        for (unsigned j = 0; j < base_count; ++j)
            while (residual % base[j] == 0) { residual /= base[j]; ++exponents[j]; }
        if (residual != 1) continue;
        relation_a[relation_count] = static_cast<std::uint64_t>(a_value);
        for (unsigned j = 0; j < base_count; ++j) relation_exp[relation_count * MAX_BASE + j] = exponents[j];
        std::uint64_t vector = sign;
        for (unsigned j = 0; j < base_count; ++j) if (exponents[j] & 1u) vector |= std::uint64_t{1} << (j + 1);
        auto combination = std::uint64_t{1} << relation_count;
        ++relation_count;
        bool inserted = false;
        for (unsigned bit = 0; bit <= base_count; ++bit) {
            if ((vector & (std::uint64_t{1} << bit)) == 0) continue;
            if (basis_used[bit]) { vector ^= basis_vector[bit]; combination ^= basis_combo[bit]; }
            else {
                basis_used[bit] = true;
                basis_vector[bit] = vector;
                basis_combo[bit] = combination;
                inserted = true;
                break;
            }
        }
        if (!inserted) {
            const auto factor = dependency_factor(n, combination, relation_count, relation_a, relation_exp, base, base_count);
            if (factor > 1) return factor;
        }
    }
    return static_cast<std::int64_t>(n);
}
