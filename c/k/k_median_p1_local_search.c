#include <stddef.h>
#include <stdint.h>
enum { NMAX=12, KMAX=4, INPUT_MAX=150 };
static void put64(uint8_t *o,int64_t x){uint64_t b=(uint64_t)x;for(size_t i=0;i<8;i++)o[i]=(uint8_t)(b>>(8*i));}
static int64_t cost(int64_t d[12][12],int n,int *c,int k){int64_t s=0;for(int i=0;i<n;i++){int64_t best=INT64_MAX;for(int j=0;j<k;j++)if(d[i][c[j]]<best)best=d[i][c[j]];s+=best;}return s;}
static void sort(int *a,int k){for(int i=1;i<k;i++){int x=a[i],j=i;while(j>0&&a[j-1]>x){a[j]=a[j-1];j--;}a[j]=x;}}
static int lexless(int *a,int *b,int k){for(int i=0;i<k;i++)if(a[i]!=b[i])return a[i]<b[i];return 0;}
int64_t k_median_p1_local_search(const int64_t *in,size_t len,uint8_t *out,size_t cap){
 if(!in||len<2||len>INPUT_MAX)return -1;int64_t n0=in[0],k0=in[1];if(n0<2||n0>NMAX||k0<1||k0>KMAX||k0>n0||len!=2+(size_t)n0*(size_t)n0+(size_t)k0)return -1;int n=(int)n0,k=(int)k0;int64_t d[12][12];size_t p=2;
 for(int i=0;i<n;i++)for(int j=0;j<n;j++){int64_t x=in[p++];if(x<0||x>1000)return -1;d[i][j]=x;}
 for(int i=0;i<n;i++)for(int j=0;j<n;j++){if(d[i][j]!=(i==j?0:d[i][j])||d[i][j]!=d[j][i]||(i!=j&&d[i][j]==0))return -1;for(int h=0;h<n;h++)if(d[i][j]>d[i][h]+d[h][j])return -1;}
 int centers[4],seen[12]={0};for(int i=0;i<k;i++){int64_t x=in[p++];if(x<0||x>=n||seen[x])return -1;seen[x]=1;centers[i]=(int)x;}sort(centers,k);
 int64_t current=cost(d,n,centers,k);for(;;){int64_t best=current;int bestc[4];for(int i=0;i<k;i++)bestc[i]=centers[i];int have=0;
  for(int leave=0;leave<k;leave++)for(int enter=0;enter<n;enter++)if(!seen[enter]){int candidate[4];for(int z=0;z<k;z++)candidate[z]=centers[z];candidate[leave]=enter;sort(candidate,k);int64_t value=cost(d,n,candidate,k);if(value<current&&(value<best||(value==best&&(!have||lexless(candidate,bestc,k))))){best=value;for(int z=0;z<k;z++)bestc[z]=candidate[z];have=1;}}
  if(!have)break;for(int z=0;z<k;z++)seen[centers[z]]=0;for(int z=0;z<k;z++){centers[z]=bestc[z];seen[centers[z]]=1;}current=best;
 }
 size_t bytes=8*(size_t)(2+k);if(!out||cap<bytes)return -2;put64(out,current);put64(out+8,k);for(int i=0;i<k;i++)put64(out+16+8*i,centers[i]);return (int64_t)bytes;
}
