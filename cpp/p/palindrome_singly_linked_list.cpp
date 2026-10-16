#include <cstddef>
#include <cstdint>
#include <climits>
extern "C" std::int64_t palindrome_singly_linked_list(const std::int64_t*v,std::size_t n) noexcept {if(!v||n<1||n>65||v[0]<0||v[0]>64||n!=std::size_t(v[0])+1)return -1;auto len=std::size_t(v[0]);for(std::size_t i=1;i<n;i++)if(v[i]<INT32_MIN||v[i]>INT32_MAX)return -1;std::size_t slow=0,fast=0;while(fast+1<len){++slow;fast+=2;}auto suffix=len-slow;for(std::size_t i=0;i<suffix;i++)if(v[i+1]!=v[len-i])return 0;return 1;}
