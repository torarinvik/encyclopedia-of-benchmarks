#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_M=8, MAX_Q=8, MAX_N=16, MAX_LEN=147;
constexpr std::int64_t NO_SUCCESSOR=34;
}

extern "C" std::int64_t fractional_cascading_subset_chain(const std::int64_t* input,std::size_t length) {
    if(input==nullptr||length<2||length>MAX_LEN)return -1;
    if(input[0]<2||input[0]>static_cast<std::int64_t>(MAX_M)||input[1]<1||input[1]>static_cast<std::int64_t>(MAX_Q))return -1;
    const std::size_t m=static_cast<std::size_t>(input[0]),q=static_cast<std::size_t>(input[1]);
    std::int64_t catalogs[MAX_M][MAX_N]{};std::size_t sizes[MAX_M]{};std::int64_t queries[MAX_Q]{};std::size_t cursor=2;
    for(std::size_t i=0;i<m;i++){
        if(cursor>=length||input[cursor]<1||input[cursor]>static_cast<std::int64_t>(MAX_N))return -1;
        const std::size_t n=static_cast<std::size_t>(input[cursor++]);if(cursor+n>length)return -1;sizes[i]=n;
        for(std::size_t j=0;j<n;j++){const auto key=input[cursor++];if(key < -16||key>16||(j>0&&catalogs[i][j-1]>=key))return -1;catalogs[i][j]=key;}
        if(i>0){std::size_t p=0,c=0;while(p<sizes[i-1]&&c<n){if(catalogs[i-1][p]<catalogs[i][c])++p;else if(catalogs[i-1][p]==catalogs[i][c]){++p;++c;}else return -1;}if(c!=n)return -1;}
    }
    if(cursor+q!=length)return -1;
    for(std::size_t i=0;i<q;i++){queries[i]=input[cursor++];if(queries[i] < -17||queries[i]>17)return -1;}
    std::size_t bridge[MAX_M-1][MAX_N+1]{};
    for(std::size_t i=0;i+1<m;i++){std::size_t child=0;for(std::size_t slot=0;slot<sizes[i];slot++){while(child<sizes[i+1]&&catalogs[i+1][child]<catalogs[i][slot])++child;bridge[i][slot]=child;}bridge[i][sizes[i]]=sizes[i+1];}
    std::int64_t checksum=0;
    for(std::size_t qi=0;qi<q;qi++){
        std::size_t low=0,high=sizes[0];while(low<high){const auto mid=(low+high)/2;if(catalogs[0][mid]<queries[qi])low=mid+1;else high=mid;}std::size_t slot=low;
        for(std::size_t ci=0;ci<m;ci++){const std::int64_t code=slot<sizes[ci]?catalogs[ci][slot]+17:NO_SUCCESSOR;checksum+=static_cast<std::int64_t>(qi+1)*static_cast<std::int64_t>(ci+1)*code;if(ci+1<m)slot=bridge[ci][slot];}
    }
    return checksum;
}
