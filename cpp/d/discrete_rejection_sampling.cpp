#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_categories = 8;
constexpr std::size_t max_samples = 8;
constexpr std::size_t max_attempts = 32;
constexpr std::size_t max_input_values = 83;

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & UINT64_C(255));
        bits >>= 8;
    }
}
}  // namespace

extern "C" std::int64_t discrete_rejection_sampling(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 3 || length > max_input_values) return -1;
    const std::int64_t n_value = input[0];
    const std::int64_t samples_value = input[1];
    const std::int64_t attempts_value = input[2];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_categories) ||
        samples_value < 1 || samples_value > static_cast<std::int64_t>(max_samples) ||
        attempts_value < 1 || attempts_value > static_cast<std::int64_t>(max_attempts)) return -1;
    const std::size_t n = static_cast<std::size_t>(n_value);
    const std::size_t wanted = static_cast<std::size_t>(samples_value);
    const std::size_t attempts = static_cast<std::size_t>(attempts_value);
    if (length != 3 + 2 * n + 2 * attempts) return -1;

    std::int64_t target[max_categories]{};
    std::int64_t proposal[max_categories]{};
    std::int64_t cumulative[max_categories]{};
    std::uint64_t target_total = 0;
    std::uint64_t proposal_total = 0;
    for (std::size_t i = 0; i < n; ++i) {
        const std::int64_t weight = input[3 + i];
        const std::int64_t q_weight = input[3 + n + i];
        if (weight < 1 || weight > 20 || q_weight < 1 || q_weight > 20) return -1;
        target[i] = weight;
        proposal[i] = q_weight;
        target_total += static_cast<std::uint64_t>(weight);
        proposal_total += static_cast<std::uint64_t>(q_weight);
        cumulative[i] = static_cast<std::int64_t>(proposal_total);
    }

    std::uint64_t envelope = 1;
    for (std::size_t i = 0; i < n; ++i) {
        const std::uint64_t numerator = static_cast<std::uint64_t>(target[i]) * proposal_total;
        const std::uint64_t denominator = target_total * static_cast<std::uint64_t>(proposal[i]);
        const std::uint64_t ratio_ceiling = (numerator + denominator - 1) / denominator;
        if (ratio_ceiling > envelope) envelope = ratio_ceiling;
    }

    const std::size_t tape_offset = 3 + 2 * n;
    for (std::size_t attempt = 0; attempt < attempts; ++attempt) {
        const std::int64_t proposal_draw = input[tape_offset + 2 * attempt];
        const std::int64_t acceptance_draw = input[tape_offset + 2 * attempt + 1];
        if (proposal_draw < 0 || static_cast<std::uint64_t>(proposal_draw) >= proposal_total || acceptance_draw < 0) return -1;
        std::size_t category = 0;
        while (static_cast<std::uint64_t>(cumulative[category]) <= static_cast<std::uint64_t>(proposal_draw)) ++category;
        const std::uint64_t acceptance_range = target_total * static_cast<std::uint64_t>(proposal[category]) * envelope;
        if (static_cast<std::uint64_t>(acceptance_draw) >= acceptance_range) return -1;
    }

    const std::size_t output_bytes = 16 * wanted;
    if (output == nullptr || capacity < output_bytes) return -2;
    std::int64_t staged[2 * max_samples]{};
    std::size_t produced = 0;
    std::size_t attempts_since_acceptance = 0;
    for (std::size_t attempt = 0; attempt < attempts; ++attempt) {
        ++attempts_since_acceptance;
        const auto proposal_draw = static_cast<std::uint64_t>(input[tape_offset + 2 * attempt]);
        const auto acceptance_draw = static_cast<std::uint64_t>(input[tape_offset + 2 * attempt + 1]);
        std::size_t category = 0;
        while (static_cast<std::uint64_t>(cumulative[category]) <= proposal_draw) ++category;
        if (acceptance_draw < static_cast<std::uint64_t>(target[category]) * proposal_total) {
            staged[produced++] = static_cast<std::int64_t>(category);
            staged[produced++] = static_cast<std::int64_t>(attempts_since_acceptance);
            attempts_since_acceptance = 0;
            if (produced == 2 * wanted) break;
        }
    }
    if (produced != 2 * wanted) return -3;
    for (std::size_t i = 0; i < produced; ++i) store_i64_le(output, 8 * i, staged[i]);
    return static_cast<std::int64_t>(output_bytes);
}
