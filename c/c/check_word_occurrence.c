#include <stddef.h>
#include <stdint.h>
#define MAX_INPUT 1024
#define MAX_ENTRIES 1025
static int ws(uint8_t c){return c>=9&&c<=13||c==32;}
static uint8_t lower(uint8_t c){return c>='A'&&c<='Z'?(uint8_t)(c+('a'-'A')):c;}
static int forbidden(const uint8_t*s,size_t n){static const char*names[]={"constructor","tostring","tolocalestring","valueof","hasownproperty","isprototypeof","propertyisenumerable"};static const size_t lens[]={11,8,14,7,14,13,20};for(size_t x=0;x<7;x++){if(n!=lens[x])continue;size_t i=0;for(;i<n;i++)if(lower(s[i])!=(uint8_t)names[x][i])break;if(i==n)return 1;}return 0;}
static void put32(uint8_t*out,size_t*pos,uint32_t x){for(int i=0;i<4;i++){out[(*pos)++]=(uint8_t)x;x>>=8;}}
int64_t check_word_occurrence(const int64_t*input,size_t length,uint8_t*output,size_t capacity){
 if(!input||length<2||input[0]<0||input[0]>1||input[1]<0||input[1]>MAX_INPUT||length!=(size_t)input[1]+2)return -1;
 size_t n=(size_t)input[1];uint8_t text[MAX_INPUT];for(size_t i=0;i<n;i++){int64_t v=input[i+2];if(v<0||v>127)return -1;uint8_t c=(uint8_t)v;if(!((c>='A'&&c<='Z')||(c>='a'&&c<='z')||ws(c)))return -1;text[i]=input[0]?lower(c):c;}
 size_t starts[MAX_ENTRIES],lens[MAX_ENTRIES],entries=0;uint32_t counts[MAX_ENTRIES]={0};size_t i=0,start=0;
 for(;;){if(i==n||ws(text[i])){size_t len=i-start;if(forbidden(text+start,len))return -1;size_t j=0;for(;j<entries;j++)if(lens[j]==len){size_t q=0;for(;q<len&&text[starts[j]+q]==text[start+q];q++){}if(q==len)break;}if(j==entries){starts[j]=start;lens[j]=len;counts[j]=0;entries++;}counts[j]++;if(i==n)break;while(i<n&&ws(text[i]))i++;start=i;}else i++;}
 size_t need=4;for(size_t j=0;j<entries;j++)need+=8+lens[j];if(capacity<need||!output)return -2;size_t pos=0;put32(output,&pos,(uint32_t)entries);for(size_t j=0;j<entries;j++){put32(output,&pos,(uint32_t)lens[j]);for(size_t q=0;q<lens[j];q++)output[pos++]=text[starts[j]+q];put32(output,&pos,counts[j]);}return (int64_t)pos;
}
