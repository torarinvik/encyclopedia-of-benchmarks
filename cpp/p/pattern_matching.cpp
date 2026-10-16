#include <cstddef>
#include <cstdint>
extern "C" std::int64_t pattern_matching(const std::int64_t*v,std::size_t n) noexcept {if(!v||n<3||n>130||v[0]<0||v[0]>64)return -1;auto t=std::size_t(v[0]),pp=t+1;if(n<pp+1||v[pp]<1||v[pp]>64)return -1;auto p=std::size_t(v[pp]);if(n!=pp+p+1||p>t)return -1;for(std::size_t i=0;i<t;i++)if(v[i+1]<0||v[i+1]>127)return -1;for(std::size_t j=0;j<p;j++)if(v[pp+1+j]<0||v[pp+1+j]>127)return -1;for(std::size_t i=0;i<=t-p;i++){std::size_t j=0;for(;j<p;j++)if(v[i+1+j]!=v[pp+1+j])break;if(j==p)return std::int64_t(i);}return -1;}
