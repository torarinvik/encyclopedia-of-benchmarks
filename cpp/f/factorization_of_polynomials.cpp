#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr int max_n = 8;
constexpr int max_poly = max_n + 1;
constexpr int max_factors = max_n;
constexpr int max_output_bytes = 216;
using Polynomial = std::array<int64_t, max_poly>;
using Factors = std::array<Polynomial, max_factors>;

void store_le(uint8_t* output, std::size_t offset, int64_t value) {
    uint64_t bits = static_cast<uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<uint8_t>(bits & 255U);
        bits >>= 8;
    }
}

int power_small(int base, int exponent) {
    int value = 1;
    for (int i = 0; i < exponent; ++i) value *= base;
    return value;
}

void monic_from_code(Polynomial& polynomial, int degree, int code, int prime) {
    polynomial.fill(0);
    for (int i = 0; i < degree; ++i) {
        polynomial[static_cast<std::size_t>(i)] = code % prime;
        code /= prime;
    }
    polynomial[static_cast<std::size_t>(degree)] = 1;
}

bool exact_quotient(const Polynomial& polynomial, int degree,
                    const Polynomial& divisor, int divisor_degree,
                    int prime, Polynomial& quotient) {
    if (degree < divisor_degree) return false;
    Polynomial remainder = polynomial;
    quotient.fill(0);
    const int quotient_degree = degree - divisor_degree;
    for (int shift = quotient_degree; shift >= 0; --shift) {
        const int64_t factor = remainder[static_cast<std::size_t>(shift + divisor_degree)];
        quotient[static_cast<std::size_t>(shift)] = factor;
        for (int j = 0; j <= divisor_degree; ++j) {
            int64_t value = remainder[static_cast<std::size_t>(shift + j)] -
                factor * divisor[static_cast<std::size_t>(j)];
            value %= prime;
            if (value < 0) value += prime;
            remainder[static_cast<std::size_t>(shift + j)] = value;
        }
    }
    for (int i = 0; i < divisor_degree; ++i)
        if (remainder[static_cast<std::size_t>(i)] != 0) return false;
    return true;
}

bool irreducible(const Polynomial& candidate, int degree, int prime) {
    for (int divisor_degree = 1; divisor_degree <= degree / 2; ++divisor_degree) {
        const int limit = power_small(prime, divisor_degree);
        for (int code = 0; code < limit; ++code) {
            Polynomial divisor{};
            Polynomial quotient{};
            monic_from_code(divisor, divisor_degree, code, prime);
            if (exact_quotient(candidate, degree, divisor, divisor_degree,
                               prime, quotient)) return false;
        }
    }
    return true;
}

bool after(const Polynomial& left, int left_degree,
           const Polynomial& right, int right_degree) {
    if (left_degree != right_degree) return left_degree > right_degree;
    for (int i = 0; i <= left_degree; ++i) {
        const auto a = left[static_cast<std::size_t>(i)];
        const auto b = right[static_cast<std::size_t>(i)];
        if (a != b) return a > b;
    }
    return false;
}
}

extern "C" int64_t factorization_of_polynomials(const int64_t* input,
                                                  std::size_t length,
                                                  uint8_t* output,
                                                  std::size_t capacity) {
    if (input == nullptr || length < 3 || length > 12) return -1;
    const int64_t degree_value = input[0];
    const int64_t prime_value = input[1];
    if (degree_value < 0 || degree_value > max_n ||
        (prime_value != 2 && prime_value != 3 && prime_value != 5) ||
        length != static_cast<std::size_t>(degree_value) + 3) return -1;
    const int degree = static_cast<int>(degree_value);
    const int prime = static_cast<int>(prime_value);
    if (input[degree + 2] != 1) return -1;
    for (int i = 0; i <= degree; ++i)
        if (input[i + 2] < 0 || input[i + 2] >= prime) return -1;

    Factors factors{};
    std::array<int, max_factors> degrees{};
    std::array<int64_t, max_factors> multiplicities{};
    Polynomial work{};
    for (int i = 0; i <= degree; ++i) work[static_cast<std::size_t>(i)] = input[i + 2];
    int work_degree = degree;
    int factor_count = 0;
    for (int candidate_degree = 1; candidate_degree <= degree / 2; ++candidate_degree) {
        const int limit = power_small(prime, candidate_degree);
        for (int code = 0; code < limit; ++code) {
            Polynomial candidate{};
            monic_from_code(candidate, candidate_degree, code, prime);
            if (!irreducible(candidate, candidate_degree, prime)) continue;
            Polynomial quotient{};
            int64_t multiplicity = 0;
            while (work_degree >= candidate_degree &&
                   exact_quotient(work, work_degree, candidate, candidate_degree,
                                  prime, quotient)) {
                ++multiplicity;
                work_degree -= candidate_degree;
                work = quotient;
            }
            if (multiplicity != 0) {
                factors[static_cast<std::size_t>(factor_count)] = candidate;
                degrees[static_cast<std::size_t>(factor_count)] = candidate_degree;
                multiplicities[static_cast<std::size_t>(factor_count)] = multiplicity;
                ++factor_count;
            }
        }
    }
    if (work_degree > 0) {
        factors[static_cast<std::size_t>(factor_count)] = work;
        degrees[static_cast<std::size_t>(factor_count)] = work_degree;
        multiplicities[static_cast<std::size_t>(factor_count)] = 1;
        ++factor_count;
    }
    for (int i = 0; i < factor_count; ++i) {
        for (int j = i + 1; j < factor_count; ++j) {
            if (after(factors[static_cast<std::size_t>(i)], degrees[static_cast<std::size_t>(i)],
                      factors[static_cast<std::size_t>(j)], degrees[static_cast<std::size_t>(j)])) {
                factors[static_cast<std::size_t>(i)].swap(factors[static_cast<std::size_t>(j)]);
                std::swap(degrees[static_cast<std::size_t>(i)], degrees[static_cast<std::size_t>(j)]);
                std::swap(multiplicities[static_cast<std::size_t>(i)], multiplicities[static_cast<std::size_t>(j)]);
            }
        }
    }

    std::size_t words = 1;
    for (int i = 0; i < factor_count; ++i) words += static_cast<std::size_t>(degrees[static_cast<std::size_t>(i)] + 3);
    const std::size_t bytes = words * 8;
    if (bytes > max_output_bytes) return -1;
    if (output == nullptr || capacity < bytes) return -2;
    std::size_t word = 0;
    store_le(output, 8 * word++, factor_count);
    for (int i = 0; i < factor_count; ++i) {
        const auto index = static_cast<std::size_t>(i);
        store_le(output, 8 * word++, multiplicities[index]);
        store_le(output, 8 * word++, degrees[index]);
        for (int j = 0; j <= degrees[index]; ++j)
            store_le(output, 8 * word++, factors[index][static_cast<std::size_t>(j)]);
    }
    return static_cast<int64_t>(bytes);
}
