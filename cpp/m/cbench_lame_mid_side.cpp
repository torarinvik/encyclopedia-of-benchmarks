#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" int64_t cbench_lame_mid_side(const double *input, size_t n, double *output, size_t cap) {
    if (!input || n < 1 || n > 66) return -1;
    for (size_t i=0;i<n;++i) if (!std::isfinite(input[i])) return -1;
    if (input[0] < 1.0 || input[0] > 32.0 || std::trunc(input[0]) != input[0]) return -1;
    const size_t count=static_cast<size_t>(input[0]);
    if (n != 1 + 2*count) return -1;
    for (size_t i=1;i<n;++i) if (input[i] < -16.0 || input[i] > 16.0) return -1;
    double staged[64]; const double factor=1.414213562373095048801688724209698079 * 0.5;
    for (size_t i=0;i<count;++i) {
        const double left=input[1+i], right=input[1+count+i];
        staged[2*i]=(left+right)*factor;
        staged[2*i+1]=(left-right)*factor;
    }
    const size_t needed=2*count;
    if (!output || cap<needed) return -2;
    for(size_t i=0;i<needed;++i) output[i]=staged[i];
    return static_cast<int64_t>(needed);
}
