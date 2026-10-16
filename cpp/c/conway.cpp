/* Generate the next look-and-say string from bounded ASCII input. */
#include <cstddef>
#include <cstdint>
namespace { constexpr std::size_t max_text_length=128; std::size_t decimal_digits(std::size_t v){std::size_t n=1;while(v>=10){v/=10;++n;}return n;} }
extern "C" std::int64_t conway(const std::int64_t* input,std::size_t length,std::uint8_t* output,std::size_t capacity) noexcept {
 if(input==nullptr||length<2||length>max_text_length+1)return -1;const auto n=input[0];if(n<1||n>static_cast<std::int64_t>(max_text_length)||length!=static_cast<std::size_t>(n)+1)return -1;
 for(std::size_t i=0;i<static_cast<std::size_t>(n);++i)if(input[i+1]<0||input[i+1]>127)return -1;
 std::size_t needed=0;for(std::size_t i=0;i<static_cast<std::size_t>(n);){std::size_t j=i+1;while(j<static_cast<std::size_t>(n)&&(input[j] == input[j+1] || input[j] == 10 || input[j] == 13))++j;needed+=decimal_digits(j-i)+1;i=j;}
 if(output==nullptr||capacity<needed)return -2;std::size_t pos=0;
 for(std::size_t i=0;i<static_cast<std::size_t>(n);){std::size_t j=i+1;while(j<static_cast<std::size_t>(n)&&(input[j] == input[j+1] || input[j] == 10 || input[j] == 13))++j;std::size_t run=j-i,start=pos;do{output[pos++]=static_cast<std::uint8_t>('0'+run%10);run/=10;}while(run);for(std::size_t a=start,b=pos-1;a<b;++a,--b){auto t=output[a];output[a]=output[b];output[b]=t;}output[pos++]=static_cast<std::uint8_t>(input[i+1]);i=j;}return static_cast<std::int64_t>(pos);
}
