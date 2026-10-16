#include <cstddef>
#include <cstdint>
extern "C" std::int64_t palindromic_partitioning(const std::int64_t* v,std::size_t n) noexcept {
 if(!v||n<2||n>65||v[0]<1||v[0]>64||n!=std::size_t(v[0])+1)return -1;
 const auto m=std::size_t(v[0]);bool p[64][64]{};std::int64_t cuts[64]{};
 for(std::size_t end=0;end<m;end++){if(v[end+1]<0||v[end+1]>127)return -1;for(std::size_t start=0;start<=end;start++)p[start][end]=v[start+1]==v[end+1]&&(end-start<2||p[start+1][end-1]);}
 for(std::size_t end=0;end<m;end++){if(p[0][end])cuts[end]=0;else{cuts[end]=64;for(std::size_t start=1;start<=end;start++)if(p[start][end]&&cuts[start-1]+1<cuts[end])cuts[end]=cuts[start-1]+1;}}
 return cuts[m-1];
}
