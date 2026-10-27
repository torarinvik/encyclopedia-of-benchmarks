#include <stddef.h>
#include <stdint.h>
enum { MAX_TEXT = 64, MAX_INPUT = 66, MAX_OUTPUT = 1536 };
static void put64(uint8_t *o, size_t at, int64_t v) { uint64_t b=(uint64_t)v; for(size_t i=0;i<8;i++){o[at+i]=(uint8_t)b;b>>=8;} }
int64_t lz77_infinite_rightmost(const int64_t *in,size_t len,uint8_t *out,size_t cap){
    if(!in||len<1||len>MAX_INPUT||in[0]<0||in[0]>MAX_TEXT)return -1;
    size_t n=(size_t)in[0]; if(len!=n+1)return -1;
    for(size_t i=0;i<n;i++)if(in[i+1]<32||in[i+1]>126)return -1;
    uint8_t staged[MAX_OUTPUT]={0}; size_t tokens=0,q=0;
    while(q<n){size_t bl=0,bp=0;int found=0;
        for(size_t p=0;p<q;p++){size_t l=0;while(q+l<n&&in[p+l+1]==in[q+l+1])l++;
            if(l>bl||(l==bl&&l>0&&(!found||p>bp))){bl=l;bp=p;found=1;}}
        int64_t source_pos=found?(int64_t)bp:0; size_t np=q+bl;
        int64_t ch=np<n?in[np+1]:0; size_t at=tokens*24;
        put64(staged,at,source_pos);put64(staged,at+8,(int64_t)bl);put64(staged,at+16,ch);tokens++;
        q=ch?np+1:np;
    }
    size_t bytes=tokens*24; if(out==NULL||cap<bytes)return -2;
    for(size_t i=0;i<bytes;i++)out[i]=staged[i]; return (int64_t)bytes;
}
