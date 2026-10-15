#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_samples = 256;
constexpr int max_levels = 16;
constexpr int max_buckets = 5;
constexpr int bucket_capacity = max_buckets + 1;
constexpr int min_subwindow = 5;
constexpr double input_scale = 1'000'000'000.0;

struct Adwin {
    std::array<int, max_levels> sizes{};
    std::array<std::array<double, bucket_capacity>, max_levels> totals{};
    std::array<std::array<double, bucket_capacity>, max_levels> variances{};
    std::int64_t width = 0;
    double total = 0.0;
    double variance = 0.0;
    int bucket_count = 0;
    double delta = 0.0;
};

double adwin_sqrt(double value) {
    if (value <= 0.0) return 0.0;
    double root = value > 1.0 ? value : 1.0;
    for (int iteration = 0; iteration < 80; ++iteration) root = 0.5 * (root + value / root);
    return root;
}

double adwin_ln(double value) {
    int exponent = 0;
    while (value >= 2.0) { value *= 0.5; ++exponent; }
    const double ratio = (value - 1.0) / (value + 1.0);
    const double square = ratio * ratio;
    double term = ratio, sum = 0.0;
    for (int iteration = 0; iteration < 40; ++iteration) {
        sum += term / static_cast<double>(2 * iteration + 1);
        term *= square;
    }
    return 2.0 * sum + static_cast<double>(exponent) * 0.693147180559945309417232121458176568;
}

void add_bucket(Adwin &state, int level, double total, double variance) {
    const int slot = state.sizes[level]++;
    state.totals[level][slot] = total;
    state.variances[level][slot] = variance;
}

void remove_oldest(Adwin &state, int level, int count) {
    const int old_size = state.sizes[level];
    for (int i = count; i < old_size; ++i) {
        state.totals[level][i - count] = state.totals[level][i];
        state.variances[level][i - count] = state.variances[level][i];
    }
    state.sizes[level] -= count;
}

void compress(Adwin &state) {
    for (int level = 0; level + 1 < max_levels && state.sizes[level] > max_buckets; ++level) {
        const double size = static_cast<double>(1 << level);
        const double first_mean = state.totals[level][0] / size;
        const double second_mean = state.totals[level][1] / size;
        const double difference = first_mean - second_mean;
        const double merged_variance = state.variances[level][0] + state.variances[level][1] +
            size * size * difference * difference / (size + size);
        add_bucket(state, level + 1, state.totals[level][0] + state.totals[level][1], merged_variance);
        remove_oldest(state, level, 2);
        --state.bucket_count;
    }
}

void insert(Adwin &state, double value) {
    ++state.width;
    add_bucket(state, 0, value, 0.0);
    ++state.bucket_count;
    if (state.width > 1) {
        const double deviation = value - state.total / static_cast<double>(state.width - 1);
        state.variance += static_cast<double>(state.width - 1) * deviation * deviation / static_cast<double>(state.width);
    }
    state.total += value;
    compress(state);
}

bool significant(const Adwin &state, std::int64_t old_width, std::int64_t recent_width, double difference) {
    const double harmonic = 1.0 / static_cast<double>(old_width - min_subwindow + 1) +
        1.0 / static_cast<double>(recent_width - min_subwindow + 1);
    const double confidence = adwin_ln(2.0 * adwin_ln(static_cast<double>(state.width)) / state.delta);
    const double window_variance = state.variance / static_cast<double>(state.width);
    const double epsilon = adwin_sqrt(2.0 * harmonic * window_variance * confidence) +
        2.0 / 3.0 * confidence * harmonic;
    return (difference < 0.0 ? -difference : difference) > epsilon;
}

void drop_oldest(Adwin &state) {
    int level = max_levels - 1;
    while (level > 0 && state.sizes[level] == 0) --level;
    const std::int64_t size = static_cast<std::int64_t>(1 << level);
    const double bucket_total = state.totals[level][0];
    state.width -= size;
    state.total -= bucket_total;
    if (state.width > 0) {
        const double bucket_mean = bucket_total / static_cast<double>(size);
        const double difference = bucket_mean - state.total / static_cast<double>(state.width);
        state.variance -= state.variances[level][0] + static_cast<double>(size) * static_cast<double>(state.width) *
            difference * difference / static_cast<double>(size + state.width);
    } else {
        state.variance = 0.0;
    }
    if (state.variance < 0.0) state.variance = 0.0;
    remove_oldest(state, level, 1);
    --state.bucket_count;
}

bool detect_change(Adwin &state) {
    bool changed = false, searching = true;
    while (searching && state.width >= 2 * min_subwindow) {
        searching = false;
        bool stop = false;
        std::int64_t old_width = 0;
        double old_total = 0.0;
        for (int level = max_levels - 1; level >= 0 && !stop; --level) {
            for (int bucket = 0; bucket < state.sizes[level]; ++bucket) {
                if (level == 0 && bucket == state.sizes[level] - 1) { stop = true; break; }
                old_width += static_cast<std::int64_t>(1 << level);
                old_total += state.totals[level][bucket];
                const std::int64_t recent_width = state.width - old_width;
                const double recent_total = state.total - old_total;
                if (recent_width < min_subwindow) { stop = true; break; }
                if (old_width >= min_subwindow &&
                    significant(state, old_width, recent_width,
                                old_total / static_cast<double>(old_width) - recent_total / static_cast<double>(recent_width))) {
                    changed = true;
                    searching = true;
                    drop_oldest(state);
                    stop = true;
                    break;
                }
            }
        }
    }
    return changed;
}

void write_i64(std::uint8_t *output, std::size_t word_index, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[8 * word_index + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t adwin(const std::int64_t *input, std::size_t length,
                               std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 3 || length > 2 + max_samples) return -1;
    const std::int64_t sample_count_value = input[0], delta_value = input[1];
    if (sample_count_value < 1 || sample_count_value > static_cast<std::int64_t>(max_samples) ||
        length != 2 + static_cast<std::size_t>(sample_count_value) || delta_value < 1 || delta_value > 100'000'000) return -1;
    const auto sample_count = static_cast<std::size_t>(sample_count_value);
    for (std::size_t i = 0; i < sample_count; ++i)
        if (input[2 + i] < -1'000'000'000LL || input[2 + i] > 1'000'000'000LL) return -1;
    if (output == nullptr || output_capacity < 16 * sample_count) return -2;

    Adwin state{};
    state.delta = static_cast<double>(delta_value) / input_scale;
    for (std::size_t i = 0; i < sample_count; ++i) {
        insert(state, static_cast<double>(input[2 + i]) / input_scale);
        const std::int64_t flag = detect_change(state) ? 1 : 0;
        write_i64(output, 2 * i, flag);
        write_i64(output, 2 * i + 1, state.width);
    }
    return static_cast<std::int64_t>(2 * sample_count);
}
