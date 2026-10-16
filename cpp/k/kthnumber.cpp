#include <cstddef>
#include <cstdint>
static std::int64_t part(std::int64_t*a,std::int64_t l,std::int64_t h){auto p=a[h],i=l;for(auto j=l;j<h;j++)if(a[j]<p){auto t=a[i];a[i]=a[j];a[j]=t;++i;}auto t=a[i];a[i]=a[h];a[h]=t;return i;}
extern "C" std::int64_t kthnumber(const std::int64_t*v,std::size_t n){if(n<4||n>19)return -1;auto count=v[0],mode=v[1],k=v[2];if(count<1||count>16||n!=static_cast<std::size_t>(count+3)||(mode!=1&&mode!=2)||k<1||k>count)return -1;std::int64_t a[16];for(std::int64_t i=0;i<count;i++){a[i]=v[i+3];if(a[i]<-10000||a[i]>10000)return -1;}auto target=mode==1?k-1:count-k;std::int64_t l=0,h=count-1;while(l<=h){auto q=part(a,l,h);if(q==target)return a[q];if(q<target)l=q+1;else h=q-1;}return -1;}
