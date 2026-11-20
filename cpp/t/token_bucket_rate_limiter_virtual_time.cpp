#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kMaxCapacity = 64;
constexpr std::int64_t kMaxRate = 32;
constexpr std::int64_t kMaxRequests = 63;
constexpr std::int64_t kMaxTicks = 256;
constexpr std::size_t kMaxInput = 66;
}

extern "C" std::int64_t token_bucket_rate_limiter_virtual_time(const std::int64_t* input,
                                                                 std::size_t length) noexcept {
    if (input == nullptr || length < 3 || length > kMaxInput) return -1;
    const std::int64_t capacity = input[0], rate = input[1], request_count = input[2];
    if (capacity < 0 || capacity > kMaxCapacity || rate < 0 || rate > kMaxRate ||
        request_count < 0 || request_count > kMaxRequests || length != 3 + static_cast<std::size_t>(request_count)) return -1;
    const auto q = static_cast<std::size_t>(request_count);
    for (std::size_t i = 0; i < q; ++i)
        if (input[3 + i] < 0 || input[3 + i] > kMaxTicks) return -1;

    std::int64_t tokens = capacity;
    std::uint64_t allowed = 0;
    for (std::size_t i = 0; i < q; ++i) {
        tokens += input[3 + i] * rate;
        if (tokens > capacity) tokens = capacity;
        if (tokens > 0) {
            allowed |= std::uint64_t{1} << i;
            --tokens;
        }
    }
    return static_cast<std::int64_t>(allowed);
}
