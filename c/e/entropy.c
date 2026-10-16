/* ASCII character and bigram entropy summary matching the pinned Python source. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>
#define MAX_TEXT 512
#define ALPHABET 128
#define PAIRS (ALPHABET*ALPHABET)
static int round_even(double value) { double lower=floor(value); double fraction=value-lower; if(fraction<0.5)return (int)lower; if(fraction>0.5)return (int)(lower+1); int integer=(int)lower; return integer%2==0?integer:integer+1; }
static size_t emit_line(uint8_t *out,size_t pos,int value) { if(value<0){out[pos++]='-';value=-value;} if(value>=10)out[pos++]=(uint8_t)('0'+value/10);out[pos++]=(uint8_t)('0'+value%10);out[pos++]='.';out[pos++]='0';out[pos++]='\n';return pos; }
int64_t entropy(const int64_t *input,size_t length,uint8_t *output,size_t capacity) {
 if(input==NULL||length<2||length>MAX_TEXT+1)return -1;int64_t n=input[0];if(n<1||n>MAX_TEXT||length!=(size_t)n+1)return -1;
 uint32_t singles[ALPHABET]={0};uint32_t pairs[PAIRS]={0};for(size_t i=0;i<(size_t)n;i++){int64_t c=input[i+1];if(c<0||c>=ALPHABET)return -1;singles[c]++;}
 pairs[32*ALPHABET+(size_t)input[1]]++;for(size_t i=0;i+1<(size_t)n;i++)pairs[(size_t)input[i+1]*ALPHABET+(size_t)input[i+2]]++;
 static const int alphabet[27]={32,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122};double s1=0.0,s2=0.0;
 for(size_t i=0;i<27;i++){uint32_t count=singles[alphabet[i]];if(count){double p=(double)count/(double)n;s1+=p*log2(p);}}
 for(size_t i=0;i<27;i++)for(size_t j=0;j<27;j++){uint32_t count=pairs[alphabet[i]*ALPHABET+alphabet[j]];if(count){double p=(double)count/(double)n;s2+=p*log2(p);}}
 uint8_t temp[32];size_t pos=0;pos=emit_line(temp,pos,round_even(-s1));pos=emit_line(temp,pos,round_even(-s2));pos=emit_line(temp,pos,round_even((-s2)-(-s1)));if(output==NULL||capacity<pos)return -2;memcpy(output,temp,pos);return (int64_t)pos;
}
