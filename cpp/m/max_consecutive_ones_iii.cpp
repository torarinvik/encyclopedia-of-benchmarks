#include <cstddef>
#include <cstdint>
extern "C" int64_t max_consecutive_ones_iii(const int64_t* a,size_t len){if(!a||len<3||len>1026||a[0]<1||a[0]>1024||len!=static_cast<size_t>(a[0])+2||a[1]<0||a[1]>a[0])return -2;size_t n=static_cast<size_t>(a[0]),left=0,zeros=0,best=0;for(size_t i=0;i<n;i++)if(a[i+2]!=0&&a[i+2]!=1)return -2;for(size_t r=0;r<n;r++){if(a[r+2]==0)zeros++;while(zeros>static_cast<size_t>(a[1])){if(a[left+2]==0)zeros--;left++;}if(r-left+1>best)best=r-left+1;}return static_cast<int64_t>(best);}
