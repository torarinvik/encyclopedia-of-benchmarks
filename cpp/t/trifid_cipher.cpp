#include <cstddef>
#include <cstdint>

static constexpr const char *codes[27] = {
    "111","112","113","121","122","123","131","132","133",
    "211","212","213","221","222","223","231","232","233",
    "311","312","313","321","322","323","331","332","333"
};
static int upper_ascii(int c) { return c >= 'a' && c <= 'z' ? c - ('a' - 'A') : c; }

extern "C" int64_t trifid_cipher(const int64_t *input, size_t length, uint8_t *output,
                                  size_t output_capacity) {
    if (!input || length < 31) return -1;
    int64_t mode=input[0], period_n=input[1], n_n=input[2], an=input[3];
    if ((mode!=0 && mode!=1) || period_n<1 || period_n>256 || n_n<0 || n_n>256 || an!=27 || length!=size_t(31+n_n)) return -1;
    size_t period=size_t(period_n), n=size_t(n_n), alen=0, tlen=0, rlen=0;
    uint8_t alphabet[27], text[256], result[256];
    for(size_t i=0;i<27;i++) { int64_t v=input[4+n+i]; if(v<0||v>127)return -1; int c=upper_ascii(int(v)); if(c==' ')continue; for(size_t j=0;j<alen;j++)if(alphabet[j]==c)return -1; alphabet[alen++]=uint8_t(c); }
    if(alen!=27)return -1;
    for(size_t i=0;i<n;i++) { int64_t v=input[4+i]; if(v<0||v>127)return -1; int c=upper_ascii(int(v)); if(c==' ')continue; bool found=false; for(size_t j=0;j<27;j++)if(alphabet[j]==c)found=true; if(!found)return -1; text[tlen++]=uint8_t(c); }
    for(size_t start=0;start<tlen;start+=period) {
        size_t k=tlen-start; if(k>period)k=period; uint8_t digits[768];
        if(mode==0) { size_t m=0; for(size_t axis=0;axis<3;axis++)for(size_t i=0;i<k;i++){size_t x=0;while(alphabet[x]!=text[start+i])++x;digits[m++]=uint8_t(codes[x][axis]);}
            for(size_t i=0;i<m;i+=3){int x=-1;for(int j=0;j<27;j++)if(codes[j][0]==digits[i]&&codes[j][1]==digits[i+1]&&codes[j][2]==digits[i+2])x=j;if(x<0)return -1;result[rlen++]=alphabet[x];}
        } else { for(size_t i=0;i<k;i++){size_t x=0;while(alphabet[x]!=text[start+i])++x;for(size_t d=0;d<3;d++)digits[3*i+d]=uint8_t(codes[x][d]);}
            for(size_t i=0;i<k;i++){int x=-1;for(int j=0;j<27;j++)if(codes[j][0]==digits[i]&&codes[j][1]==digits[k+i]&&codes[j][2]==digits[2*k+i])x=j;if(x<0)return -1;result[rlen++]=alphabet[x];}
        }
    }
    if(output_capacity<rlen)return -2; if(rlen&&!output)return -1; for(size_t i=0;i<rlen;i++)output[i]=result[i]; return int64_t(rlen);
}
