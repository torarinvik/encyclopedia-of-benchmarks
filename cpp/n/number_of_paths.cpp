// Count vertex-simple directed paths with recursive DFS.
#include <cstddef>
#include <cstdint>

static std::uint32_t count_from(const std::int64_t *matrix, std::uint32_t n,
                                std::uint32_t current, std::uint32_t destination,
                                std::uint32_t visited)
{
    if (current == destination) return 1;
    visited |= std::uint32_t{1} << current;
    std::uint32_t count = 0;
    for (std::uint32_t next = 0; next < n; ++next) {
        if (matrix[static_cast<std::size_t>(current) * n + next] == 1 &&
            (visited & (std::uint32_t{1} << next)) == 0) {
            count += count_from(matrix, n, next, destination, visited);
        }
    }
    return count;
}

extern "C" std::int64_t number_of_paths(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length < 3 || values[0] < 1 || values[0] > 10) return -1;
    const auto n = static_cast<std::uint32_t>(values[0]);
    if (length != 3 + static_cast<std::size_t>(n) * n) return -1;
    if (values[1] < 0 || values[1] > UINT32_MAX || values[2] < 0 || values[2] > UINT32_MAX)
        return -1;
    for (std::size_t i = 3; i < length; ++i) if (values[i] != 0 && values[i] != 1) return -1;
    const auto source = static_cast<std::uint32_t>(values[1]);
    const auto destination = static_cast<std::uint32_t>(values[2]);
    if (source >= n || destination >= n) return 0;
    return count_from(values + 3, n, source, destination, 0);
}
