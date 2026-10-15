#include <array>
#include <cstddef>
#include <cstdint>

extern "C" int64_t maximum_unique_subarray(const int64_t *values, size_t length) {
    if (length > 256 || (length != 0 && values == nullptr)) return -1;
    std::array<int64_t, 512> keys{};
    std::array<size_t, 512> last_seen{};
    std::array<bool, 512> occupied{};
    size_t left = 0;
    int64_t window_sum = 0;
    int64_t best = 0;
    for (size_t index = 0; index < length; ++index) {
        const int64_t value = values[index];
        if (value < 1 || value > 10000) return -1;
        size_t slot = static_cast<size_t>(value) % 512;
        while (occupied[slot] && keys[slot] != value) slot = (slot + 1) % 512;
        const size_t previous = last_seen[slot];
        while (left < previous) {
            window_sum -= values[left];
            ++left;
        }
        window_sum += value;
        keys[slot] = value;
        last_seen[slot] = index + 1;
        occupied[slot] = true;
        if (window_sum > best) best = window_sum;
    }
    return best;
}
