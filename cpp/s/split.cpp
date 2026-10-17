#include <cstddef>
#include <cstdint>
namespace { constexpr std::size_t max_text=256,max_input=max_text+2; }
extern "C" std::int64_t split(const std::int64_t* input,std::size_t length,std::uint8_t* output,std::size_t capacity){
 if(input==nullptr||length<2||length>max_input+1||input[0]<0||input[0]>static_cast<std::int64_t>(max_text)||input[1]<0||input[1]>127)return -1;
 const auto n=static_cast<std::size_t>(input[0]);if(length!=n+2)return -1;
 for(std::size_t i=0;i<n;++i)if(input[i+2]<0||input[i+2]>127)return -1;
 if(n>0&&input[n+1]==input[1])return -1;
 std::size_t separators=0;for(std::size_t i=0;i<n;++i)if(input[i+2]==input[1])++separators;if(n>0&&separators==0)return -1;
 const auto count=separators+1,required=2+2*count+n-separators;if(output==nullptr||capacity<required)return -2;
 output[0]=static_cast<std::uint8_t>(count);output[1]=static_cast<std::uint8_t>(count>>8);std::size_t pos=2,start=0;
 for(std::size_t i=0;i<=n;++i)if(i==n||input[i+2]==input[1]){const auto field=i-start;output[pos++]=static_cast<std::uint8_t>(field);output[pos++]=static_cast<std::uint8_t>(field>>8);for(std::size_t j=start;j<i;++j)output[pos++]=static_cast<std::uint8_t>(input[j+2]);start=i+1;}
 return static_cast<std::int64_t>(required);
}
