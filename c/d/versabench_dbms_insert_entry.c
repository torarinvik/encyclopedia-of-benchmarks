#include <stddef.h>
#include <stdint.h>

#define MAX_DEPTH 2
#define MAX_CHILDREN 4
#define MAX_LEAF_ENTRIES 3
#define MAX_INPUT_LENGTH 104
#define MAX_OUTPUT_WORDS 28

static int valid_box(const int64_t box[8]) {
    for (size_t d=0;d<4;++d)
        if(box[d]<-8||box[d]>8||box[4+d]<-8||box[4+d]>8||box[d]>=box[4+d])return 0;
    return 1;
}
static void box_union(const int64_t *boxes,size_t count,size_t stride,int64_t out[8]) {
    for(size_t d=0;d<4;++d){out[d]=boxes[d];out[4+d]=boxes[4+d];}
    for(size_t i=1;i<count;++i)for(size_t d=0;d<4;++d){
        int64_t lo=boxes[i*stride+d],hi=boxes[i*stride+4+d];
        if(lo<out[d])out[d]=lo;if(hi>out[4+d])out[4+d]=hi;
    }
}
static int64_t volume(const int64_t box[8]) {
    int64_t result=1;for(size_t d=0;d<4;++d)result*=box[4+d]-box[d];return result;
}
static int same_box(const int64_t *a,const int64_t *b){for(size_t i=0;i<8;++i)if(a[i]!=b[i])return 0;return 1;}
static void write_i64(uint8_t *out,size_t word,int64_t value){uint64_t bits=(uint64_t)value;for(size_t b=0;b<8;++b)out[word*8+b]=(uint8_t)(bits>>(8*b));}

int64_t versabench_dbms_insert_entry(const int64_t *v,size_t length,uint8_t *output,size_t output_capacity){
    if(v==NULL||length<11||length>MAX_INPUT_LENGTH+1)return -1;
    int64_t depthv=v[0],new_id=v[1];
    if(depthv<0||depthv>MAX_DEPTH||new_id<0||new_id>=32)return -1;
    size_t depth=(size_t)depthv;int64_t incoming[8];
    for(size_t i=0;i<8;++i)incoming[i]=v[2+i];if(!valid_box(incoming))return -1;
    int64_t branches[MAX_DEPTH][MAX_CHILDREN][8]={0};size_t counts[MAX_DEPTH]={0};size_t pos=10;
    unsigned char seen[32]={0};size_t leaf_count=0;
    for(size_t level=0;level<depth;++level){
        if(pos>=length)return -1;int64_t countv=v[pos++];
        if(countv<1||countv>MAX_CHILDREN||pos+(size_t)countv*8>length)return -1;
        counts[level]=(size_t)countv;
        for(size_t i=0;i<counts[level];++i){for(size_t j=0;j<8;++j)branches[level][i][j]=v[pos++];if(!valid_box(branches[level][i]))return -1;}
    }
    if(pos>=length)return -1;int64_t leafv=v[pos++];
    if(leafv<0||leafv>MAX_LEAF_ENTRIES||(depth>0&&leafv==0)||pos+(size_t)leafv*9>length)return -1;
    leaf_count=(size_t)leafv;
    int64_t leaf_boxes[MAX_LEAF_ENTRIES][8]={{0}};int64_t leaf_ids[MAX_LEAF_ENTRIES]={0};
    for(size_t i=0;i<leaf_count;++i){for(size_t j=0;j<8;++j)leaf_boxes[i][j]=v[pos++];leaf_ids[i]=v[pos++];
        if(!valid_box(leaf_boxes[i])||leaf_ids[i]<0||leaf_ids[i]>=32||seen[leaf_ids[i]])return -1;seen[leaf_ids[i]]=1;}
    if(pos!=length||seen[new_id])return -1;
    size_t choice[MAX_DEPTH]={0};
    for(size_t level=0;level<depth;++level){
        int64_t best=-1;
        for(size_t i=0;i<counts[level];++i){int64_t joined[8];
            for(size_t d=0;d<4;++d){joined[d]=branches[level][i][d]<incoming[d]?branches[level][i][d]:incoming[d];joined[4+d]=branches[level][i][4+d]>incoming[4+d]?branches[level][i][4+d]:incoming[4+d];}
            int64_t penalty=volume(joined)-volume(branches[level][i]);
            if(best<0||penalty<best){best=penalty;choice[level]=i;}
        }
    }
    if(depth>0){
        int64_t pre[8];box_union(&leaf_boxes[0][0],leaf_count,8,pre);
        for(size_t rev=depth;rev>0;--rev){size_t level=rev-1;if(!same_box(branches[level][choice[level]],pre))return -1;box_union(&branches[level][0][0],counts[level],8,pre);}
    }
    int64_t staged_leaf[4][8]={{0}};for(size_t i=0;i<leaf_count;++i)for(size_t j=0;j<8;++j)staged_leaf[i][j]=leaf_boxes[i][j];
    for(size_t j=0;j<8;++j)staged_leaf[leaf_count][j]=incoming[j];
    int64_t after_mbr[8];box_union(&staged_leaf[0][0],leaf_count+1,8,after_mbr);
    int64_t output_words[MAX_OUTPUT_WORDS];size_t out_count=0;
    output_words[out_count++]=(int64_t)depth;output_words[out_count++]=new_id;
    for(size_t i=0;i<depth;++i)output_words[out_count++]=(int64_t)choice[i];
    for(size_t j=0;j<8;++j)output_words[out_count++]=after_mbr[j];
    int64_t child_after[8];for(size_t j=0;j<8;++j)child_after[j]=after_mbr[j];
    for(size_t rev=depth;rev>0;--rev){size_t level=rev-1;for(size_t j=0;j<8;++j)branches[level][choice[level]][j]=child_after[j];
        box_union(&branches[level][0][0],counts[level],8,child_after);for(size_t j=0;j<8;++j)output_words[out_count++]=child_after[j];}
    const size_t output_bytes=out_count*8;
    if(output==NULL||output_capacity<output_bytes)return -2;
    for(size_t i=0;i<out_count;++i)write_i64(output,i,output_words[i]);
    return (int64_t)output_bytes;
}
