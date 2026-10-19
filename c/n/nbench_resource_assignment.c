#include <stddef.h>
#include <stdint.h>
#define MAX_N 8
#define MAX_INPUT (1+MAX_N*MAX_N)
#define MAX_COST 1000
#define MAX_ADJUST 2048
static int first_assignments(int64_t *a,uint8_t *mark,size_t n){
 for(size_t i=0;i<n*n;i++)mark[i]=0;size_t total=0;
 for(;;){size_t made=0;
  for(size_t i=0;i<n;i++){size_t cnt=0,sel=0;for(size_t j=0;j<n;j++)if(a[i*n+j]==0&&mark[i*n+j]==0){cnt++;sel=j;}if(cnt==1){made++;total++;mark[i*n+sel]=1;for(size_t k=0;k<n;k++)if(k!=i&&a[k*n+sel]==0)mark[k*n+sel]=2;}}
  for(size_t j=0;j<n;j++){size_t cnt=0,sel=0;for(size_t i=0;i<n;i++)if(a[i*n+j]==0&&mark[i*n+j]==0){cnt++;sel=i;}if(cnt==1){made++;total++;mark[sel*n+j]=1;for(size_t k=0;k<n;k++)if(k!=j&&a[sel*n+k]==0)mark[sel*n+k]=2;}}
  if(made==0)break;
 }
 if(total==n)return (int)total;
 for(size_t i=0;i<n;i++){size_t sel=n;for(size_t j=0;j<n;j++)if(a[i*n+j]==0&&mark[i*n+j]==0){sel=j;break;}if(sel<n){mark[i*n+sel]=1;total++;for(size_t k=0;k<n;k++)if(k!=sel&&a[i*n+k]==0)mark[i*n+k]=2;for(size_t k=0;k<n;k++)if(k!=i&&a[k*n+sel]==0)mark[k*n+sel]=2;}}
 return (int)total;
}
static int second_assignments(int64_t *a,const uint8_t *mark,size_t n){
 uint8_t rows[MAX_N]={0},cols[MAX_N]={0};for(size_t i=0;i<n;i++){int assigned=0;for(size_t j=0;j<n;j++)if(mark[i*n+j]==1){assigned=1;break;}rows[i]=assigned?0:1;}
 for(;;){size_t newrows=0;for(size_t i=0;i<n;i++)if(rows[i])for(size_t j=0;j<n;j++)if(a[i*n+j]==0)cols[j]=1;
  for(size_t j=0;j<n;j++)if(cols[j])for(size_t i=0;i<n;i++)if(mark[i*n+j]==1&&rows[i]!=1){rows[i]=1;newrows++;}if(!newrows)break;
 }
 int64_t smallest=INT64_MAX;for(size_t i=0;i<n;i++)if(rows[i])for(size_t j=0;j<n;j++)if(!cols[j]&&a[i*n+j]<smallest)smallest=a[i*n+j];if(smallest==INT64_MAX)return 0;
 for(size_t i=0;i<n;i++)for(size_t j=0;j<n;j++){if(rows[i]&&!cols[j])a[i*n+j]-=smallest;else if(!rows[i]&&cols[j])a[i*n+j]+=smallest;}return 1;
}
int64_t nbench_resource_assignment(const int64_t *values,size_t length,uint8_t *output,size_t capacity){
 if(!values||length<2||length>MAX_INPUT+1)return -1;int64_t rn=values[0];if(rn<1||rn>MAX_N||length!=1+(size_t)rn*(size_t)rn)return -1;size_t n=(size_t)rn;
 int64_t a[MAX_N*MAX_N];for(size_t i=0;i<n*n;i++){if(values[i+1]<0||values[i+1]>MAX_COST)return -1;a[i]=values[i+1];}
 for(size_t i=0;i<n;i++){int64_t m=INT64_MAX;for(size_t j=0;j<n;j++)if(a[i*n+j]<m)m=a[i*n+j];for(size_t j=0;j<n;j++)a[i*n+j]-=m;}
 for(size_t j=0;j<n;j++){int64_t m=INT64_MAX;for(size_t i=0;i<n;i++)if(a[i*n+j]<m)m=a[i*n+j];if(m)for(size_t i=0;i<n;i++)a[i*n+j]-=m;}
 uint8_t mark[MAX_N*MAX_N]={0};int done=0;for(size_t iter=0;iter<=MAX_ADJUST;iter++){if(first_assignments(a,mark,n)==(int)n){done=1;break;}if(!second_assignments(a,mark,n))return -1;}if(!done)return -1;
 size_t columns[MAX_N];uint8_t seen[MAX_N]={0};for(size_t i=0;i<n;i++){size_t col=n;for(size_t j=0;j<n;j++)if(mark[i*n+j]==1){if(col!=n)return -1;col=j;}if(col==n||seen[col])return -1;columns[i]=col;seen[col]=1;}
 size_t bytes=n*4;if(!output||capacity<bytes)return -2;for(size_t i=0;i<n;i++){uint32_t x=(uint32_t)columns[i];for(size_t b=0;b<4;b++)output[4*i+b]=(uint8_t)(x>>(8*b));}return (int64_t)bytes;
}
