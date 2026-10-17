#include <cstddef>
#include <cstdint>
static const int dr[8]={1,-1,1,-1,2,2,-2,-2},dc[8]={2,2,-2,-2,1,-1,1,-1};
static bool search(int b[25],int n,int r,int c,int step){if(step==n*n)return true;for(int k=0;k<8;k++){int nr=r+dr[k],nc=c+dc[k];if(nr>=0&&nr<n&&nc>=0&&nc<n&&b[nr*n+nc]==0){b[nr*n+nc]=step+1;if(search(b,n,nr,nc,step+1))return true;b[nr*n+nc]=0;}}return false;}
static void put(std::uint8_t*out,std::size_t off,std::int32_t x){auto b=static_cast<std::uint32_t>(x);for(int k=0;k<4;k++)out[off+k]=static_cast<std::uint8_t>(b>>(8*k));}
extern "C" std::int64_t open_knight_tour(const std::int64_t*v,std::size_t n,std::uint8_t*out,std::size_t cap){if(!v||n!=1||(v[0]!=1&&v[0]!=5))return -1;int d=(int)v[0],b[25]={0};if(!out||cap<(std::size_t)d*d*4)return -2;for(int r=0;r<d;r++)for(int c=0;c<d;c++){b[r*d+c]=1;if(search(b,d,r,c,1))goto done;b[r*d+c]=0;}done:for(int i=0;i<d*d;i++)put(out,(std::size_t)i*4,b[i]);return (std::int64_t)d*d*4;}
