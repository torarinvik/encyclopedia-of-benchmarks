#include <cstddef>
#include <cstdint>
#include <numeric>
extern "C" std::int64_t linear_diophantine_eqn(const std::int64_t*v,std::size_t n){if(!v||n!=3||v[0]<-100000||v[0]>100000||v[1]==0||v[1]<-100000||v[1]>100000||v[2]<-1000000||v[2]>1000000)return -1;return v[2]%std::gcd(v[0],v[1])==0?1:0;}
