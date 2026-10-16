#include <stddef.h>
#include <stdint.h>
int64_t majority_element_sort(const int64_t*v,size_t n){if(!v||n<2||n>128)return -1;int32_t a[128];for(size_t i=0;i<n;i++){if(v[i]<INT32_MIN||v[i]>INT32_MAX)return -1;a[i]=(int32_t)v[i];}for(size_t i=1;i<n;i++){int32_t x=a[i];size_t j=i;while(j&&a[j-1]>x){a[j]=a[j-1];j--;}a[j]=x;}size_t run=1;for(size_t i=1;i<n;i++){run=a[i]==a[i-1]?run+1:1;if(run>n/2)return a[i];}return -1;}
