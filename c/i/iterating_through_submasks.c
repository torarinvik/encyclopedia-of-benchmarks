#include <stddef.h>
#include <stdint.h>
int64_t iterating_through_submasks(const int64_t*v,size_t n){if(!v||n!=1||v[0]<1||v[0]>4095)return -1;int64_t mask=v[0],count=0,submask=mask;while(submask){count++;submask=(submask-1)&mask;}return count;}
