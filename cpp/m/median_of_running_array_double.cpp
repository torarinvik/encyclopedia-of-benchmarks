#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_count = 64;
constexpr std::size_t max_input_length = 66;
bool less_double(double left, double right) {
    return left < right || (left == 0.0 && right == 0.0 && std::signbit(left) && !std::signbit(right));
}
void push_max(double* heap, std::size_t& count, double value) {
    std::size_t position = count++;
    while (position > 0 && less_double(heap[(position - 1) / 2], value)) {
        const std::size_t parent = (position - 1) / 2; heap[position] = heap[parent]; position = parent;
    }
    heap[position] = value;
}
double pop_max(double* heap, std::size_t& count) {
    const double result = heap[0], value = heap[--count];
    if (count == 0) return result;
    std::size_t position = 0;
    while (2 * position + 1 < count) {
        std::size_t child = 2 * position + 1;
        if (child + 1 < count && less_double(heap[child], heap[child + 1])) ++child;
        if (!less_double(value, heap[child])) break;
        heap[position] = heap[child]; position = child;
    }
    heap[position] = value; return result;
}
void push_min(double* heap, std::size_t& count, double value) {
    std::size_t position = count++;
    while (position > 0 && less_double(value, heap[(position - 1) / 2])) {
        const std::size_t parent = (position - 1) / 2; heap[position] = heap[parent]; position = parent;
    }
    heap[position] = value;
}
double pop_min(double* heap, std::size_t& count) {
    const double result = heap[0], value = heap[--count];
    if (count == 0) return result;
    std::size_t position = 0;
    while (2 * position + 1 < count) {
        std::size_t child = 2 * position + 1;
        if (child + 1 < count && less_double(heap[child + 1], heap[child])) ++child;
        if (!less_double(heap[child], value)) break;
        heap[position] = heap[child]; position = child;
    }
    heap[position] = value; return result;
}
}

extern "C" std::int64_t median_of_running_array_double(const double* input, std::size_t length,
                                                        double* output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    const double count_value = input[0];
    if (!std::isfinite(count_value) || count_value < 1.0 || count_value > max_count || std::trunc(count_value) != count_value ||
        length != 1 + static_cast<std::size_t>(count_value)) return -1;
    const std::size_t count = static_cast<std::size_t>(count_value);
    double lower[max_count], upper[max_count], medians[max_count];
    std::size_t lower_count = 0, upper_count = 0;
    for (std::size_t i = 0; i < count; ++i) {
        const double sample = input[i + 1];
        if (!std::isfinite(sample) || sample < -1000000.0 || sample > 1000000.0) return -1;
        if (upper_count > 0 && less_double(sample, upper[0])) push_max(lower, lower_count, sample);
        else push_min(upper, upper_count, sample);
        if (lower_count > upper_count + 1) push_min(upper, upper_count, pop_max(lower, lower_count));
        else if (upper_count > lower_count + 1) push_max(lower, lower_count, pop_min(upper, upper_count));
        if (lower_count > upper_count) medians[i] = lower[0];
        else if (upper_count > lower_count) medians[i] = upper[0];
        else medians[i] = (lower[0] + upper[0]) / 2.0;
    }
    if (output == nullptr || capacity < count) return -2;
    for (std::size_t i = 0; i < count; ++i) output[i] = medians[i];
    return static_cast<std::int64_t>(count);
}
