#include <stddef.h>
#include <stdint.h>
enum { MAX_TEXT=32, MAX_PATTERN=8, MAX_INPUT=43, ALPHABET=5 };
static int suffix_less(const int64_t *s,size_t n,size_t a,size_t b){while(a<n&&b<n){if(s[a]!=s[b])return s[a]<s[b];++a;++b;}return a==n&&b!=n;}
static void store_i64_le(uint8_t *out,size_t off,int64_t value){uint64_t bits=(uint64_t)value;for(size_t b=0;b<8;++b){out[off+b]=(uint8_t)(bits&255U);bits>>=8;}}
int64_t fm_index_locate(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
 if(input==NULL||length<5||length>MAX_INPUT)return -1;int64_t n0=input[0];if(n0<1||n0>MAX_TEXT||length<(size_t)n0+4)return -1;
 size_t n=(size_t)n0,m_at=n+1;int64_t m0=input[m_at];if(m0<1||m0>MAX_PATTERN||length!=m_at+1+(size_t)m0+1)return -1;size_t m=(size_t)m0,stride_at=length-1;int64_t stride0=input[stride_at];if(stride0<1||stride0>n0)return -1;size_t stride=(size_t)stride0,N=n+1;
 int64_t s[MAX_TEXT+1],pattern[MAX_PATTERN];for(size_t i=0;i<n;++i){int64_t x=input[1+i];if(x<1||x>4)return -1;s[i]=x;}
 for(size_t i=0;i<m;++i){int64_t x=input[m_at+1+i];if(x<1||x>4)return -1;pattern[i]=x;}s[n]=0;
 size_t sa[MAX_TEXT+1];for(size_t i=0;i<N;++i)sa[i]=i;for(size_t i=1;i<N;++i){size_t key=sa[i],j=i;while(j>0&&suffix_less(s,N,key,sa[j-1])){sa[j]=sa[j-1];--j;}sa[j]=key;}
 int64_t bwt[MAX_TEXT+1];size_t freq[ALPHABET]={0};for(size_t i=0;i<N;++i){bwt[i]=s[(sa[i]+N-1)%N];++freq[(size_t)bwt[i]];}
 size_t C[ALPHABET],sum=0;for(size_t c=0;c<ALPHABET;++c){C[c]=sum;sum+=freq[c];}
 size_t left=0,right=N;for(size_t j=m;j>0;--j){size_t c=(size_t)pattern[j-1],rl=0,rr=0;for(size_t x=0;x<left;++x)if((size_t)bwt[x]==c)++rl;for(size_t x=0;x<right;++x)if((size_t)bwt[x]==c)++rr;left=C[c]+rl;right=C[c]+rr;if(left==right)break;}
 size_t LF[MAX_TEXT+1],seen[ALPHABET]={0};uint8_t sampled[MAX_TEXT+1];size_t samples[MAX_TEXT+1];
 for(size_t row=0;row<N;++row){size_t c=(size_t)bwt[row],rank=0;for(size_t x=0;x<row;++x)if((size_t)bwt[x]==c)++rank;LF[row]=C[c]+rank;sampled[row]=(uint8_t)(sa[row]%stride==0);samples[row]=sa[row];}
 int64_t locations[MAX_TEXT];size_t count=0;
 for(size_t origin=left;origin<right;++origin){size_t row=origin,steps=0;while(!sampled[row]&&steps<N){row=LF[row];++steps;}if(!sampled[row])return -1;size_t pos=(samples[row]+steps)%N;if(pos>=n)return -1;locations[count++]=(int64_t)pos;}
 size_t bytes=8*(count+1);if(output==NULL||capacity<bytes)return -2;store_i64_le(output,0,(int64_t)count);for(size_t i=0;i<count;++i)store_i64_le(output,8*(i+1),locations[i]);return (int64_t)bytes;
}
