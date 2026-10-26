/* Bounded exact closest-string center by lexicographic exhaustive search. */
#include <cstddef>
#include <cstdint>
extern "C" int64_t closest_string_center(const int64_t*x,size_t len,uint8_t*out,size_t cap){
 if(!x)return -2;if(len<3||len>51)return -1;auto nv=x[0],mv=x[1],qv=x[2];if(nv<1||nv>6||mv<1||mv>8||(qv!=2&&qv!=3)||len!=3+size_t(nv)*size_t(mv))return -1;
 size_t n=nv,m=mv,q=qv;for(size_t i=3;i<len;i++)if(x[i]<0||x[i]>=qv)return -1;size_t total=1;for(size_t i=0;i<m;i++)total*=q;
 size_t best=m+1,bestc[8]={},candidate[8];for(size_t code=0;code<total;code++){size_t v=code;for(size_t p=m;p>0;p--){candidate[p-1]=v%q;v/=q;}size_t radius=0;
  for(size_t row=0;row<n;row++){size_t d=0;for(size_t col=0;col<m;col++)if(int64_t(candidate[col])!=x[3+row*m+col])++d;if(d>radius)radius=d;}if(radius<best){best=radius;for(size_t j=0;j<m;j++)bestc[j]=candidate[j];}}
 size_t bytes=8*(m+1);if(cap<bytes||!out)return -2;uint64_t v=best;for(size_t b=0;b<8;b++)out[b]=(v>>(8*b))&255;for(size_t j=0;j<m;j++){v=bestc[j];for(size_t b=0;b<8;b++)out[8*(j+1)+b]=(v>>(8*b))&255;}return bytes;
}
