#include <stddef.h>
#include <stdint.h>

#define MAX_CHILDREN 4
#define MAX_RECORDS 4
#define MAX_INPUT 189
#define MAX_OUTPUT_WORDS 181

static int valid_box(const int64_t b[8]) { for (size_t d=0; d<4; ++d) if (b[d]<-8 || b[d]>8 || b[4+d]<-8 || b[4+d]>8 || b[d]>=b[4+d]) return 0; return 1; }
static int intersects(const int64_t a[8], const int64_t q[8]) { for (size_t d=0; d<4; ++d) if (q[d]>a[4+d] || a[d]>q[4+d]) return 0; return 1; }
static void union_boxes(const int64_t *boxes, size_t count, size_t stride, int64_t out[8]) { for(size_t d=0;d<4;++d){out[d]=boxes[d];out[4+d]=boxes[4+d];} for(size_t i=1;i<count;++i)for(size_t d=0;d<4;++d){if(boxes[i*stride+d]<out[d])out[d]=boxes[i*stride+d];if(boxes[i*stride+4+d]>out[4+d])out[4+d]=boxes[i*stride+4+d];} }
static void write_i64(uint8_t *out,size_t word,int64_t x){uint64_t u=(uint64_t)x;for(size_t b=0;b<8;++b)out[word*8+b]=(uint8_t)(u>>(8*b));}

int64_t versabench_dbms_delete_entry(const int64_t *v,size_t length,uint8_t *output,size_t output_capacity){
    if(v==NULL||length<10||length>MAX_INPUT+1)return -1;
    int64_t childv=v[0];if(childv<1||childv>MAX_CHILDREN)return -1;size_t child_count=(size_t)childv;
    int64_t query[8];for(size_t i=0;i<8;++i)query[i]=v[1+i];if(!valid_box(query))return -1;
    int64_t boxes[MAX_CHILDREN][MAX_RECORDS][8]={0};int64_t ids[MAX_CHILDREN][MAX_RECORDS]={0};size_t counts[MAX_CHILDREN]={0};int64_t mbrs[MAX_CHILDREN][8]={0};unsigned char seen[32]={0};size_t pos=9;
    for(size_t c=0;c<child_count;++c){if(pos+9>length)return -1;int64_t rv=v[pos++];if(rv<1||rv>MAX_RECORDS||pos+8+(size_t)rv*9>length)return -1;counts[c]=(size_t)rv;for(size_t d=0;d<8;++d)mbrs[c][d]=v[pos++];if(!valid_box(mbrs[c]))return -1;
        for(size_t r=0;r<counts[c];++r){for(size_t d=0;d<8;++d)boxes[c][r][d]=v[pos++];ids[c][r]=v[pos++];if(!valid_box(boxes[c][r])||ids[c][r]<0||ids[c][r]>=32||seen[ids[c][r]])return -1;seen[ids[c][r]]=1;}
        int64_t actual[8];union_boxes(&boxes[c][0][0],counts[c],8,actual);for(size_t d=0;d<8;++d)if(actual[d]!=mbrs[c][d])return -1;
    }
    if(pos!=length)return -1;
    int64_t result[MAX_OUTPUT_WORDS];size_t outn=0,remaining=0;size_t kept_counts[MAX_CHILDREN]={0};int64_t kept_boxes[MAX_CHILDREN][MAX_RECORDS][8]={0};int64_t kept_ids[MAX_CHILDREN][MAX_RECORDS]={0};int64_t kept_mbrs[MAX_CHILDREN][8]={0};
    for(size_t c=0;c<child_count;++c){size_t k=0;for(size_t r=0;r<counts[c];++r){if(intersects(mbrs[c],query)&&intersects(boxes[c][r],query))continue;for(size_t d=0;d<8;++d)kept_boxes[c][k][d]=boxes[c][r][d];kept_ids[c][k]=ids[c][r];++k;}if(k){kept_counts[remaining]=k;for(size_t r=0;r<k;++r){for(size_t d=0;d<8;++d)kept_boxes[remaining][r][d]=kept_boxes[c][r][d];kept_ids[remaining][r]=kept_ids[c][r];}union_boxes(&kept_boxes[remaining][0][0],k,8,kept_mbrs[remaining]);++remaining;}}
    result[outn++]=(int64_t)remaining;
    for(size_t c=0;c<remaining;++c){result[outn++]=(int64_t)kept_counts[c];for(size_t d=0;d<8;++d)result[outn++]=kept_mbrs[c][d];for(size_t r=0;r<kept_counts[c];++r){for(size_t d=0;d<8;++d)result[outn++]=kept_boxes[c][r][d];result[outn++]=kept_ids[c][r];}}
    size_t bytes=outn*8;if(output==NULL||output_capacity<bytes)return -2;for(size_t i=0;i<outn;++i)write_i64(output,i,result[i]);return (int64_t)bytes;
}
