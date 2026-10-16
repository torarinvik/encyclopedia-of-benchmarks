#include <stddef.h>
#include <stdint.h>
#define MAX_TEXT 256
#define MAX_PATTERN 64
int64_t zblock_substring_search(const int64_t* a,size_t length){if(!a||length<3)return -1;int64_t tn=a[0],pn=a[1];if(tn<0||tn>MAX_TEXT||pn<1||pn>MAX_PATTERN||length!=(size_t)(tn+pn+2))return -1;for(size_t i=2;i<length;i++)if(a[i]<0||a[i]>127||a[i]==36)return -1;size_t n=(size_t)(tn+pn+1),sep=(size_t)pn;int64_t s[MAX_TEXT+MAX_PATTERN+1];size_t z[MAX_TEXT+MAX_PATTERN+1];for(size_t i=0;i<(size_t)pn;i++)s[i]=a[2+tn+i];s[sep]=-1;for(size_t i=0;i<(size_t)tn;i++)s[sep+1+i]=a[2+i];size_t l=0,r=0;z[0]=0;for(size_t i=1;i<n;i++){if(i<=r){size_t k=z[i-l];z[i]=k<r-i+1?k:r-i+1;}else z[i]=0;while(i+z[i]<n&&s[z[i]]==s[i+z[i]])z[i]++;if(i+z[i]>0&&i+z[i]-1>r){l=i;r=i+z[i]-1;}}int64_t found=0;for(size_t i=sep+1;i<n;i++)if(z[i]>=(size_t)pn)found++;return found;}
