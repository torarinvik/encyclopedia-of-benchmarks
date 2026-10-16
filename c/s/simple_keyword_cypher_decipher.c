#include <stddef.h>
#include <stdint.h>
#define MAX_INPUT 322
int64_t simple_keyword_cypher_decipher(const int64_t *v, size_t n, uint8_t *out, size_t cap) {
 if (!v || n < 2 || n > 323) return -1;
 int64_t kl=v[0], ml=v[1]; if(kl<0||kl>64||ml<0||ml>256||n!=2+(size_t)kl+(size_t)ml)return -1;
 uint8_t key[26], map[26], result[256]; size_t count=0;
 for(size_t i=0;i<(size_t)kl;i++){int64_t x=v[2+i]; if(!((x>=65&&x<=90)||(x>=97&&x<=122)))return -1; if(x>=97)x-=32; size_t j=0;while(j<count&&key[j]!=(uint8_t)x)j++;if(j==count)key[count++]=(uint8_t)x;}
 size_t k=0;for(size_t i=0;i<count;i++)map[k++]=key[i];for(int x=65;x<=90;x++){size_t j=0;while(j<count&&key[j]!=(uint8_t)x)j++;if(j==count)map[k++]=(uint8_t)x;}
 for(size_t i=0;i<(size_t)ml;i++){int64_t x=v[2+(size_t)kl+i];if(x<0||x>127)return -1;if(x>=97&&x<=122)x-=32;if(x>=65&&x<=90){size_t j=0;while(j<26&&map[j]!=(uint8_t)x)j++;if(j==26)return -1;result[i]=(uint8_t)('A'+j);}else result[i]=(uint8_t)x;}
 if(!out||cap<(size_t)ml)return -2;for(size_t i=0;i<(size_t)ml;i++)out[i]=result[i];return ml;
}
