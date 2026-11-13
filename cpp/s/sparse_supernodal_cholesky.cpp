#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>

extern "C" std::int64_t sparse_supernodal_cholesky(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) {
    if (input == nullptr || length < 2 || length > 56) return -1;
    if (input[0] < 1 || input[0] > 8 || input[1] < 1 || input[1] > input[0]) return -1;
    const int n = static_cast<int>(input[0]), count = static_cast<int>(input[1]);
    const auto triangle = static_cast<std::size_t>(n * (n + 1) / 2);
    if (length != 3 + static_cast<std::size_t>(count + n) + triangle) return -1;
    std::array<int, 9> boundary{};
    std::array<int, 8> masks{};
    std::array<std::array<int, 8>, 8> slot{};
    for (auto &row : slot) row.fill(-1);
    for (int i = 0; i <= count; ++i) {
        const auto value = input[2 + i];
        if (value < 0 || value > n) return -1;
        boundary[i] = static_cast<int>(value);
        if (i && boundary[i] <= boundary[i - 1]) return -1;
    }
    if (boundary[0] != 0 || boundary[count] != n) return -1;
    for (int row = 0; row < n; ++row) {
        const auto mask = input[3 + count + row];
        if (mask < 0 || mask >= (1 << (row + 1)) || !(mask & (1 << row))) return -1;
        masks[row] = static_cast<int>(mask);
    }
    for (int col = 0; col < n; ++col)
        for (int row = col + 1; row < n; ++row) if (masks[row] & (1 << col))
            for (int lower = row + 1; lower < n; ++lower)
                if ((masks[lower] & (1 << col)) && !(masks[lower] & (1 << row))) return -1;
    for (int block = 0; block < count; ++block) {
        const int start = boundary[block], end = boundary[block + 1];
        for (int row = start; row < end; ++row)
            for (int col = start; col < row; ++col)
                if (!(masks[row] & (1 << col))) return -1;
        const int mask = ((1 << end) - 1) ^ ((1 << start) - 1);
        for (int row = end; row < n; ++row)
            if ((masks[row] & mask) != 0 && (masks[row] & mask) != mask) return -1;
    }
    std::array<double, 36> sparse{};
    std::size_t cursor = 3 + count + n, used = 0;
    for (int row = 0; row < n; ++row) for (int col = 0; col <= row; ++col) {
        const auto value = input[cursor++];
        if (value < -1000000 || value > 1000000) return -1;
        if (!(masks[row] & (1 << col))) {
            if (value != 0) return -1;
        } else {
            slot[row][col] = static_cast<int>(used);
            sparse[used++] = static_cast<double>(value) / 1000.0;
        }
    }
    for (int block = 0; block < count; ++block) {
        const int start = boundary[block], end = boundary[block + 1];
        for (int col = start; col < end; ++col) {
            auto &pivot = sparse[slot[col][col]];
            if (!std::isfinite(pivot) || pivot <= 0) return -1;
            pivot = std::sqrt(pivot);
            for (int row = col + 1; row < end; ++row) sparse[slot[row][col]] /= pivot;
            for (int row = col + 1; row < end; ++row)
                for (int target = col + 1; target <= row; ++target)
                    sparse[slot[row][target]] -= sparse[slot[row][col]] * sparse[slot[target][col]];
        }
        for (int row = end; row < n; ++row) if (masks[row] & (1 << start)) {
            for (int col = start; col < end; ++col) {
                auto &value = sparse[slot[row][col]];
                for (int k = start; k < col; ++k) value -= sparse[slot[row][k]] * sparse[slot[col][k]];
                value /= sparse[slot[col][col]];
            }
        }
        for (int row = end; row < n; ++row) if (masks[row] & (1 << start))
            for (int target = end; target <= row; ++target) if (masks[target] & (1 << start))
                for (int k = start; k < end; ++k)
                    sparse[slot[row][target]] -= sparse[slot[row][k]] * sparse[slot[target][k]];
    }
    const auto required = triangle * 8;
    if (output == nullptr || capacity < required) return -2;
    std::size_t offset = 0;
    for (int row = 0; row < n; ++row) for (int col = 0; col <= row; ++col) {
        const double value = slot[row][col] < 0 ? 0.0 : sparse[slot[row][col]];
        std::uint64_t bits;
        std::memcpy(&bits, &value, sizeof bits);
        for (int byte = 0; byte < 8; ++byte) output[offset++] = static_cast<std::uint8_t>(bits >> (8 * byte));
    }
    return static_cast<std::int64_t>(required);
}
