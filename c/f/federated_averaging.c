#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

double federated_averaging(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > 17) return INVALID_RESULT;
    int64_t clients = input[0];
    if (clients < 1 || clients > 8 || length != 1 + 2 * (size_t)clients) return INVALID_RESULT;
    double total = 0.0;
    for (int64_t i = 0; i < clients; ++i) {
        int64_t weight = input[1 + i];
        if (weight < 0 || weight > 1000) return INVALID_RESULT;
        total += (double)weight;
    }
    if (total <= 0.0) return INVALID_RESULT;
    double result = 0.0;
    for (int64_t i = 0; i < clients; ++i) {
        int64_t value = input[1 + clients + i];
        if (value < -1000 || value > 1000) return INVALID_RESULT;
        double normalized = (double)input[1 + i] / total;
        result += normalized * (double)value;
    }
    return result;
}
