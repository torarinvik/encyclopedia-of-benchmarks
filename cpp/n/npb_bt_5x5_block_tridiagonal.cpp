#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kBlock = 5;
constexpr std::size_t kMaxLine = 4;
constexpr std::size_t kRowWords = 80;
constexpr double kInvalid = -1.0e300;

bool solve_block(const double matrix[kBlock][kBlock],
                 const double right[kBlock][kBlock + 1],
                 double answer[kBlock][kBlock + 1]) {
    double work[kBlock][2 * kBlock + 1];
    for (std::size_t r = 0; r < kBlock; ++r) {
        for (std::size_t c = 0; c < kBlock; ++c) work[r][c] = matrix[r][c];
        for (std::size_t c = 0; c < kBlock + 1; ++c) work[r][kBlock + c] = right[r][c];
    }
    for (std::size_t pivot = 0; pivot < kBlock; ++pivot) {
        std::size_t best = pivot;
        for (std::size_t r = pivot + 1; r < kBlock; ++r) {
            if (std::fabs(work[r][pivot]) > std::fabs(work[best][pivot])) best = r;
        }
        if (work[best][pivot] == 0.0) return false;
        if (best != pivot) {
            for (std::size_t c = 0; c < 2 * kBlock + 1; ++c) {
                const double temporary = work[pivot][c];
                work[pivot][c] = work[best][c];
                work[best][c] = temporary;
            }
        }
        const double divisor = work[pivot][pivot];
        for (std::size_t c = pivot; c < 2 * kBlock + 1; ++c) work[pivot][c] /= divisor;
        for (std::size_t r = 0; r < kBlock; ++r) {
            if (r == pivot) continue;
            const double factor = work[r][pivot];
            for (std::size_t c = pivot; c < 2 * kBlock + 1; ++c) {
                work[r][c] -= factor * work[pivot][c];
            }
        }
    }
    for (std::size_t r = 0; r < kBlock; ++r) {
        for (std::size_t c = 0; c < kBlock + 1; ++c) answer[r][c] = work[r][kBlock + c];
    }
    return true;
}
}  // namespace

extern "C" double npb_bt_5x5_block_tridiagonal(const std::int64_t* input,
                                                std::size_t length) {
    if (input == nullptr || length < 1 || length > 1 + kRowWords * kMaxLine) return kInvalid;
    if (input[0] < 2 || input[0] > static_cast<std::int64_t>(kMaxLine)) return kInvalid;
    const std::size_t n = static_cast<std::size_t>(input[0]);
    if (length != 1 + kRowWords * n) return kInvalid;

    double lower[kMaxLine][kBlock][kBlock] = {};
    double diagonal[kMaxLine][kBlock][kBlock] = {};
    double upper[kMaxLine][kBlock][kBlock] = {};
    double rhs[kMaxLine][kBlock] = {};
    for (std::size_t row = 0; row < n; ++row) {
        std::size_t cursor = 1 + kRowWords * row;
        for (std::size_t which = 0; which < 3; ++which) {
            for (std::size_t r = 0; r < kBlock; ++r) {
                for (std::size_t c = 0; c < kBlock; ++c) {
                    const std::int64_t value = input[cursor++];
                    if (which == 1) {
                        if (r == c) {
                            if (value < 40 || value > 64) return kInvalid;
                        } else if (value < -2 || value > 2) return kInvalid;
                        diagonal[row][r][c] = static_cast<double>(value);
                    } else {
                        if (value < -2 || value > 2) return kInvalid;
                        if (which == 0) lower[row][r][c] = static_cast<double>(value);
                        else upper[row][r][c] = static_cast<double>(value);
                    }
                }
            }
        }
        for (std::size_t r = 0; r < kBlock; ++r) {
            const std::int64_t value = input[cursor++];
            if (value < -1000 || value > 1000) return kInvalid;
            rhs[row][r] = static_cast<double>(value);
        }
        if (row == 0) for (std::size_t r = 0; r < kBlock; ++r) for (std::size_t c = 0; c < kBlock; ++c) {
            if (lower[row][r][c] != 0.0) return kInvalid;
        }
        if (row + 1 == n) for (std::size_t r = 0; r < kBlock; ++r) for (std::size_t c = 0; c < kBlock; ++c) {
            if (upper[row][r][c] != 0.0) return kInvalid;
        }
        for (std::size_t r = 0; r < kBlock; ++r) {
            double off_diagonal = 0.0;
            for (std::size_t c = 0; c < kBlock; ++c) {
                if (r != c) off_diagonal += std::fabs(diagonal[row][r][c]);
                off_diagonal += std::fabs(lower[row][r][c]) + std::fabs(upper[row][r][c]);
            }
            if (diagonal[row][r][r] <= off_diagonal) return kInvalid;
        }
    }

    double modified_upper[kMaxLine][kBlock][kBlock] = {};
    double modified_rhs[kMaxLine][kBlock] = {};
    for (std::size_t row = 0; row < n; ++row) {
        double schur[kBlock][kBlock];
        double reduced[kBlock];
        double right[kBlock][kBlock + 1];
        double solved[kBlock][kBlock + 1];
        for (std::size_t r = 0; r < kBlock; ++r) {
            reduced[r] = rhs[row][r];
            for (std::size_t c = 0; c < kBlock; ++c) {
                schur[r][c] = diagonal[row][r][c];
                if (row > 0) for (std::size_t k = 0; k < kBlock; ++k) {
                    schur[r][c] -= lower[row][r][k] * modified_upper[row - 1][k][c];
                }
            }
            if (row > 0) for (std::size_t k = 0; k < kBlock; ++k) {
                reduced[r] -= lower[row][r][k] * modified_rhs[row - 1][k];
            }
            for (std::size_t c = 0; c < kBlock; ++c) right[r][c] = upper[row][r][c];
            right[r][kBlock] = reduced[r];
        }
        if (!solve_block(schur, right, solved)) return kInvalid;
        for (std::size_t r = 0; r < kBlock; ++r) {
            modified_rhs[row][r] = solved[r][kBlock];
            for (std::size_t c = 0; c < kBlock; ++c) modified_upper[row][r][c] = solved[r][c];
        }
    }

    double solution[kMaxLine][kBlock] = {};
    for (std::size_t r = 0; r < kBlock; ++r) solution[n - 1][r] = modified_rhs[n - 1][r];
    for (std::size_t row = n - 1; row-- > 0;) {
        for (std::size_t r = 0; r < kBlock; ++r) {
            solution[row][r] = modified_rhs[row][r];
            for (std::size_t c = 0; c < kBlock; ++c) {
                solution[row][r] -= modified_upper[row][r][c] * solution[row + 1][c];
            }
        }
    }
    double checksum = 0.0;
    for (std::size_t row = 0; row < n; ++row) for (std::size_t r = 0; r < kBlock; ++r) {
        checksum += static_cast<double>(row * kBlock + r + 1) * solution[row][r];
    }
    return std::isfinite(checksum) ? checksum : kInvalid;
}
