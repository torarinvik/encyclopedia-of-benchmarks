#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MAX_ROWS = 30;
constexpr std::int64_t HASH_MOD = 1'000'000'007;
}

extern "C" std::int64_t pascal_triangle_benchmark(const std::int64_t *values,
                                                    std::size_t length) noexcept
{
    if (length != 1 || values[0] < 0 || values[0] > MAX_ROWS) return -1;
    const auto row_count = static_cast<std::size_t>(values[0]);
    std::int64_t row[30]{};
    row[0] = 1;
    std::int64_t hash = 0;
    for (std::size_t row_index = 0; row_index < row_count; ++row_index) {
        for (std::size_t column = row_index; column > 0; --column) {
            row[column] += row[column - 1];
        }
        for (std::size_t column = 0; column <= row_index; ++column) {
            hash = (hash * 31 + row[column] % HASH_MOD) % HASH_MOD;
        }
    }
    return hash;
}
