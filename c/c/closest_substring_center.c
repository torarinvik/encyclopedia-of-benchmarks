/* Bounded exact closest-substring center by lexicographic exhaustive search. */
#include <stddef.h>
#include <stdint.h>
int64_t closest_substring_center(const int64_t*x,size_t len,uint8_t*out,size_t cap){
 if(!x)return -2;if(len<4||len>44)return -1;int64_t nv=x[0],mv=x[1],lv=x[2],qv=x[3];
 if(nv<1||nv>4||mv<1||mv>10||lv<1||lv>8||lv>mv||(qv!=2&&qv!=3)||len!=4+(size_t)nv*(size_t)mv)return -1;
 size_t n=nv,m=mv,l=lv,q=qv;for(size_t i=4;i<len;i++)if(x[i]<0||x[i]>=qv)return -1;
 size_t total=1;for(size_t i=0;i<l;i++)total*=q;size_t best=l+1,bestc[8]={0},cand[8];
 for(size_t code=0;code<total;code++){size_t v=code;for(size_t p=l;p>0;p--){cand[p-1]=v%q;v/=q;}size_t radius=0;
  for(size_t row=0;row<n;row++){size_t rowbest=l+1;for(size_t st=0;st+l<=m;st++){size_t d=0;for(size_t j=0;j<l;j++)if((int64_t)cand[j]!=x[4+row*m+st+j])d++;if(d<rowbest)rowbest=d;}if(rowbest>radius)radius=rowbest;}
  if(radius<best){best=radius;for(size_t j=0;j<l;j++)bestc[j]=cand[j];}}
 size_t bytes=8*(l+1);if(cap<bytes||out==NULL)return -2;uint64_t z=best;for(size_t b=0;b<8;b++)out[b]=(uint8_t)(z>>(8*b));for(size_t j=0;j<l;j++){z=bestc[j];for(size_t b=0;b<8;b++)out[8*(j+1)+b]=(uint8_t)(z>>(8*b));}return bytes;
}
