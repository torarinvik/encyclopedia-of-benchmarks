#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_d = 4, max_n = 16, max_l = 4, max_input = 318;
constexpr std::int64_t q24 = 16'777'216;

std::int64_t round_away(std::int64_t numerator, std::int64_t denominator) noexcept {
    const auto magnitude = numerator < 0 ? -numerator : numerator;
    auto quotient = magnitude / denominator;
    const auto remainder = magnitude % denominator;
    if (2 * remainder >= denominator) ++quotient;
    return numerator < 0 ? -quotient : quotient;
}

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t bodytrack_annealed_particle_filter(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 3 || length > max_input) return -1;
    const auto d_value = input[0], n_value = input[1], layers_value = input[2];
    if (d_value < 1 || d_value > static_cast<std::int64_t>(max_d) ||
        n_value < 2 || n_value > static_cast<std::int64_t>(max_n) ||
        layers_value < 1 || layers_value > static_cast<std::int64_t>(max_l)) return -1;
    const auto d = static_cast<std::size_t>(d_value);
    const auto n = static_cast<std::size_t>(n_value);
    const auto layers = static_cast<std::size_t>(layers_value);
    const auto expected = 2 + d + 2 * layers + n * d + (layers - 1) * n * (d + 1);
    if (length != expected) return -1;

    const auto target_at = std::size_t{3};
    const auto beta_at = target_at + d;
    const auto sigma_at = beta_at + layers;
    const auto pose_at = sigma_at + layers - 1;
    const auto uniform_at = pose_at + n * d;
    const auto shock_at = uniform_at + (layers - 1) * n;
    std::int64_t target[max_d], beta[max_l], sigma[max_l - 1];
    for (std::size_t axis = 0; axis < d; ++axis) {
        target[axis] = input[target_at + axis];
        if (target[axis] < -10000 || target[axis] > 10000) return -1;
    }
    for (std::size_t layer = 0; layer < layers; ++layer) {
        beta[layer] = input[beta_at + layer];
        if (beta[layer] < 1 || beta[layer] > 8 ||
            (layer != 0 && beta[layer] <= beta[layer - 1])) return -1;
    }
    for (std::size_t layer = 0; layer + 1 < layers; ++layer) {
        sigma[layer] = input[sigma_at + layer];
        if (sigma[layer] < 0 || sigma[layer] > 2000 ||
            (layer != 0 && sigma[layer] > sigma[layer - 1])) return -1;
    }
    for (std::size_t i = 0; i < n * d; ++i)
        if (input[pose_at + i] < -10000 || input[pose_at + i] > 10000) return -1;
    for (std::size_t i = 0; i < (layers - 1) * n; ++i)
        if (input[uniform_at + i] < 0 || input[uniform_at + i] >= q24) return -1;
    for (std::size_t i = 0; i < (layers - 1) * n * d; ++i)
        if (input[shock_at + i] < -3000 || input[shock_at + i] > 3000) return -1;

    const auto required = 8 * d;
    if (output == nullptr || capacity < required) return -2;
    std::int64_t storage_a[max_n][max_d]{}, storage_b[max_n][max_d]{};
    auto* population = storage_a;
    auto* next_population = storage_b;
    std::int64_t weights[max_n]{}, estimate[max_d]{};
    for (std::size_t particle = 0; particle < n; ++particle)
        for (std::size_t axis = 0; axis < d; ++axis)
            population[particle][axis] = input[pose_at + particle * d + axis];

    for (std::size_t layer = 0; layer < layers; ++layer) {
        std::int64_t total_weight = 0;
        for (std::size_t particle = 0; particle < n; ++particle) {
            std::int64_t squared_distance = 0;
            for (std::size_t axis = 0; axis < d; ++axis) {
                const auto delta = population[particle][axis] - target[axis];
                squared_distance += delta * delta;
            }
            const auto energy = squared_distance / 10000;
            const auto base = (q24 * 100000) / (100000 + energy);
            auto weight = base;
            for (std::int64_t power = 1; power < beta[layer]; ++power)
                weight = (weight * base) / q24;
            weights[particle] = weight;
            total_weight += weight;
        }
        if (layer + 1 == layers) {
            for (std::size_t axis = 0; axis < d; ++axis) {
                std::int64_t moment = 0;
                for (std::size_t particle = 0; particle < n; ++particle)
                    moment += weights[particle] * population[particle][axis];
                estimate[axis] = round_away(moment, total_weight);
            }
            break;
        }
        for (std::size_t child = 0; child < n; ++child) {
            const auto draw = input[uniform_at + layer * n + child];
            const auto threshold = (draw * total_weight) / q24;
            std::int64_t cumulative = 0;
            std::size_t ancestor = 0;
            while (cumulative <= threshold) cumulative += weights[ancestor++];
            --ancestor;
            for (std::size_t axis = 0; axis < d; ++axis) {
                const auto shock = input[shock_at + layer * n * d + child * d + axis];
                auto coordinate = population[ancestor][axis] + round_away(sigma[layer] * shock, 1000);
                if (coordinate < -10000) coordinate = -10000;
                if (coordinate > 10000) coordinate = 10000;
                next_population[child][axis] = coordinate;
            }
        }
        auto* temporary = population;
        population = next_population;
        next_population = temporary;
    }
    for (std::size_t axis = 0; axis < d; ++axis)
        store_i64_le(output, 8 * axis, estimate[axis]);
    return static_cast<std::int64_t>(required);
}
