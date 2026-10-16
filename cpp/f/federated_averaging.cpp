#include <cstddef>
#include <cstdint>

extern "C" double federated_averaging(const int64_t *input, std::size_t length) {
    if (input == nullptr || length < 3 || length > 17) return -1.0e300;
    const auto clients = input[0];
    if (clients < 1 || clients > 8 || length != 1 + 2 * static_cast<std::size_t>(clients)) return -1.0e300;
    double total = 0.0;
    for (int64_t i = 0; i < clients; ++i) {
        const auto weight = input[1 + i];
        if (weight < 0 || weight > 1000) return -1.0e300;
        total += static_cast<double>(weight);
    }
    if (total <= 0.0) return -1.0e300;
    double result = 0.0;
    for (int64_t i = 0; i < clients; ++i) {
        const auto value = input[1 + clients + i];
        if (value < -1000 || value > 1000) return -1.0e300;
        const double normalized = static_cast<double>(input[1 + i]) / total;
        result += normalized * static_cast<double>(value);
    }
    return result;
}
