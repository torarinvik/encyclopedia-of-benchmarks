#include <cstddef>
#include <cstdint>

static uint32_t upper_ascii(uint32_t c) { return c >= 'a' && c <= 'z' ? c - 32u : c; }
extern "C" int64_t cbench_ispell_hash(const int64_t *values, size_t length) {
    if (values == nullptr || length == 0 || length > 65) return -1;
    const int64_t table_size = values[0];
    if (table_size < 1 || table_size > INT64_C(2147483647)) return -1;
    const size_t count = length - 1;
    for (size_t i=0; i<count; ++i) if (values[i+1] < 1 || values[i+1] > 127) return -1;
    uint32_t h=0; const size_t initial=count<4?count:4;
    for(size_t i=0;i<initial;++i) h=(h<<8)|upper_ascii((uint32_t)values[i+1]);
    for(size_t i=initial;i<count;++i){ h=(h<<5)|(h>>27); h^=upper_ascii((uint32_t)values[i+1]); }
    return (int64_t)((uint64_t)h%(uint64_t)table_size);
}
