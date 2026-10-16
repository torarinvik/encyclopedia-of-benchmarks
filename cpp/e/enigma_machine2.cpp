#include <cstdint>
#include <cstddef>
#include <stdint.h>
#include <stddef.h>
static const char *rotors[3]={"EGZWVONAHDCLFQMSIPJBYUKXTR","FOBHMDKEXQNRAULPGSJVTYICZW","ZJXESIUQLHAVRMDOYGTNFWPBKC"};
static int64_t mod26(int x){x%=26;return x<0?x+26:x;}
extern "C" int64_t enigma_machine2(const int64_t *a,size_t len){if(!a||len<4||len>16)return -1;int64_t n=a[0];if(n<0||n>12||len!=(size_t)(4+n))return -1;int p[3];for(int j=0;j<3;j++){if(a[1+j]<1||a[1+j]>26)return -1;p[j]=(int)a[1+j]-1;}for(int i=0;i<n;i++)if(a[4+i]<0||a[4+i]>25)return -1;int64_t out=0;for(int i=0;i<n;i++){int x=(int)a[4+i];for(int r=0;r<3;r++)x=rotors[r][mod26(x+p[r])]-'A';x=mod26(x+13);for(int r=2;r>=0;r--){int z=0;while(rotors[r][z]-'A'!=x)z++;x=mod26(z-p[r]);}out=out*26+x;p[0]++;if(p[0]==26){p[0]=0;p[1]++;if(p[1]==26){p[1]=0;p[2]=(p[2]+1)%26;}}}return out;}
