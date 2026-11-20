#include <cstddef>
#include <cstdint>

extern "C" std::int64_t pisano_period(const std::int64_t* input,
                                      std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > 2) return -1;
    const auto modulus = input[0];
    if (length != 1 || modulus < 1 || modulus > 64) return -1;

    const auto initial_next = std::int64_t{1} % modulus;
    std::int64_t previous = 0;
    std::int64_t current = initial_next;
    for (std::int64_t period = 1; period <= 6 * modulus; ++period) {
        const auto next = (previous + current) % modulus;
        previous = current;
        current = next;
        if (previous == 0 && current == initial_next) return period;
    }
    return -1;
}
