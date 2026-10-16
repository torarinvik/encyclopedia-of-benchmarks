#include <stddef.h>
#include <stdint.h>
#define BASE 32000001LL
int64_t job_sequencing_with_deadline(const int64_t*v,size_t n){if(!v||n<1||n>65)return -1;int64_t count=v[0];if(count<1||count>32||n!=1+2*(size_t)count)return -1;int64_t d[32],p[32];size_t order[32];for(size_t i=0;i<(size_t)count;i++){d[i]=v[1+2*i];p[i]=v[2+2*i];if(d[i]<0||d[i]>32||p[i]<0||p[i]>1000000)return -1;order[i]=i;}for(size_t i=1;i<(size_t)count;i++){size_t key=order[i],j=i;while(j>0&&p[order[j-1]]<p[key]){order[j]=order[j-1];j--;}order[j]=key;}int slots[33]={0};int64_t chosen=0,profit=0;for(size_t k=0;k<(size_t)count;k++)for(int s=(int)d[order[k]];s>0;s--)if(!slots[s]){slots[s]=1;chosen++;profit+=p[order[k]];break;}return chosen*BASE+profit;}
