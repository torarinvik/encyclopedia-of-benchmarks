#include <cstddef>
#include <cstdint>
#include <cstring>
#include <array>
static void reverse_points(int64_t *o,size_t s,size_t n){for(size_t i=0;i<n/2;i++){size_t a=s+2*i,b=s+2*(n-1-i);auto x=o[a],y=o[a+1];o[a]=o[b];o[a+1]=o[b+1];o[b]=x;o[b+1]=y;}}
static size_t curve(int64_t x,int64_t y,int64_t side,int level,int angle,int64_t*o,size_t off){int64_t q=side/4;int64_t p[4][2]={{x+q,y+q},{x-q,y+q},{x-q,y-q},{x+q,y-q}},r[4][2];angle=(angle%4+4)%4;for(int i=0;i<4;i++){r[i][0]=p[(i+angle)%4][0];r[i][1]=p[(i+angle)%4][1];}if(level==1){for(int i=0;i<4;i++){o[off+2*i]=r[i][0];o[off+2*i+1]=r[i][1];}return 4;}auto h=side/2;size_t n=curve(r[0][0],r[0][1],h,level-1,angle+1,o,off);reverse_points(o,off,n);size_t n1=curve(r[1][0],r[1][1],h,level-1,angle,o,off+2*n);size_t n2=curve(r[2][0],r[2][1],h,level-1,angle,o,off+2*(n+n1));size_t n3=curve(r[3][0],r[3][1],h,level-1,angle-1,o,off+2*(n+n1+n2));reverse_points(o,off+2*(n+n1+n2),n3);return n+n1+n2+n3;}
extern "C" int64_t hilbert_curve(const int64_t*v,size_t n,uint8_t*out,size_t cap){if(!v||n!=2||v[0]<1||v[0]>6||v[1]<0||v[1]>3)return -1;size_t l=v[0],points=size_t(1)<<(2*l),bytes=points*16;if(!out||cap<bytes)return -2;std::array<int64_t,8192>a{};curve(0,0,int64_t(1)<<(l+1),int(l),int(v[1]),a.data(),0);for(size_t i=0;i<points*2;i++){uint64_t b;std::memcpy(&b,&a[i],8);for(size_t k=0;k<8;k++)out[i*8+k]=uint8_t(b>>(8*k));}return int64_t(bytes);}
