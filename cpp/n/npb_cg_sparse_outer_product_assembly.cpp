#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t kMaxN = 16;
constexpr std::size_t kMaxNonzer = 4;
constexpr std::size_t kMaxSupport = 5;
constexpr std::size_t kMaxTriplets = 416;
constexpr std::int64_t kMaxValueMicro = 1'000'000;
constexpr std::int64_t kMaxShiftMicro = 10'000'000;
constexpr double kScale = 1'000'000.0;
constexpr double kRcond = 0.1;

void put_u64(std::uint8_t* out, std::size_t& offset, std::uint64_t value) {
    for (unsigned byte = 0; byte < 8; ++byte, offset += 1)
        out[offset] = static_cast<std::uint8_t>(value >> (8 * byte));
}

void put_f64(std::uint8_t* out, std::size_t& offset, double value) {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    put_u64(out, offset, bits);
}

bool valid(const std::int64_t* values, std::size_t length,
           std::size_t& n, std::size_t& nonzer) {
    if (values == nullptr || length < 3 || length > 3 + 2 * kMaxN * kMaxNonzer)
        return false;
    if (values[0] < 2 || values[0] > static_cast<std::int64_t>(kMaxN) ||
        values[1] < 1 || values[1] > static_cast<std::int64_t>(kMaxNonzer) ||
        values[2] < 0 || values[2] > kMaxShiftMicro)
        return false;
    n = static_cast<std::size_t>(values[0]);
    nonzer = static_cast<std::size_t>(values[1]);
    if (length != 3 + 2 * n * nonzer) return false;
    std::size_t cursor = 3;
    for (std::size_t vector = 0; vector < n; ++vector) {
        std::uint32_t seen = 0;
        for (std::size_t entry = 0; entry < nonzer; ++entry) {
            const std::int64_t coordinate = values[cursor++];
            const std::int64_t value = values[cursor++];
            if (coordinate < 0 || coordinate >= static_cast<std::int64_t>(n) ||
                value == 0 || value < -kMaxValueMicro || value > kMaxValueMicro)
                return false;
            const std::uint32_t bit = std::uint32_t{1} << static_cast<unsigned>(coordinate);
            if ((seen & bit) != 0) return false;
            seen |= bit;
        }
    }
    return true;
}
}

extern "C" std::int64_t npb_cg_sparse_outer_product_assembly(
        const std::int64_t* values, std::size_t length,
        std::uint8_t* output, std::size_t capacity) noexcept {
    std::size_t n, nonzer;
    if (!valid(values, length, n, nonzer)) return -1;
    std::uint8_t raw_rows[kMaxTriplets], raw_columns[kMaxTriplets];
    double raw_values[kMaxTriplets];
    std::size_t raw_count = 0, cursor = 3;
    for (std::size_t vector = 0; vector < n; ++vector) {
        std::uint8_t coordinates[kMaxSupport];
        double vector_values[kMaxSupport];
        std::size_t support_count = nonzer;
        bool has_anchor = false;
        for (std::size_t entry = 0; entry < nonzer; ++entry) {
            const auto coordinate = static_cast<std::size_t>(values[cursor++]);
            coordinates[entry] = static_cast<std::uint8_t>(coordinate);
            vector_values[entry] = static_cast<double>(values[cursor++]) / kScale;
            if (coordinate == vector) {
                vector_values[entry] = 0.5;
                has_anchor = true;
            }
        }
        if (!has_anchor) {
            coordinates[support_count] = static_cast<std::uint8_t>(vector);
            vector_values[support_count++] = 0.5;
        }
        const double weight = vector == 0 ? 1.0 :
            (vector + 1 == n ? kRcond : std::pow(kRcond, static_cast<double>(vector) / (n - 1)));
        for (std::size_t column_slot = 0; column_slot < support_count; ++column_slot) {
            const double scaled_column = weight * vector_values[column_slot];
            for (std::size_t row_slot = 0; row_slot < support_count; ++row_slot) {
                raw_rows[raw_count] = coordinates[row_slot];
                raw_columns[raw_count] = coordinates[column_slot];
                raw_values[raw_count++] = vector_values[row_slot] * scaled_column;
            }
        }
    }
    const double diagonal_addend = kRcond - static_cast<double>(values[2]) / kScale;
    for (std::size_t diagonal = 0; diagonal < n; ++diagonal) {
        raw_rows[raw_count] = static_cast<std::uint8_t>(diagonal);
        raw_columns[raw_count] = static_cast<std::uint8_t>(diagonal);
        raw_values[raw_count++] = diagonal_addend;
    }

    std::int64_t column_pointers[kMaxN + 1];
    std::uint8_t row_indices[kMaxN * kMaxN];
    double matrix_values[kMaxN * kMaxN];
    std::size_t nnz = 0;
    for (std::size_t column = 0; column < n; ++column) {
        column_pointers[column] = static_cast<std::int64_t>(nnz);
        for (std::size_t row = 0; row < n; ++row) {
            double sum = 0.0;
            bool touched = false;
            for (std::size_t triple = 0; triple < raw_count; ++triple) {
                if (raw_rows[triple] == row && raw_columns[triple] == column) {
                    sum += raw_values[triple];
                    touched = true;
                }
            }
            if (touched) {
                row_indices[nnz] = static_cast<std::uint8_t>(row);
                matrix_values[nnz++] = sum;
            }
        }
    }
    column_pointers[n] = static_cast<std::int64_t>(nnz);
    const std::size_t required = 8 * (2 + (n + 1) + 2 * nnz);
    if (output == nullptr || capacity < required) return -2;
    std::size_t offset = 0;
    put_f64(output, offset, static_cast<double>(n));
    put_f64(output, offset, static_cast<double>(nnz));
    for (std::size_t i = 0; i <= n; ++i) put_f64(output, offset, static_cast<double>(column_pointers[i]));
    for (std::size_t i = 0; i < nnz; ++i) put_f64(output, offset, static_cast<double>(row_indices[i]));
    for (std::size_t i = 0; i < nnz; ++i) put_f64(output, offset, matrix_values[i]);
    return static_cast<std::int64_t>(required);
}
