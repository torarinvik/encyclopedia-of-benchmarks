/* ASCII character and bigram entropy summary matching the pinned Python source. */
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>
namespace {constexpr std::size_t max_text=512, alphabet_size=128;int round_even(double v){double lo=std::floor(v),f=v-lo;if(f<0.5)return static_cast<int>(lo);if(f>0.5)return static_cast<int>(lo+1);int i=static_cast<int>(lo);return i%2==0?i:i+1;}std::size_t emit_line(std::uint8_t*out,std::size_t p,int v){if(v<0){out[p++]='-';v=-v;}if(v>=10)out[p++]=static_cast<std::uint8_t>('0'+v/10);out[p++]=static_cast<std::uint8_t>('0'+v%10);out[p++]='.';out[p++]='0';out[p++]='\n';return p;}}
extern "C" std::int64_t entropy(const std::int64_t*input,std::size_t length,std::uint8_t*output,std::size_t capacity) noexcept {
 if(input==nullptr||length<2||length>max_text+1)return -1;const auto n=input[0];if(n<1||n>static_cast<std::int64_t>(max_text)||length!=static_cast<std::size_t>(n)+1)return -1;
 std::uint32_t singles[alphabet_size]={},pairs[alphabet_size*alphabet_size]={};for(std::size_t i=0;i<static_cast<std::size_t>(n);++i){auto c=input[i+1];if(c<0||c>=128)return -1;++singles[c];}++pairs[32*alphabet_size+static_cast<std::size_t>(input[1])];for(std::size_t i=0;i+1<static_cast<std::size_t>(n);++i)++pairs[static_cast<std::size_t>(input[i+1])*alphabet_size+static_cast<std::size_t>(input[i+2])];
 constexpr int alpha[27]={32,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122};double s1=0,s2=0;for(int c:alpha){auto count=singles[c];if(count){double p=static_cast<double>(count)/n;s1+=p*std::log2(p);}}for(int a:alpha)for(int b:alpha){auto count=pairs[a*alphabet_size+b];if(count){double p=static_cast<double>(count)/n;s2+=p*std::log2(p);}}
 std::uint8_t temp[32];std::size_t pos=0;pos=emit_line(temp,pos,round_even(-s1));pos=emit_line(temp,pos,round_even(-s2));pos=emit_line(temp,pos,round_even((-s2)-(-s1)));if(output==nullptr||capacity<pos)return -2;std::memcpy(output,temp,pos);return static_cast<std::int64_t>(pos);
}
