#include <cstddef>
#include <cstdint>
namespace { constexpr std::size_t MAX_LENGTH=1024; bool space(std::int64_t c){return c==9||c==10||c==11||c==12||c==13||c==32;} }
extern "C" std::int64_t validate_email(const std::int64_t *v,std::size_t n){
    if(!v||n<2||n>MAX_LENGTH+1||v[0]<1||v[0]>MAX_LENGTH||std::size_t(v[0])+1!=n)return -1;
    std::size_t end=std::size_t(v[0]);for(std::size_t i=0;i<end;++i)if(v[i+1]<0||v[i+1]>127)return -1;
    std::size_t at=end;for(std::size_t i=0;i<end;++i){auto c=v[i+1];if(space(c))return 0;if(c=='@'){if(at!=end)return 0;at=i;}}
    if(at==0||at>=end-1)return 0;bool dot=false;for(std::size_t i=at+2;i+1<end;++i)if(v[i+1]=='.')dot=true;return dot?1:0;
}
