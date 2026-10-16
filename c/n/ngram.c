#include <stddef.h>
#include <stdint.h>
int64_t ngram(const int64_t *v,size_t n,uint8_t *out,size_t cap){
 if(!v||n<2||n>258||v[0]<1||v[0]>16||v[1]<0||v[1]>256||n!=(size_t)v[1]+2)return -1;
 size_t width=(size_t)v[0],text=(size_t)v[1];for(size_t i=0;i<text;i++)if(v[i+2]<32||v[i+2]>126)return -1;
 size_t grams=text>=width?text-width+1:0;size_t bytes=grams?grams*width+grams-1:0;
 if(bytes>cap||(bytes>0&&!out))return -2;size_t w=0;for(size_t i=0;i<grams;i++){if(i)out[w++]='\n';for(size_t j=0;j<width;j++)out[w++]=(uint8_t)v[i+j+2];}return (int64_t)w;
}
