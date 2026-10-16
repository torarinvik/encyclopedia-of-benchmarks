#include <cstddef>
#include <cstdint>
namespace {
constexpr std::size_t max_input=1024,max_entries=512;
bool ws(std::uint8_t c){return (c>=9&&c<=13)||(c>=28&&c<=32);}
void put32(std::uint8_t*out,std::size_t&pos,std::uint32_t value){for(int i=0;i<4;i++){out[pos++]=static_cast<std::uint8_t>(value);value>>=8;}}
}
extern "C" std::int64_t word_occurrence(const std::int64_t*input,std::size_t length,std::uint8_t*output,std::size_t capacity){
 if(!input||length<1||length>max_input+1||input[0]<0||input[0]>max_input||length!=static_cast<std::size_t>(input[0])+1)return -1;
 const auto n=static_cast<std::size_t>(input[0]);std::uint8_t text[max_input];for(std::size_t i=0;i<n;i++){const auto v=input[i+1];if(v<0||v>127)return -1;text[i]=static_cast<std::uint8_t>(v);}
 std::size_t starts[max_entries],lens[max_entries],entries=0;std::uint32_t counts[max_entries]={};std::size_t i=0;
 while(i<n){while(i<n&&ws(text[i]))++i;if(i==n)break;const auto start=i;while(i<n&&!ws(text[i]))++i;const auto len=i-start;std::size_t j=0;for(;j<entries;j++){if(lens[j]!=len)continue;std::size_t q=0;for(;q<len&&text[starts[j]+q]==text[start+q];++q){}if(q==len)break;}if(j==entries){if(entries>=max_entries)return -1;starts[j]=start;lens[j]=len;counts[j]=0;++entries;}++counts[j];}
 std::size_t need=4;for(std::size_t j=0;j<entries;j++)need+=8+lens[j];if(!output||capacity<need)return -2;std::size_t pos=0;put32(output,pos,static_cast<std::uint32_t>(entries));for(std::size_t j=0;j<entries;j++){put32(output,pos,static_cast<std::uint32_t>(lens[j]));for(std::size_t q=0;q<lens[j];q++)output[pos++]=text[starts[j]+q];put32(output,pos,counts[j]);}return static_cast<std::int64_t>(pos);
}
