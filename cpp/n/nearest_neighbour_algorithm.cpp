#include <cstddef>
#include <cstdint>
#include <string>
extern "C" std::int64_t nearest_neighbour_algorithm(const std::int64_t*v,std::size_t n,std::uint8_t*out,std::size_t cap){
 if(!v||n<2||n>257||v[0]<1||v[0]>16)return -1;std::size_t m=static_cast<std::size_t>(v[0]);if(n!=1+m*m)return -1;for(std::size_t i=1;i<n;i++)if(v[i]<0||v[i]>1000000)return -1;
 bool seen[16]={};std::size_t current=0;std::string result;for(std::size_t step=0;step<m;step++){seen[current]=true;if(step)result+=',';result+=std::to_string(current);if(step+1==m)break;std::size_t best=m;std::int64_t distance=0;for(std::size_t j=0;j<m;j++)if(!seen[j]){auto d=v[1+current*m+j];if(best==m||d<distance){best=j;distance=d;}}current=best;}
 if(result.size()>cap||(result.size()&&!out))return -2;for(std::size_t i=0;i<result.size();i++)out[i]=static_cast<std::uint8_t>(result[i]);return static_cast<std::int64_t>(result.size());
}
