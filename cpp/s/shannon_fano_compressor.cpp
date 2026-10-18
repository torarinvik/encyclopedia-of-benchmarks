#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text = 16, max_symbols = 16, max_code = 15, max_output = 514;
using Codes = std::array<std::array<std::uint8_t, max_code>, 128>;
using Lengths = std::array<std::uint8_t, 128>;
bool make_codes(const std::uint8_t* symbols, std::size_t count, const std::array<double,128>& freq,
                std::array<std::uint8_t,max_code>& prefix, std::size_t depth, Codes& codes, Lengths& lengths) {
    if (count == 1) { for (std::size_t i=0;i<depth;++i) codes[symbols[0]][i]=prefix[i]; lengths[symbols[0]]=static_cast<std::uint8_t>(depth); return true; }
    double total=0.0; for(std::size_t i=0;i<count;++i) total+=freq[symbols[i]];
    const double capacity=0.5*total; double running=0.0;
    std::array<std::uint8_t,max_symbols> left{}, right{}; std::size_t nl=0,nr=0;
    for(std::size_t i=0;i<count;++i){auto s=symbols[i]; if(running+freq[s]<=capacity){left[nl++]=s;running+=freq[s];}else right[nr++]=s;}
    if(nl==0||nr==0||depth>=max_code)return false;
    prefix[depth]='0'; if(!make_codes(left.data(),nl,freq,prefix,depth+1,codes,lengths))return false;
    prefix[depth]='1'; return make_codes(right.data(),nr,freq,prefix,depth+1,codes,lengths);
}
}
extern "C" std::int64_t shannon_fano_compressor(const std::int64_t* input,std::size_t input_length,std::uint8_t* output,std::size_t capacity){
    if(input_length>18||(input==nullptr?input_length!=0:input_length==0))return -1;
    std::size_t text_len=0;if(input){if(input[0]<0||input[0]>16)return -1;text_len=static_cast<std::size_t>(input[0]);if(input_length!=text_len+1)return -1;}
    std::array<std::uint8_t,16> text{};std::array<std::uint8_t,16> symbols{};std::array<std::size_t,128> counts{};std::array<bool,128> seen{};std::size_t ns=0;
    for(std::size_t i=0;i<text_len;++i){auto v=input[i+1];if(v<0||v>127)return -1;text[i]=static_cast<std::uint8_t>(v);if(!seen[text[i]]){seen[text[i]]=true;symbols[ns++]=text[i];}++counts[text[i]];}
    std::array<double,128> freq{};if(text_len)for(std::size_t s=0;s<128;++s)freq[s]=(1.0*static_cast<double>(counts[s]))/static_cast<double>(text_len);
    Codes codes{};Lengths lengths{};if(ns==1){codes[symbols[0]][0]='1';lengths[symbols[0]]=1;}else if(ns>1){std::array<std::uint8_t,max_code> prefix{};if(!make_codes(symbols.data(),ns,freq,prefix,0,codes,lengths))return -1;}
    std::array<std::uint8_t,max_output> staged{};std::size_t n=0,cl=0;for(std::size_t i=0;i<text_len;++i)cl+=lengths[text[i]];staged[n++]=static_cast<std::uint8_t>(cl);
    for(std::size_t i=0;i<text_len;++i)for(std::size_t j=0;j<lengths[text[i]];++j)staged[n++]=codes[text[i]][j];
    staged[n++]=static_cast<std::uint8_t>(ns);for(std::size_t s=0;s<128;++s)if(lengths[s]){staged[n++]=static_cast<std::uint8_t>(s);staged[n++]=lengths[s];for(std::size_t j=0;j<lengths[s];++j)staged[n++]=codes[s][j];}
    if(!output||capacity<n)return -2;for(std::size_t i=0;i<n;++i)output[i]=staged[i];return static_cast<std::int64_t>(n);
}
