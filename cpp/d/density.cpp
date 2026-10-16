#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_nodes = 100000;
constexpr double invalid_result = -1.0e300;
}

extern "C" double density(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 3) return invalid_result;
    const auto nodes = values[0];
    const auto edges = values[1];
    const auto directed = values[2];
    if (nodes < 2 || nodes > max_nodes || (directed != 0 && directed != 1)) return invalid_result;
    const auto max_edges = directed == 1 ? nodes * (nodes - 1) : nodes * (nodes - 1) / 2;
    if (edges < 0 || edges > max_edges) return invalid_result;
    const double factor = directed == 1 ? 1.0 : 2.0;
    return (factor * static_cast<double>(edges)) /
           (static_cast<double>(nodes) * static_cast<double>(nodes - 1));
}
