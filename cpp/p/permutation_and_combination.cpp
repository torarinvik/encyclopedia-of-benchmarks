#include <cstddef>
#include <cstdint>
extern "C" std::int64_t permutation_and_combination(const std::int64_t*v,std::size_t n) noexcept {if(!v||n!=3)return -1;auto op=v[0],a=v[1],r=v[2];if(op<0||op>2||a<0||a>18)return -1;if(op==0){}else if(r<0||r>a)return -1;std::int64_t result=1;if(op==0){for(auto i=2;i<=a;i++)result*=i;}else if(op==1){for(auto i=a-r+1;i<=a;i++)result*=i;}else{auto k=r;if(k>a-k)k=a-k;for(auto i=1;i<=k;i++)result=result*(a-k+i)/i;}return result;}
