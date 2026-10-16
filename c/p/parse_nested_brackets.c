#include <stddef.h>
#include <stdint.h>
static void scan(const unsigned char*s,size_t lo,size_t hi,uint64_t*h){size_t depth=0,begin=0;for(size_t i=lo;i<hi;i++){if(s[i]=='<'){if(depth==0)begin=i;depth++;}else if(s[i]=='>'){depth--;if(depth==0){for(size_t j=begin;j<=i;j++)*h=(*h*257u+(uint64_t)s[j]+1u)%1000000007u;scan(s,begin+1,i,h);}}}}
int64_t parse_nested_brackets(const int64_t*v,size_t n){if(!v||n<1||n>129||v[0]<0||v[0]>128||n!=(size_t)v[0]+1)return -1;unsigned char s[128];size_t len=(size_t)v[0],d=0;for(size_t i=0;i<len;i++){if(v[i+1]<0||v[i+1]>127)return -1;s[i]=(unsigned char)v[i+1];if(s[i]=='<')d++;else if(s[i]=='>'){if(d==0)return -1;d--;}}if(d)return -1;uint64_t h=0;scan(s,0,len,&h);return (int64_t)h;}
