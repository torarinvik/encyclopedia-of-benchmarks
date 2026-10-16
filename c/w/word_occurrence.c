#include <stddef.h>
#include <stdint.h>
#define MAX_INPUT 1024
#define MAX_ENTRIES 512
static int ws(uint8_t c){return (c>=9&&c<=13)||(c>=28&&c<=32);}
static void put32(uint8_t*out,size_t*pos,uint32_t value){for(size_t i=0;i<4;i++){out[(*pos)++]=(uint8_t)value;value>>=8;}}
int64_t word_occurrence(const int64_t*input,size_t length,uint8_t*output,size_t capacity){
 if(input==NULL||length<1||length>MAX_INPUT+1||input[0]<0||input[0]>MAX_INPUT||length!=(size_t)input[0]+1)return -1;
 size_t n=(size_t)input[0];uint8_t text[MAX_INPUT];for(size_t i=0;i<n;i++){int64_t v=input[i+1];if(v<0||v>127)return -1;text[i]=(uint8_t)v;}
 size_t starts[MAX_ENTRIES],lens[MAX_ENTRIES],entries=0;uint32_t counts[MAX_ENTRIES]={0};size_t i=0;
 while(i<n){while(i<n&&ws(text[i]))i++;if(i==n)break;size_t start=i;while(i<n&&!ws(text[i]))i++;size_t len=i-start;size_t j=0;for(;j<entries;j++){if(lens[j]!=len)continue;size_t q=0;for(;q<len&&text[starts[j]+q]==text[start+q];q++){}if(q==len)break;}if(j==entries){if(entries>=MAX_ENTRIES)return -1;starts[j]=start;lens[j]=len;counts[j]=0;entries++;}counts[j]++;}
 size_t need=4;for(size_t j=0;j<entries;j++)need+=8+lens[j];if(output==NULL||capacity<need)return -2;size_t pos=0;put32(output,&pos,(uint32_t)entries);for(size_t j=0;j<entries;j++){put32(output,&pos,(uint32_t)lens[j]);for(size_t q=0;q<lens[j];q++)output[pos++]=text[starts[j]+q];put32(output,&pos,counts[j]);}return (int64_t)pos;
}
