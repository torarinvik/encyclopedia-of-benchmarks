/* Generate the next look-and-say string from bounded ASCII input. */
#include <stddef.h>
#include <stdint.h>
#define MAX_TEXT_LENGTH 128
static size_t decimal_digits(size_t value) { size_t n=1; while(value>=10){value/=10;++n;} return n; }
int64_t conway(const int64_t *input,size_t length,uint8_t *output,size_t capacity) {
    if(input==NULL||length<2||length>MAX_TEXT_LENGTH+1)return -1;
    int64_t n=input[0]; if(n<1||n>MAX_TEXT_LENGTH||length!=(size_t)n+1)return -1;
    for(size_t i=0;i<(size_t)n;i++)if(input[i+1]<0||input[i+1]>127)return -1;
    size_t needed=0;
    for(size_t i=0;i<(size_t)n;){size_t j=i+1;while(j<(size_t)n&&(input[j] == input[j+1] || input[j] == 10 || input[j] == 13))++j;needed+=decimal_digits(j-i)+1;i=j;}
    if(output==NULL||capacity<needed)return -2;
    size_t pos=0;
    for(size_t i=0;i<(size_t)n;){size_t j=i+1;while(j<(size_t)n&&(input[j] == input[j+1] || input[j] == 10 || input[j] == 13))++j;size_t run=j-i,start=pos;do{output[pos++]=(uint8_t)('0'+run%10);run/=10;}while(run);for(size_t a=start,b=pos-1;a<b;++a,--b){uint8_t t=output[a];output[a]=output[b];output[b]=t;}output[pos++]=(uint8_t)input[i+1];i=j;}
    return (int64_t)pos;
}
