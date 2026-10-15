#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 1024
static int ascii_space(int64_t c) { return c==9||c==10||c==11||c==12||c==13||c==32; }
int64_t validate_email(const int64_t *v,size_t n) {
    if(!v||n<2||n>MAX_LENGTH+1||v[0]<1||v[0]>MAX_LENGTH||(size_t)v[0]+1!=n)return -1;
    size_t end=(size_t)v[0];for(size_t i=0;i<end;++i)if(v[i+1]<0||v[i+1]>127)return -1;
    size_t at=end;
    for(size_t i=0;i<end;++i){int64_t c=v[i+1];if(ascii_space(c))return 0;if(c=='@'){if(at!=end)return 0;at=i;}}
    if(at==0||at>=end-1)return 0;
    int dot=0;for(size_t i=at+2;i+1<end;++i)if(v[i+1]=='.')dot=1;
    return dot?1:0;
}
