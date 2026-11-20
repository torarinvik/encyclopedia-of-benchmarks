#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxDegree = 8;
constexpr std::size_t kMaxIterations = 4;
constexpr std::size_t kMaxInputLength = 14;
constexpr std::int64_t kModulus = 998244353;

std::int64_t normalize(std::int64_t value) {
    value %= kModulus;
    return value < 0 ? value + kModulus : value;
}

std::int64_t power(std::int64_t base, std::int64_t exponent) {
    std::int64_t result = 1;
    base = normalize(base);
    while (exponent > 0) {
        if (exponent & 1) result = result * base % kModulus;
        base = base * base % kModulus;
        exponent >>= 1;
    }
    return result;
}

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t bairstow_quadratic_factor_iteration(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) {
    if (input == nullptr || length < 1 || length > kMaxInputLength) return -1;
    const auto degree_value = input[0];
    if (degree_value < 3 || degree_value > static_cast<std::int64_t>(kMaxDegree)) return -1;
    const auto degree = static_cast<std::size_t>(degree_value);
    if (length != degree + 5) return -1;

    std::array<std::int64_t, kMaxDegree + 1> coefficients{};
    for (std::size_t i = 0; i <= degree; ++i) {
        coefficients[i] = input[1 + i];
        if (coefficients[i] < 0 || coefficients[i] >= kModulus) return -1;
    }
    auto s_value = input[degree + 2];
    auto t_value = input[degree + 3];
    const auto iteration_value = input[degree + 4];
    if (coefficients[degree] == 0 || s_value < 0 || s_value >= kModulus
            || t_value < 0 || t_value >= kModulus
            || iteration_value < 1 || iteration_value > static_cast<std::int64_t>(kMaxIterations)) return -1;
    const auto iterations = static_cast<std::size_t>(iteration_value);

    std::array<std::int64_t, kMaxIterations + 1> s_trace{}, t_trace{};
    s_trace[0] = s_value;
    t_trace[0] = t_value;
    for (std::size_t step = 0; step < iterations; ++step) {
        std::array<std::int64_t, kMaxDegree + 2> q{}, r{};
        q[degree] = r[degree] = coefficients[degree];
        for (std::size_t cursor = degree; cursor-- > 0;) {
            q[cursor] = normalize(coefficients[cursor] + s_value * q[cursor + 1]
                                  + t_value * q[cursor + 2]);
            r[cursor] = normalize(q[cursor] + s_value * r[cursor + 1]
                                  + t_value * r[cursor + 2]);
        }
        const auto r2 = r[2], r3 = r[3], q0 = q[0], q1 = q[1];
        const auto ell = normalize(s_value * r2 + t_value * r3);
        const auto denominator = normalize(r2 * r2 - ell * r3);
        if (denominator == 0) return -1;
        const auto inverse = power(denominator, kModulus - 2);
        const auto delta_s = normalize(r3 * q0 - r2 * q1) * inverse % kModulus;
        const auto delta_t = normalize(ell * q1 - r2 * q0) * inverse % kModulus;
        s_value = normalize(s_value + delta_s);
        t_value = normalize(t_value + delta_t);
        s_trace[step + 1] = s_value;
        t_trace[step + 1] = t_value;
    }

    const auto output_bytes = 8 * (2 * iterations + 3);
    if (output == nullptr || capacity < output_bytes) return -2;
    store_i64_le(output, 0, static_cast<std::int64_t>(iterations + 1));
    for (std::size_t i = 0; i <= iterations; ++i) {
        store_i64_le(output, 8 * (1 + 2 * i), s_trace[i]);
        store_i64_le(output, 8 * (2 + 2 * i), t_trace[i]);
    }
    return static_cast<std::int64_t>(output_bytes);
}
