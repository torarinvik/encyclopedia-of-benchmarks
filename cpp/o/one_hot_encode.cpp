#include <cstddef>
#include <cstdint>
extern "C" std::int64_t one_hot_encode(const std::int64_t*v,std::size_t n,std::uint8_t*out,std::size_t cap){
 if(!v||n<2||n>33||v[0]<1||v[0]>32||n!=static_cast<std::size_t>(v[0])+1)return -1;std::size_t rows=static_cast<std::size_t>(v[0]);bool present[26]={};for(std::size_t i=0;i<rows;i++){if(v[i+1]<0||v[i+1]>25)return -1;present[v[i+1]]=true;}
 std::size_t map[26],cols=0;for(std::size_t i=0;i<26;i++)if(present[i])map[i]=cols++;std::size_t need=rows*cols;if(need>cap||(need&&!out))return -2;for(std::size_t r=0;r<rows;r++)for(std::size_t c=0;c<cols;c++)out[r*cols+c]=static_cast<std::uint8_t>(map[v[r+1]]==c);return static_cast<std::int64_t>(need);
}
