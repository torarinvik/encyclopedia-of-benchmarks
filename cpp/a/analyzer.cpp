#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_events = 64;
constexpr std::int64_t max_epoch = 15;
constexpr std::int64_t max_address = 255;
}

extern "C" std::int64_t analyzer(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 1 || length > 1 + 3 * max_events + 1) return -1;
    const std::int64_t count_value = input[0];
    if (count_value < 0 || count_value > static_cast<std::int64_t>(max_events)) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != 1 + 3 * count) return -1;
    std::int64_t latest_writer[static_cast<std::size_t>(max_address) + 1];
    for (std::size_t address = 0; address <= static_cast<std::size_t>(max_address); ++address) latest_writer[address] = -1;
    std::int64_t conflicts = 0, previous_epoch = 0;
    for (std::size_t event = 0; event < count; ++event) {
        const std::size_t base = 1 + 3 * event;
        const auto epoch = input[base], opcode = input[base + 1], address_value = input[base + 2];
        if (epoch < previous_epoch || epoch < 0 || epoch > max_epoch
                || (opcode != 0 && opcode != 1) || address_value < 0 || address_value > max_address) return -1;
        previous_epoch = epoch;
        const auto address = static_cast<std::size_t>(address_value);
        if (opcode == 0) latest_writer[address] = static_cast<std::int64_t>(event);
        else {
            for (std::size_t prior = 0; prior < event; ++prior) {
                const std::size_t prior_base = 1 + 3 * prior;
                if (input[prior_base] < epoch && input[prior_base + 1] == 0
                        && input[prior_base + 2] == address_value
                        && latest_writer[address] == static_cast<std::int64_t>(prior)) ++conflicts;
            }
        }
    }
    return conflicts;
}
