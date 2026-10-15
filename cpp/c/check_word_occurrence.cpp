#include <cstddef>
#include <cstdint>
namespace {
constexpr std::size_t max_input=1024,max_entries=1025;
bool ws(std::uint8_t c){return (c>=9&&c<=13)||c==32;}
std::uint8_t lower_ascii(std::uint8_t c){return c>='A'&&c<='Z'?static_cast<std::uint8_t>(c+('a'-'A')):c;}
bool forbidden(const std::uint8_t*s,std::size_t n){const char*names[]={"constructor","tostring","tolocalestring","valueof","hasownproperty","isprototypeof","propertyisenumerable"};const std::size_t lens[]={11,8,14,7,14,13,20};for(std::size_t x=0;x<7;++x){if(n!=lens[x])continue;std::size_t i=0;for(;i<n;++i)if(lower_ascii(s[i])!=static_cast<std::uint8_t>(names[x][i]))break;if(i==n)return true;}return false;}
void put32(std::uint8_t*out,std::size_t&pos,std::uint32_t x){for(int i=0;i<4;++i){out[pos++]=static_cast<std::uint8_t>(x);x>>=8;}}
}
extern "C" std::int64_t check_word_occurrence(const std::int64_t*input,std::size_t length,std::uint8_t*output,std::size_t capacity) noexcept {
 if(!input||length<2||input[0]<0||input[0]>1||input[1]<0||input[1]>1024||length!=static_cast<std::size_t>(input[1])+2)return -1;
 const auto n=static_cast<std::size_t>(input[1]);std::uint8_t text[max_input];for(std::size_t i=0;i<n;++i){auto v=input[i+2];if(v<0||v>127)return -1;auto c=static_cast<std::uint8_t>(v);if(!((c>='A'&&c<='Z')||(c>='a'&&c<='z')||ws(c)))return -1;text[i]=input[0]?lower_ascii(c):c;}
 std::size_t starts[max_entries],lens[max_entries],entries=0;std::uint32_t counts[max_entries]={};std::size_t i=0,start=0;
 for(;;){if(i==n||ws(text[i])){const auto len=i-start;if(forbidden(text+start,len))return -1;std::size_t j=0;for(;j<entries;++j)if(lens[j]==len){std::size_t q=0;for(;q<len&&text[starts[j]+q]==text[start+q];++q){}if(q==len)break;}if(j==entries){starts[j]=start;lens[j]=len;counts[j]=0;++entries;}++counts[j];if(i==n)break;while(i<n&&ws(text[i]))++i;start=i;}else ++i;}
 std::size_t need=4;for(std::size_t j=0;j<entries;++j)need+=8+lens[j];if(capacity<need||!output)return -2;std::size_t pos=0;put32(output,pos,static_cast<std::uint32_t>(entries));for(std::size_t j=0;j<entries;++j){put32(output,pos,static_cast<std::uint32_t>(lens[j]));for(std::size_t q=0;q<lens[j];++q)output[pos++]=text[starts[j]+q];put32(output,pos,counts[j]);}return static_cast<std::int64_t>(pos);
}
