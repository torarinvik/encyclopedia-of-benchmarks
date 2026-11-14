// Independent finite-field polynomial primitives for difference_product.
// Registered draft; see the package README for verification status.
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace difference_product_draft {
constexpr std::int64_t modulus = 998244353;
constexpr std::int64_t primitive_root = 3;

std::int64_t power(std::int64_t base, std::int64_t exponent) {
    std::int64_t result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}

void transform(std::vector<std::int64_t>& values, bool inverse) {
    const std::size_t n = values.size();
    std::size_t reversed = 0;
    for (std::size_t i = 1; i < n; ++i) {
        std::size_t bit = n >> 1;
        while (reversed & bit) { reversed ^= bit; bit >>= 1; }
        reversed ^= bit;
        if (i < reversed) std::swap(values[i], values[reversed]);
    }
    for (std::size_t width = 2; width <= n; width <<= 1) {
        auto step = power(primitive_root, (modulus - 1) / static_cast<std::int64_t>(width));
        if (inverse) step = power(step, modulus - 2);
        for (std::size_t start = 0; start < n; start += width) {
            std::int64_t root = 1;
            for (std::size_t j = 0; j < width / 2; ++j) {
                const auto even = values[start + j];
                const auto odd = values[start + j + width / 2] * root % modulus;
                values[start + j] = (even + odd) % modulus;
                values[start + j + width / 2] = (even - odd + modulus) % modulus;
                root = root * step % modulus;
            }
        }
    }
    if (inverse) {
        const auto scale = power(static_cast<std::int64_t>(n), modulus - 2);
        for (auto& value : values) value = value * scale % modulus;
    }
}

std::vector<std::int64_t> multiply(const std::vector<std::int64_t>& a,
                                   const std::vector<std::int64_t>& b) {
    if (a.empty() || b.empty()) return {};
    const std::size_t result_size = a.size() + b.size() - 1;
    if (std::min(a.size(), b.size()) <= 32) {
        std::vector<std::int64_t> result(result_size, 0);
        for (std::size_t i = 0; i < a.size(); ++i)
            for (std::size_t j = 0; j < b.size(); ++j)
                result[i + j] = (result[i + j] + a[i] * b[j]) % modulus;
        return result;
    }
    std::size_t size = 1;
    while (size < result_size) size <<= 1;
    auto left = a;
    auto right = b;
    left.resize(size, 0);
    right.resize(size, 0);
    transform(left, false);
    transform(right, false);
    for (std::size_t i = 0; i < size; ++i) left[i] = left[i] * right[i] % modulus;
    transform(left, true);
    left.resize(result_size);
    return left;
}

// Newton doubling computes the inverse modulo x^count. The caller supplies a
// nonzero constant term; all coefficients remain canonical field elements.
std::vector<std::int64_t> inverse_series(const std::vector<std::int64_t>& f,
                                         std::size_t count) {
    std::vector<std::int64_t> inverse{power(f[0], modulus - 2)};
    while (inverse.size() < count) {
        const std::size_t next = std::min(count, 2 * inverse.size());
        std::vector<std::int64_t> prefix(f.begin(), f.begin() + std::min(next, f.size()));
        auto error = multiply(prefix, inverse);
        error.resize(next, 0);
        for (auto& coefficient : error)
            coefficient = coefficient == 0 ? 0 : modulus - coefficient;
        error[0] = (error[0] + 2) % modulus;
        inverse = multiply(inverse, error);
        inverse.resize(next);
    }
    return inverse;
}

// Remainder of a polynomial on division by a nonzero monic polynomial.
// Reverse the leading coefficients to turn quotient extraction into a
// power-series multiplication, then subtract the reconstructed multiple.
std::vector<std::int64_t> remainder(const std::vector<std::int64_t>& dividend,
                                    const std::vector<std::int64_t>& divisor) {
    if (dividend.size() < divisor.size()) return dividend;
    if (divisor.size() == 1) return {};
    const std::size_t quotient_size = dividend.size() - divisor.size() + 1;
    std::vector<std::int64_t> high_dividend;
    high_dividend.reserve(quotient_size);
    for (std::size_t i = 0; i < quotient_size; ++i)
        high_dividend.push_back(dividend[dividend.size() - 1 - i]);
    std::vector<std::int64_t> reverse_divisor(divisor.rbegin(), divisor.rend());
    auto reciprocal = inverse_series(reverse_divisor, quotient_size);
    auto reversed_quotient = multiply(high_dividend, reciprocal);
    reversed_quotient.resize(quotient_size);
    std::reverse(reversed_quotient.begin(), reversed_quotient.end());
    const auto removed = multiply(reversed_quotient, divisor);
    std::vector<std::int64_t> result(divisor.size() - 1, 0);
    for (std::size_t i = 0; i < result.size(); ++i) {
        const auto subtrahend = i < removed.size() ? removed[i] : 0;
        result[i] = (dividend[i] - subtrahend + modulus) % modulus;
    }
    while (!result.empty() && result.back() == 0) result.pop_back();
    return result;
}

// Product tree of (x - point), padded with multiplicative identity leaves.
struct PointTree {
    std::size_t size;
    std::size_t count;
    std::vector<std::vector<std::int64_t>> products;

    explicit PointTree(const std::vector<std::int64_t>& points)
        : size(1), count(points.size()) {
        while (size < count) size <<= 1;
        products.resize(2 * size);
        for (std::size_t i = 0; i < size; ++i) {
            if (i < count) products[size + i] = {(modulus - points[i]) % modulus, 1};
            else products[size + i] = {1};
        }
        for (std::size_t i = size; i-- > 1;)
            products[i] = multiply(products[2 * i], products[2 * i + 1]);
    }

    std::vector<std::int64_t> evaluate(const std::vector<std::int64_t>& polynomial) const {
        std::vector<std::int64_t> answers(count, 0);
        if (count == 0) return answers;
        descend(1, remainder(polynomial, products[1]), answers);
        return answers;
    }

private:
    void descend(std::size_t node, const std::vector<std::int64_t>& value,
                 std::vector<std::int64_t>& answers) const {
        if (node >= size) {
            const std::size_t index = node - size;
            if (index < count && !value.empty()) answers[index] = value[0];
            return;
        }
        descend(2 * node, remainder(value, products[2 * node]), answers);
        descend(2 * node + 1, remainder(value, products[2 * node + 1]), answers);
    }
};

// Split in input order. The left root polynomial evaluated at the right
// points produces product(right - left), so each cross pair reverses sign.
std::int64_t ordered_product(const std::vector<std::int64_t>& points,
                             std::size_t begin, std::size_t end) {
    const std::size_t count = end - begin;
    if (count <= 32) {
        std::int64_t value = 1;
        for (std::size_t i = begin; i < end; ++i)
            for (std::size_t j = i + 1; j < end; ++j)
                value = value * ((points[i] - points[j] + modulus) % modulus) % modulus;
        return value;
    }
    const std::size_t middle = begin + count / 2;
    auto result = ordered_product(points, begin, middle);
    result = result * ordered_product(points, middle, end) % modulus;
    if (result == 0) return 0;
    std::vector<std::int64_t> left(points.begin() + begin, points.begin() + middle);
    std::vector<std::int64_t> right(points.begin() + middle, points.begin() + end);
    const PointTree left_tree(left);
    const PointTree right_tree(right);
    const auto values = right_tree.evaluate(left_tree.products[1]);
    for (auto value : values) result = result * value % modulus;
    if (((middle - begin) & 1) && ((end - middle) & 1) && result != 0)
        result = modulus - result;
    return result;
}
} // namespace difference_product_draft

extern "C" std::int64_t difference_product(const std::int64_t* input, std::size_t length) {
    using namespace difference_product_draft;
    if (!input || length == 0 || input[0] < 0 || input[0] > 65536) return -1;
    const auto count = static_cast<std::size_t>(input[0]);
    if (length != count + 1) return -1;
    std::vector<std::int64_t> values;
    values.reserve(count);
    for (std::size_t i = 0; i < count; ++i) {
        const auto value = input[i + 1];
        if (value < 0 || value >= modulus) return -1;
        values.push_back(value);
    }
    return ordered_product(values, 0, values.size());
}
