#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N=3, MAX_L=4, MAX_INPUT=20, MAX_OUTPUT=48, MAX_UPDATES=6;
constexpr std::int64_t SCALE=46656;
std::int64_t gcd64(std::int64_t a,std::int64_t b){while(b){auto r=a%b;a=b;b=r;}return a;}
void put64(std::uint8_t* out,std::size_t p,std::int64_t v){auto bits=static_cast<std::uint64_t>(v);for(std::size_t b=0;b<8;++b)out[p+b]=static_cast<std::uint8_t>(bits>>(8U*b));}

bool update(std::size_t s,std::size_t n,std::size_t l,const std::int64_t cap[MAX_L],
    const bool path[MAX_N][MAX_L],std::int64_t rate[MAX_N]){
    auto best=INT64_MAX;std::size_t bottleneck=l;
    for(std::size_t e=0;e<l;++e){if(!path[s][e])continue;std::int64_t fixed=0;std::size_t active=1;
        for(std::size_t j=0;j<n;++j)if(j!=s&&path[j][e]){if(rate[j]<=rate[s])fixed+=rate[j];else++active;}
        auto level=rate[s];std::int64_t candidate=level;
        for(std::size_t pass=0;pass<n;++pass){auto numerator=cap[e]*SCALE-fixed;if(numerator<0||numerator%static_cast<std::int64_t>(active)!=0)return false;
            candidate=numerator/static_cast<std::int64_t>(active);if(candidate<level)return false;
            auto next=INT64_MAX;for(std::size_t j=0;j<n;++j)if(j!=s&&path[j][e]&&rate[j]>level&&rate[j]<next)next=rate[j];
            if(next==INT64_MAX||candidate<=next)break;
            std::size_t count=0;for(std::size_t j=0;j<n;++j)if(j!=s&&path[j][e]&&rate[j]==next)++count;
            fixed+=static_cast<std::int64_t>(count)*next;active-=count;level=next;
        }
        if(candidate<best){best=candidate;bottleneck=e;}
    }
    if(bottleneck==l)return false;rate[s]=best;
    for(std::size_t j=0;j<n;++j)if(j!=s&&path[j][bottleneck]&&rate[j]>best)rate[j]=best;
    return true;
}

std::size_t choose(std::size_t mode,std::size_t step,std::size_t n,std::size_t l,
    const std::int64_t cap[MAX_L],const bool path[MAX_N][MAX_L],const std::int64_t rate[MAX_N]){
    if(mode==0)return step%n;
    if(mode==1){std::size_t best=0;for(std::size_t s=1;s<n;++s)if(rate[s]<rate[best])best=s;return best;}
    if(mode==2){for(std::size_t s=0;s<n;++s){bool local=true;for(std::size_t j=0;j<n&&local;++j)if(j!=s){bool shares=false;for(std::size_t e=0;e<l;++e)if(path[s][e]&&path[j][e])shares=true;if(shares&&(rate[j]<rate[s]||(rate[j]==rate[s]&&j<s)))local=false;}if(local)return s;}return 0;}
    std::size_t selected=l;std::int64_t load_best=0;
    for(std::size_t e=0;e<l;++e){std::int64_t load=0;bool used=false;for(std::size_t s=0;s<n;++s)if(path[s][e]){load+=rate[s];used=true;}if(used&&(selected==l||load*cap[selected]>load_best*cap[e])){selected=e;load_best=load;}}
    for(std::size_t s=0;s<n;++s)if(path[s][selected])return s;return 0;
}
}

extern "C" std::int64_t optimistic_flow_control_updates(const std::int64_t* input,std::size_t length,
    std::uint8_t* output,std::size_t capacity) noexcept{
    if(input==nullptr||length<7||length>MAX_INPUT)return -1;
    auto n64=input[0],l64=input[1],mode64=input[2],q64=input[3];
    if(n64<2||n64>MAX_N||l64<1||l64>MAX_L||mode64<0||mode64>3||q64<1||q64>MAX_UPDATES)return -1;
    auto n=static_cast<std::size_t>(n64),l=static_cast<std::size_t>(l64),mode=static_cast<std::size_t>(mode64),q=static_cast<std::size_t>(q64);
    if(length!=4+l+n*l)return -1;
    std::int64_t cap[MAX_L]{};bool path[MAX_N][MAX_L]{};std::int64_t rate[MAX_N]{};
    for(std::size_t e=0;e<l;++e){cap[e]=input[4+e];if(cap[e]<1||cap[e]>16)return -1;}
    for(std::size_t s=0;s<n;++s){bool used=false;for(std::size_t e=0;e<l;++e){auto v=input[4+l+s*l+e];if(v!=0&&v!=1)return -1;path[s][e]=v==1;used=used||v==1;}if(!used)return -1;}
    auto bytes=16*n;if(output==nullptr||capacity<bytes)return -2;
    for(std::size_t step=0;step<q;++step)if(!update(choose(mode,step,n,l,cap,path,rate),n,l,cap,path,rate))return -1;
    std::uint8_t staged[MAX_OUTPUT]{};
    for(std::size_t s=0;s<n;++s){auto g=gcd64(rate[s],SCALE);put64(staged,16*s,rate[s]/g);put64(staged,16*s+8,SCALE/g);}
    for(std::size_t b=0;b<bytes;++b)output[b]=staged[b];return static_cast<std::int64_t>(bytes);
}
