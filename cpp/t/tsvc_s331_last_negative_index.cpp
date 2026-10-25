#include <cstddef>
#include <cstdint>
extern "C" int64_t tsvc_s331_last_negative_index(const int64_t *input, size_t length) {
    if (!input || length < 2 || length > 257 || input[0] < 1 || input[0] > 256 || length != 1 + static_cast<size_t>(input[0])) return -1;
    int64_t result=0;
    for(size_t i=0;i<static_cast<size_t>(input[0]);++i){const int64_t x=input[1+i];if(x < -1000000 || x > 1000000)return -1;if(x<0)result=static_cast<int64_t>(i)+1;}
    return result;
}
