#include <array>
#include <cstddef>
#include <cstdint>

extern "C" int64_t indexed_deque(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (!input || length < 1 || length > 513 || input[0] < 1 || input[0] > 256) return -1;
    auto q = static_cast<size_t>(input[0]);
    if (length != 1 + 2*q) return -1;
    std::array<int64_t,256> items{}, answers{};
    size_t head=0, size=0, count=0;
    for (size_t i=0;i<q;++i) {
        auto op=input[1+2*i], arg=input[2+2*i];
        if (op==0 || op==1) {
            if (arg < -1000000 || arg > 1000000 || size==256) return -1;
            if (op==0) { head=(head+255)%256; items[head]=arg; }
            else items[(head+size)%256]=arg;
            ++size;
        } else if (op==2 || op==3) {
            if (arg!=0 || size==0) return -1;
            if (op==2) head=(head+1)%256;
            --size;
        } else if (op==4) {
            if (arg<0 || arg>=static_cast<int64_t>(size)) return -1;
            answers[count++]=items[(head+static_cast<size_t>(arg))%256];
        } else return -1;
    }
    if (!count) return -1;
    if (!output || capacity<8*count) return -2;
    for (size_t i=0;i<count;++i) {
        auto bits=static_cast<uint64_t>(answers[i]);
        for (size_t byte=0;byte<8;++byte) output[8*i+byte]=static_cast<uint8_t>(bits >> (8*byte));
    }
    return static_cast<int64_t>(8*count);
}
