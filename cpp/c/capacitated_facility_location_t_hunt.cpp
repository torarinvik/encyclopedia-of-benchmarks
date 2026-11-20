#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t MAX_N=4, MAX_F=3, MAX_Q=4, MAX_P=7;
constexpr std::int64_t NEG_INF=std::numeric_limits<std::int64_t>::min()/4;
void put(std::uint8_t* out,std::size_t at,std::int64_t value){auto bits=static_cast<std::uint64_t>(value);for(std::size_t b=0;b<8;++b){out[at+b]=static_cast<std::uint8_t>(bits&255U);bits>>=8;}}
}

extern "C" std::int64_t capacitated_facility_location_t_hunt(const std::int64_t* in,std::size_t len,std::uint8_t* out,std::size_t cap){
    if(!in||len<4||len>68)return -1;
    auto nr=in[0],fr=in[1],qr=in[2],tr=in[3];
    if(nr<1||nr>4||fr<1||fr>3||qr<1||qr>4||tr<0||tr>=fr)return -1;
    auto n=static_cast<std::size_t>(nr),f=static_cast<std::size_t>(fr),q=static_cast<std::size_t>(qr),target=static_cast<std::size_t>(tr),p=n+f;
    if(len!=4+p*p+2*f+q+n)return -1;
    std::array<std::array<std::int64_t,MAX_P>,MAX_P> d{};
    std::array<std::int64_t,MAX_F> fee{},capacity{};
    std::array<std::size_t,MAX_Q> type{};
    std::array<std::size_t,MAX_N> assignment{};
    std::size_t at=4;
    for(std::size_t i=0;i<p;++i)for(std::size_t j=0;j<p;++j){auto x=in[at++];if(x<0||x>1000)return -1;d[i][j]=x;}
    for(std::size_t i=0;i<p;++i){if(d[i][i]!=0)return -1;for(std::size_t j=0;j<p;++j){if(i!=j&&d[i][j]==0)return -1;if(d[i][j]!=d[j][i])return -1;for(std::size_t k=0;k<p;++k)if(d[i][j]>d[i][k]+d[k][j])return -1;}}
    for(std::size_t i=0;i<f;++i){fee[i]=in[at++];if(fee[i]<0||fee[i]>1000)return -1;}
    for(std::size_t i=0;i<f;++i){capacity[i]=in[at++];if(capacity[i]<1||capacity[i]>nr)return -1;}
    for(std::size_t i=0;i<q;++i){if(in[at]<0||in[at]>=fr)return -1;type[i]=static_cast<std::size_t>(in[at++]);}
    for(std::size_t i=0;i<n;++i){if(in[at]<0||in[at]>=qr)return -1;assignment[i]=static_cast<std::size_t>(in[at++]);}
    std::array<std::int64_t,MAX_Q> weight{},profit{};std::int64_t old=0;
    for(std::size_t c=0;c<q;++c){profit[c]=fee[type[c]];old+=fee[type[c]];}
    for(std::size_t u=0;u<n;++u){auto c=assignment[u],t=type[c];if(++weight[c]>capacity[t])return -1;auto before=d[u][n+t],after=d[u][n+target];old+=before;profit[c]-=after-before;}
    std::array<std::int64_t,5> result{0,0,0,old,old};
    for(std::size_t copies=1;copies<=n;++copies){auto limit=std::min(n,copies*static_cast<std::size_t>(capacity[target]));std::array<std::int64_t,MAX_N+1> dp{},next{};std::array<std::uint32_t,MAX_N+1> masks{},next_masks{};dp.fill(NEG_INF);dp[0]=0;
        for(std::size_t item=0;item<q;++item){next=dp;next_masks=masks;auto iw=static_cast<std::size_t>(weight[item]);if(iw<=limit)for(std::size_t w=0;w+iw<=limit;++w)if(dp[w]!=NEG_INF){auto nw=w+iw,value=dp[w]+profit[item];auto mask=masks[w]|(UINT32_C(1)<<item);if(value>next[nw]||(value==next[nw]&&mask<next_masks[nw])){next[nw]=value;next_masks[nw]=mask;}}dp=next;masks=next_masks;}
        auto best=NEG_INF;std::uint32_t best_mask=0;for(std::size_t w=0;w<=limit;++w)if(dp[w]>best||(dp[w]==best&&masks[w]<best_mask)){best=dp[w];best_mask=masks[w];}
        if(best>static_cast<std::int64_t>(copies)*fee[target]){result={1,static_cast<std::int64_t>(copies),best_mask,old,old+static_cast<std::int64_t>(copies)*fee[target]-best};break;}
    }
    if(!out||cap<40)return -2;for(std::size_t i=0;i<5;++i)put(out,8*i,result[i]);return 40;
}
