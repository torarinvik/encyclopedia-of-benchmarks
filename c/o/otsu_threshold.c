#include <stddef.h>
#include <stdint.h>
int64_t otsu_threshold(const int64_t *v,size_t n,uint8_t*out,size_t cap){
 if(!v||n<2||v[0]<1||v[0]>32||n!=(size_t)v[0]+1)return -1;
 size_t count=(size_t)v[0];uint64_t hist[256]={0};
 for(size_t j=0;j<count;j++){int64_t p=v[j+1];if(p<0||p>255)return -1;hist[p]++;}
 double total=0;for(size_t i=0;i<256;i++)total+=(double)i*(double)hist[i];
 double maxv=0,sum=0;size_t wb=0,threshold=0;
 for(size_t i=0;i<256;i++){wb+=(size_t)hist[i];if(wb==0)continue;size_t wf=count-wb;if(wf==0)break;sum+=(double)i*(double)hist[i];double mb=sum/(double)wb,mf=(total-sum)/(double)wf;double var=(double)wb*(double)wf*(mb-mf)*(mb-mf);if(var>maxv){maxv=var;threshold=i;}}
 if(cap<count||!out)return -2;for(size_t j=0;j<count;j++)out[j]=(uint8_t)(v[j+1]>(int64_t)threshold?255:0);return (int64_t)count;
}
