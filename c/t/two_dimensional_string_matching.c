#include <stddef.h>
#include <stdint.h>
#define D 8
#define L 132
static void put64(uint8_t*o,size_t p,int64_t x){uint64_t b=(uint64_t)x;for(size_t j=0;j<8;j++){o[p+j]=(uint8_t)(b&255U);b>>=8;}}
static int same_row(const int64_t*a,size_t ar,const int64_t*b,size_t br,size_t width){for(size_t j=0;j<width;j++)if(a[ar*width+j]!=b[br*width+j])return 0;return 1;}
int64_t two_dimensional_string_matching(const int64_t*in,size_t len,uint8_t*out,size_t cap){
 if(!in||len<6||len>L)return -1;int64_t rr=in[0],cc=in[1],hr=in[2],wc=in[3];if(rr<1||rr>D||cc<1||cc>D||hr<1||hr>rr||wc<1||wc>cc)return -1;size_t r=(size_t)rr,c=(size_t)cc,h=(size_t)hr,w=(size_t)wc;if(len!=4+r*c+h*w)return -1;int64_t text[64],pat[64];size_t pos=4;for(size_t i=0;i<r*c;i++){text[i]=in[pos++];if(text[i]<0||text[i]>3)return -1;}for(size_t i=0;i<h*w;i++){pat[i]=in[pos++];if(pat[i]<0||pat[i]>3)return -1;}
 int64_t prefix[D]={0};for(size_t i=1;i<h;i++){size_t q=(size_t)prefix[i-1];while(q>0&&!same_row(pat,i,pat,q,w))q=(size_t)prefix[q-1];if(same_row(pat,i,pat,q,w))q++;prefix[i]=(int64_t)q;}
 uint8_t mark[D*D*D]={0};for(size_t tr=0;tr<r;tr++)for(size_t col=0;col<=c-w;col++)for(size_t pr=0;pr<h;pr++){int equal=1;for(size_t j=0;j<w;j++)if(text[tr*c+col+j]!=pat[pr*w+j])equal=0;mark[(tr*D+col)*D+pr]=(uint8_t)equal;}
 int64_t match_r[D*D],match_c[D*D];size_t count=0;for(size_t col=0;col<=c-w;col++){size_t q=0;for(size_t tr=0;tr<r;tr++){while(q>0&&!mark[(tr*D+col)*D+q])q=(size_t)prefix[q-1];if(mark[(tr*D+col)*D+q])q++;if(q==h){match_r[count]=(int64_t)(tr+1-h);match_c[count]=(int64_t)col;count++;q=(size_t)prefix[h-1];}}}
 size_t bytes=8*(1+2*count);if(!out||cap<bytes)return -2;put64(out,0,(int64_t)count);for(size_t i=0;i<count;i++){put64(out,8*(1+2*i),match_r[i]);put64(out,8*(2+2*i),match_c[i]);}return (int64_t)bytes;
}
