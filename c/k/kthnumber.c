#include <stddef.h>
#include <stdint.h>
static int64_t part(int64_t*a,int64_t l,int64_t h){int64_t p=a[h],i=l;for(int64_t j=l;j<h;j++)if(a[j]<p){int64_t t=a[i];a[i++]=a[j];a[j]=t;}int64_t t=a[i];a[i]=a[h];a[h]=t;return i;}
int64_t kthnumber(const int64_t*v,size_t n){if(n<4||n>19)return -1;int64_t count=v[0],mode=v[1],k=v[2];if(count<1||count>16||n!=(size_t)(count+3)||(mode!=1&&mode!=2)||k<1||k>count)return -1;int64_t a[16];for(int64_t i=0;i<count;i++){a[i]=v[i+3];if(a[i]<-10000||a[i]>10000)return -1;}int64_t target=mode==1?k-1:count-k,l=0,h=count-1;while(l<=h){int64_t q=part(a,l,h);if(q==target)return a[q];if(q<target)l=q+1;else h=q-1;}return -1;}
