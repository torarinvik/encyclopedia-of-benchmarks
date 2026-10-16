#include <cstddef>
#include <cstdint>
#include <string>
#include <vector>
extern "C" std::int64_t optimal_job_scheduling(const std::int64_t*v,std::size_t n,std::uint8_t*out,std::size_t cap){
 if(!v||n<4||n>194||v[0]<1||v[0]>16||v[1]<1||v[1]>8)return -1;std::size_t p=v[0],m=v[1];if(n!=2+p*m+m*m)return -1;std::vector<std::uint32_t> run(p*m),transfer(m*m);std::size_t at=2;
 for(auto&x:run){if(v[at]<0||v[at]>1000)return -1;x=static_cast<std::uint32_t>(v[at++]);}for(auto&x:transfer){if(v[at]<0||v[at]>1000)return -1;x=static_cast<std::uint32_t>(v[at++]);}
 std::vector<std::uint32_t> cost(p*m);for(std::size_t j=0;j<m;j++)cost[j]=run[j];for(std::size_t i=1;i<p;i++)for(std::size_t j=0;j<m;j++){std::uint32_t best=UINT32_MAX;for(std::size_t k=0;k<m;k++){auto x=cost[(i-1)*m+k]+transfer[k*m+j]+run[i*m+j];if(x<best)best=x;}cost[i*m+j]=best;}
 std::string s;for(std::size_t i=0;i<p;i++){for(std::size_t j=0;j<m;j++){if(j)s+=',';s+=std::to_string(cost[i*m+j]);}if(i+1<p)s+='\n';}if(s.size()>cap||(s.size()&&!out))return -2;for(std::size_t i=0;i<s.size();i++)out[i]=static_cast<std::uint8_t>(s[i]);return static_cast<std::int64_t>(s.size());
}
