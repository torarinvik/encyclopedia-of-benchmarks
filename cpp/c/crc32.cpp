#include <cstddef>
#include <cstdint>
extern "C" std::int64_t crc32(const std::int64_t *values, std::size_t length) {
    if (length > 100001 || (length != 0 && values == nullptr)) return -1;
    std::int64_t crc = INT64_C(4294967295);
    for (std::size_t i=0; i<length; ++i) {
        const auto byte=values[i]; if(byte<0||byte>255)return -1; crc^=byte;
        for(int bit=0;bit<8;++bit) crc=(crc&1)!=0?(crc>>1)^INT64_C(3988292384):crc>>1;
    }
    return crc^INT64_C(4294967295);
}
