#include <array>
#include <cstddef>
#include <cstdint>

namespace {
struct Matrix {
    std::array<std::array<int, 65>, 11> prefix{};
    std::array<int, 11> zeros{};

    int less(int left, int right, int value) const {
        int result = 0;
        for (int level = 0; level < 11; ++level) {
            const int zl = prefix[level][left], zr = prefix[level][right];
            if ((value >> (10 - level)) & 1) {
                result += zr - zl;
                left = zeros[level] + left - zl;
                right = zeros[level] + right - zr;
            } else {
                left = zl;
                right = zr;
            }
        }
        return result;
    }

    int quantile(int left, int right, int k) const {
        int value = 0;
        for (int level = 0; level < 11; ++level) {
            const int zl = prefix[level][left], zr = prefix[level][right];
            if (k < zr - zl) { left = zl; right = zr; }
            else {
                k -= zr - zl;
                value |= 1 << (10 - level);
                left = zeros[level] + left - zl;
                right = zeros[level] + right - zr;
            }
        }
        return value - 1000;
    }
};
}

extern "C" std::int64_t wavelet_matrix(const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 2 || input[0] < 1 || input[0] > 64) return -1;
    const int n = static_cast<int>(input[0]);
    if (length < static_cast<std::size_t>(n + 2)) return -1;
    for (int i = 0; i < n; ++i) if (input[1+i] < -1000 || input[1+i] > 1000) return -1;
    const auto q = input[n+1];
    if (q < 0 || q > 128 || length != static_cast<std::size_t>(n + 2 + 5*q)) return -1;
    Matrix matrix;
    std::array<int, 64> current{}, scratch{};
    for (int i = 0; i < n; ++i) current[i] = static_cast<int>(input[1+i]) + 1000;
    for (int level = 0; level < 11; ++level) {
        const int bit = 10 - level;
        for (int i = 0; i < n; ++i)
            matrix.prefix[level][i+1] = matrix.prefix[level][i] + (((current[i] >> bit) & 1) == 0);
        const int zeros = matrix.prefix[level][n];
        matrix.zeros[level] = zeros;
        int z = 0, o = zeros;
        for (int i = 0; i < n; ++i) {
            if (((current[i] >> bit) & 1) == 0) scratch[z++] = current[i];
            else scratch[o++] = current[i];
        }
        current = scratch;
    }
    std::int64_t total = 0;
    for (int j = 0; j < q; ++j) {
        const auto* query = input + n + 2 + 5*j;
        const auto op = query[0], a = query[1], b = query[2], c = query[3], d = query[4];
        int answer;
        if (op == 0) {
            if (a < -1000 || a > 1000 || b < -1 || b >= n) return -1;
            answer = matrix.less(0, static_cast<int>(b)+1, static_cast<int>(a)+1001)
                   - matrix.less(0, static_cast<int>(b)+1, static_cast<int>(a)+1000);
        } else if (op == 1) {
            if (a < 0 || a > b || b >= n || c < 0 || c > b-a) return -1;
            answer = matrix.quantile(static_cast<int>(a), static_cast<int>(b)+1, static_cast<int>(c));
        } else if (op == 2) {
            if (a < 0 || a > b || b >= n || c < -1000 || c > d || d > 1000) return -1;
            answer = matrix.less(static_cast<int>(a), static_cast<int>(b)+1, static_cast<int>(d)+1001)
                   - matrix.less(static_cast<int>(a), static_cast<int>(b)+1, static_cast<int>(c)+1000);
        } else return -1;
        total += static_cast<std::int64_t>(j+1) * (answer + INT64_C(1000001));
    }
    return total;
}
