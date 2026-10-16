#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT 128
#define MAX_TOKENS 128
#define MAX_FRACTION_WORDS 3

enum { E_NULL=-3, E_UNKNOWN=-4, E_UNEXPECTED=-5, E_AFTER_POINT=-6, E_MISSING_DECIMAL=-7, E_MULTI_NEGATIVE=-8, E_NEGATIVE=-9, E_CONJUNCTION=-10 };
static const char *const WORDS[] = {"zero","one","two","three","four","five","six","seven","eight","nine","ten","eleven","twelve","thirteen","fourteen","fifteen","sixteen","seventeen","eighteen","nineteen","twenty","thirty","forty","fifty","sixty","seventy","eighty","ninety","hundred","thousand","million","billion","trillion","and","point","negative"};
static int word_id(const int64_t *input,size_t start,size_t end) {
    size_t length=end-start;
    for(size_t word=0;word<sizeof(WORDS)/sizeof(WORDS[0]);++word){size_t j=0;while(WORDS[word][j]&&j<length){int ch=(int)input[1+start+j];if(ch>='A'&&ch<='Z')ch+=32;if(ch!=(unsigned char)WORDS[word][j])break;++j;}if(j==length&&WORDS[word][j]=='\0')return (int)word+1;}
    return 0;
}
static int number_value(int id){if(id>=1&&id<=20)return id-1;if(id>=21&&id<=28)return (id-19)*10;return -1;}
static int digits10(int64_t value){int n=1;while(value>=10){value/=10;++n;}return n;}
static size_t append_uint(uint8_t *out,size_t at,int64_t value){uint8_t reversed[24];size_t n=0;do{reversed[n++]=(uint8_t)('0'+value%10);value/=10;}while(value);while(n)out[at++]=reversed[--n];return at;}
static int separator(int64_t c){return c==32||c==44||c==45;}
static int put_number_string(const int64_t *input,size_t byte_count,uint8_t *text,size_t *text_length){
    int tokens[MAX_TOKENS];size_t count=0,start=MAX_INPUT+1;
    for(size_t i=0;i<byte_count;++i){int64_t ch=input[i+1];if(ch<32||ch>126)return -1;if(separator(ch)){if(start!=MAX_INPUT+1){if(count>=MAX_TOKENS)return -1;tokens[count++]=word_id(input,start,i);start=MAX_INPUT+1;}}else if(start==MAX_INPUT+1)start=i;}
    if(start!=MAX_INPUT+1){if(count>=MAX_TOKENS)return -1;tokens[count++]=word_id(input,start,byte_count);}
    if(count==0)return E_NULL;
    int negative=tokens[0]==36;size_t pos=negative?1:0;
    int64_t chunks[MAX_TOKENS];size_t chunk_count=0;int64_t current=0;int prev_hundred=0,prev_scale=0;uint8_t fraction[16];size_t fraction_len=0;int has_point=0;
    for(size_t i=pos;i<count;++i){int id=tokens[i];
        if(id==34){if(i+1>=count)return E_CONJUNCTION;int next=tokens[i+1],value=number_value(next);int after=i+2<count?tokens[i+2]:-1;if((!prev_hundred&&!prev_scale)||value<0||!(value>=10||after==-1||after==35))return E_CONJUNCTION;continue;}
        if(id==29){if(current>=10||prev_scale)return E_UNEXPECTED;if(current==0)current=1;current*=100;prev_hundred=1;continue;}
        prev_hundred=0;
        if(id>=30&&id<=33){if(current==0||prev_scale)return E_UNEXPECTED;int64_t scale=id==30?1000:id==31?1000000:id==32?1000000000LL:1000000000000LL;int64_t next=current*scale;if(chunk_count&&digits10(chunks[chunk_count-1])<=digits10(next))return E_UNEXPECTED;chunks[chunk_count++]=next;current=0;prev_scale=1;continue;}
        prev_scale=0;
        int value=number_value(id);
        if(value>=0){if(value==0&&!(current==0&&chunk_count==0))return E_UNEXPECTED;if(current!=0&&digits10(current)<=digits10(value))return E_UNEXPECTED;current+=value;continue;}
        if(id==35){if(current!=0)chunks[chunk_count++]=current;current=0;has_point=1;size_t words=0;for(size_t j=i+1;j<count;++j){int digit=number_value(tokens[j]);if(digit<0)return E_AFTER_POINT;if(++words>MAX_FRACTION_WORDS)return -1;fraction_len=append_uint(fraction,fraction_len,digit);}if(words==0)return E_MISSING_DECIMAL;break;}
        if(id==36)return negative?E_MULTI_NEGATIVE:E_NEGATIVE;
        return E_UNKNOWN;
    }
    if(current!=0)chunks[chunk_count++]=current;
    int64_t total=0;for(size_t i=0;i<chunk_count;++i)total+=chunks[i];
    size_t out=0;int frac_nonzero=0;for(size_t i=0;i<fraction_len;++i)if(fraction[i]!='0')frac_nonzero=1;
    if(negative&&(total!=0||frac_nonzero))text[out++]='-';
    out=append_uint(text,out,total);
    if(has_point){text[out++]='.';for(size_t i=0;i<fraction_len;++i)text[out++]=fraction[i];}
    *text_length=out;return 0;
}
int64_t words_to_number(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
    if(input==NULL||length<1||length>MAX_INPUT+1)return -1;int64_t n=input[0];if(n<0||n>MAX_INPUT||length!=(size_t)n+1)return -1;
    uint8_t text[64];size_t text_length=0;int status=put_number_string(input,(size_t)n,text,&text_length);if(status!=0)return status;if(output==NULL||capacity<text_length)return -2;for(size_t i=0;i<text_length;++i)output[i]=text[i];return (int64_t)text_length;
}
