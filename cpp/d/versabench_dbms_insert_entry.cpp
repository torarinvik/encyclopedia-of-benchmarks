#include <cstddef>
#include <cstdint>

namespace {
constexpr size_t MaxDepth=2,MaxChildren=4,MaxLeaf=3,MaxWords=28;
bool valid_box(const int64_t b[8]){for(size_t d=0;d<4;++d)if(b[d]<-8||b[d]>8||b[4+d]<-8||b[4+d]>8||b[d]>=b[4+d])return false;return true;}
void box_union(const int64_t *boxes,size_t count,size_t stride,int64_t out[8]){
    for(size_t d=0;d<4;++d){out[d]=boxes[d];out[4+d]=boxes[4+d];}
    for(size_t i=1;i<count;++i)for(size_t d=0;d<4;++d){if(boxes[i*stride+d]<out[d])out[d]=boxes[i*stride+d];if(boxes[i*stride+4+d]>out[4+d])out[4+d]=boxes[i*stride+4+d];}
}
int64_t volume(const int64_t b[8]){int64_t v=1;for(size_t d=0;d<4;++d)v*=b[4+d]-b[d];return v;}
bool same_box(const int64_t *a,const int64_t *b){for(size_t i=0;i<8;++i)if(a[i]!=b[i])return false;return true;}
void write_i64(uint8_t *out,size_t word,int64_t v){uint64_t bits=static_cast<uint64_t>(v);for(size_t b=0;b<8;++b)out[word*8+b]=static_cast<uint8_t>(bits>>(8*b));}
}

extern "C" int64_t versabench_dbms_insert_entry(const int64_t *v,size_t length,uint8_t *output,size_t output_capacity){
    if(v==nullptr||length<11||length>105)return -1;
    const int64_t depthv=v[0],new_id=v[1];if(depthv<0||depthv>static_cast<int64_t>(MaxDepth)||new_id<0||new_id>=32)return -1;
    const size_t depth=static_cast<size_t>(depthv);int64_t incoming[8];for(size_t i=0;i<8;++i)incoming[i]=v[2+i];if(!valid_box(incoming))return -1;
    int64_t branches[MaxDepth][MaxChildren][8]{};size_t counts[MaxDepth]{},pos=10;bool seen[32]{};
    for(size_t level=0;level<depth;++level){if(pos>=length)return -1;const int64_t cv=v[pos++];if(cv<1||cv>4||pos+static_cast<size_t>(cv)*8>length)return -1;counts[level]=static_cast<size_t>(cv);for(size_t i=0;i<counts[level];++i){for(size_t j=0;j<8;++j)branches[level][i][j]=v[pos++];if(!valid_box(branches[level][i]))return -1;}}
    if(pos>=length)return -1;const int64_t lv=v[pos++];if(lv<0||lv>3||(depth>0&&lv==0)||pos+static_cast<size_t>(lv)*9>length)return -1;
    const size_t leaf_count=static_cast<size_t>(lv);int64_t leaf[MaxLeaf][9]{};
    for(size_t i=0;i<leaf_count;++i){for(size_t j=0;j<9;++j)leaf[i][j]=v[pos++];if(!valid_box(leaf[i])||leaf[i][8]<0||leaf[i][8]>=32||seen[leaf[i][8]])return -1;seen[leaf[i][8]]=true;}
    if(pos!=length||seen[new_id])return -1;
    size_t choices[MaxDepth]{};
    for(size_t level=0;level<depth;++level){int64_t best=-1;for(size_t i=0;i<counts[level];++i){int64_t joined[8];for(size_t d=0;d<4;++d){joined[d]=branches[level][i][d]<incoming[d]?branches[level][i][d]:incoming[d];joined[4+d]=branches[level][i][4+d]>incoming[4+d]?branches[level][i][4+d]:incoming[4+d];}const int64_t p=volume(joined)-volume(branches[level][i]);if(best<0||p<best){best=p;choices[level]=i;}}}
    if(depth>0){int64_t pre[8];box_union(&leaf[0][0],leaf_count,9,pre);for(size_t rev=depth;rev>0;--rev){const size_t level=rev-1;if(!same_box(branches[level][choices[level]],pre))return -1;box_union(&branches[level][0][0],counts[level],8,pre);}}
    int64_t staged[MaxLeaf+1][8]{};for(size_t i=0;i<leaf_count;++i)for(size_t d=0;d<8;++d)staged[i][d]=leaf[i][d];for(size_t d=0;d<8;++d)staged[leaf_count][d]=incoming[d];
    int64_t child[8];box_union(&staged[0][0],leaf_count+1,8,child);
    int64_t result[MaxWords];size_t outn=0;result[outn++]=static_cast<int64_t>(depth);result[outn++]=new_id;for(size_t i=0;i<depth;++i)result[outn++]=static_cast<int64_t>(choices[i]);for(size_t d=0;d<8;++d)result[outn++]=child[d];
    for(size_t rev=depth;rev>0;--rev){const size_t level=rev-1;for(size_t d=0;d<8;++d)branches[level][choices[level]][d]=child[d];box_union(&branches[level][0][0],counts[level],8,child);for(size_t d=0;d<8;++d)result[outn++]=child[d];}
    const size_t bytes=outn*8;if(output==nullptr||output_capacity<bytes)return -2;for(size_t i=0;i<outn;++i)write_i64(output,i,result[i]);return static_cast<int64_t>(bytes);
}
