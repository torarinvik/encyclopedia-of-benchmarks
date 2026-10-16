#include <cstddef>
#include <cstdint>
extern "C" std::int64_t ngram(const std::int64_t *v,std::size_t n,std::uint8_t *out,std::size_t cap){
 if(!v||n<2||n>258||v[0]<1||v[0]>16||v[1]<0||v[1]>256||n!=static_cast<std::size_t>(v[1])+2)return -1;
 const auto width=static_cast<std::size_t>(v[0]),text=static_cast<std::size_t>(v[1]);for(std::size_t i=0;i<text;i++)if(v[i+2]<32||v[i+2]>126)return -1;
 const auto grams=text>=width?text-width+1:0;const auto bytes=grams?grams*width+grams-1:0;if(bytes>cap||(bytes>0&&!out))return -2;
 std::size_t w=0;for(std::size_t i=0;i<grams;i++){if(i)out[w++]='\n';for(std::size_t j=0;j<width;j++)out[w++]=static_cast<std::uint8_t>(v[i+j+2]);}return static_cast<std::int64_t>(w);
}
