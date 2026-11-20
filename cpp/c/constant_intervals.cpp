#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 256;

struct IntervalState {
    std::uint8_t *output;
    std::size_t count;
    std::size_t last_hi;
    std::int32_t last_value;
    bool has_last;
};

std::int32_t value_at(std::size_t index, std::int64_t step,
                      std::int64_t offset, std::int64_t divisor) noexcept {
    return static_cast<std::int32_t>((step * static_cast<std::int64_t>(index) + offset) / divisor);
}

void store_i32_le(std::uint8_t *output, std::size_t position, std::int32_t value) noexcept {
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[position + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

void append_interval(IntervalState &state, std::size_t lo, std::size_t hi,
                     std::int32_t value) noexcept {
    if (state.has_last && state.last_hi == lo && state.last_value == value) {
        store_i32_le(state.output, (state.count - 1) * 12 + 4, static_cast<std::int32_t>(hi));
    } else {
        const auto position = state.count * 12;
        store_i32_le(state.output, position, static_cast<std::int32_t>(lo));
        store_i32_le(state.output, position + 4, static_cast<std::int32_t>(hi));
        store_i32_le(state.output, position + 8, value);
        ++state.count;
    }
    state.last_hi = hi;
    state.last_value = value;
    state.has_last = true;
}

void visit_range(std::size_t lo, std::size_t hi, std::int64_t step,
                 std::int64_t offset, std::int64_t divisor, IntervalState &state) {
    const auto first = value_at(lo, step, offset, divisor);
    const auto last = value_at(hi - 1, step, offset, divisor);
    if (first == last || hi - lo == 1) {
        append_interval(state, lo, hi, first);
        return;
    }
    const auto mid = lo + (hi - lo) / 2;
    visit_range(lo, mid, step, offset, divisor, state);
    visit_range(mid, hi, step, offset, divisor, state);
}
}  // namespace

extern "C" std::int64_t constant_intervals(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length != 4) return -1;
    const auto n_value = input[0];
    const auto step = input[1];
    const auto offset = input[2];
    const auto divisor = input[3];
    if (n_value < 0 || n_value > static_cast<std::int64_t>(max_n)
        || step < 0 || step > 65535 || offset < 0 || offset > 65535
        || divisor < 1 || divisor > 65535) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto maximum_bytes = n * 12;
    if (output_capacity < maximum_bytes || (maximum_bytes > 0 && output == nullptr)) return -2;
    if (n == 0) return 0;
    IntervalState state{output, 0, 0, 0, false};
    visit_range(0, n, step, offset, divisor, state);
    return static_cast<std::int64_t>(state.count);
}
