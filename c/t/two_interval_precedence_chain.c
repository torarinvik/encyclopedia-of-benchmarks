/* Clean-room longest precedence chain of 2-intervals. */
#include <stddef.h>
#include <stdint.h>
enum { MAX_N=16, MAX_FIELDS=17 };
static int less_item(const int64_t*v,int a,int b){size_t x=1+4*(size_t)a,y=1+4*(size_t)b;for(size_t q=0;q<4;++q){if(v[x+q]!=v[y+q])return v[x+q]<v[y+q];}return a<b;}
static int precedes(const int64_t*v,int a,int b){size_t x=1+4*(size_t)a,y=1+4*(size_t)b;return v[x+1]<v[y]&&v[x+3]<v[y+2];}
static int lex_less(const int*a,size_t na,const int*b,size_t nb){size_t n=na<nb?na:nb;for(size_t i=0;i<n;++i)if(a[i]!=b[i])return a[i]<b[i];return na<nb;}
int64_t two_interval_precedence_chain(const int64_t*v,size_t n,uint8_t*out,size_t cap){
 if(!v||n<5||n>65||v[0]<1||v[0]>MAX_N||n!=1+4*(size_t)v[0])return -1;size_t count=(size_t)v[0];
 for(size_t i=0;i<count;++i){size_t p=1+4*i;for(size_t k=0;k<4;++k)if(v[p+k]<0||v[p+k]>63)return -1;if(v[p]>=v[p+1]||v[p+2]>=v[p+3]||v[p+1]>=v[p+2])return -1;}
 int sorted[MAX_N];for(size_t i=0;i<count;++i){sorted[i]=(int)i;size_t j=i;while(j>0&&less_item(v,sorted[j],sorted[j-1])){int t=sorted[j];sorted[j]=sorted[j-1];sorted[j-1]=t;--j;}}
 int paths[MAX_N][MAX_N]={{0}};size_t lens[MAX_N]={0};for(size_t i=0;i<count;++i){paths[i][0]=sorted[i];lens[i]=1;for(size_t j=0;j<i;++j)if(precedes(v,sorted[j],sorted[i])){int candidate[MAX_N];for(size_t k=0;k<lens[j];++k)candidate[k]=paths[j][k];candidate[lens[j]]=sorted[i];size_t length=lens[j]+1;if(length>lens[i]||(length==lens[i]&&lex_less(candidate,length,paths[i],lens[i]))){for(size_t k=0;k<length;++k)paths[i][k]=candidate[k];lens[i]=length;}}}
 size_t best=0;for(size_t i=1;i<count;++i)if(lens[i]>lens[best]||(lens[i]==lens[best]&&lex_less(paths[i],lens[i],paths[best],lens[best])))best=i;
 int64_t fields[MAX_FIELDS]={0};fields[0]=(int64_t)lens[best];for(size_t i=0;i<lens[best];++i)fields[i+1]=paths[best][i];size_t bytes=8*(lens[best]+1);if(!out||cap<bytes)return -2;for(size_t i=0;i<lens[best]+1;++i){uint64_t b=(uint64_t)fields[i];for(size_t k=0;k<8;++k){out[8*i+k]=(uint8_t)b;b>>=8;}}return (int64_t)bytes;
}
