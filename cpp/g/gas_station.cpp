/* Return a zero-based station index that completes the circuit, or -1. */
#include <cstddef>
#include <cstdint>
extern "C" std::int64_t gas_station(const std::int64_t *input, std::size_t length) noexcept {
    if (!input || length<1 || input[0]<0 || input[0]>128) return -2;
    const auto n=static_cast<std::size_t>(input[0]);
    if (length!=2*n+1) return -2;
    for (std::size_t i=0;i<2*n;++i) if (input[i+1]<0 || input[i+1]>1000000) return -2;
    std::int64_t total=0, current=0; std::size_t start=0;
    for (std::size_t i=0;i<n;++i) {
        const auto net=input[1+i]-input[1+n+i]; total+=net; current+=net;
        if (current<0) { start=i+1; current=0; }
    }
    if (total<0) return -1;
    return static_cast<std::int64_t>(start);
}
