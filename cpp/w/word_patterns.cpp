#include <cstddef>
#include <cstdint>
#include <array>

extern "C" int64_t word_patterns(const int64_t* input, size_t length, uint8_t* output, size_t capacity) {
    if (!input || length < 1 || input[0] < 0 || input[0] > 256 || length != static_cast<size_t>(input[0]) + 1) return -1;
    size_t n = static_cast<size_t>(input[0]);
    std::array<int,128> first; first.fill(-1); size_t pos=0; int next=0;
    for (size_t i=0;i<n;++i) { int ch=static_cast<int>(input[i+1]); if(ch<0||ch>127)return -1; if(ch>='a'&&ch<='z')ch-=32; if(first[ch]<0)first[ch]=next++; }
    if(!output||capacity<4*n+1)return -2; pos=0;
    for(size_t i=0;i<n;++i){int ch=static_cast<int>(input[i+1]);if(ch>='a'&&ch<='z')ch-=32; if(i)output[pos++]='.'; char digits[3]; int count=0,value=first[ch]; do{digits[count++]=static_cast<char>('0'+value%10);value/=10;}while(value); while(count)output[pos++]=static_cast<uint8_t>(digits[--count]); }
    output[pos]=0; return static_cast<int64_t>(pos);
}
