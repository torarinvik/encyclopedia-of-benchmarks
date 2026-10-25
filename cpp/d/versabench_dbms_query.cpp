#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr size_t MaxNodes=7, MaxEntries=4, MaxRecords=16;
struct Entry { int64_t lo[4], hi[4], ref; };
struct Node { int64_t level, count; Entry entries[MaxEntries]; };
bool valid_box(const int64_t *lo,const int64_t *hi) {
    for(size_t d=0;d<4;++d) if(lo[d]<-8||lo[d]>8||hi[d]<-8||hi[d]>8||lo[d]>=hi[d]) return false;
    return true;
}
bool intersects(const Entry &e,const int64_t *lo,const int64_t *hi) {
    for(size_t d=0;d<4;++d) if(lo[d]>e.hi[d]||e.lo[d]>hi[d]) return false;
    return true;
}
void write_i64(uint8_t *out,size_t word,int64_t value) {
    uint64_t bits=static_cast<uint64_t>(value);
    for(size_t b=0;b<8;++b) out[word*8+b]=static_cast<uint8_t>(bits>>(8*b));
}
}

extern "C" int64_t versabench_dbms_query(const int64_t *v,size_t length,uint8_t *output,size_t output_capacity) {
    if(v==nullptr||length<10||length>277) return -1;
    const int64_t nn=v[0], root_value=v[1];
    if(nn<1||nn>static_cast<int64_t>(MaxNodes)||root_value<0||root_value>=nn) return -1;
    const size_t n=static_cast<size_t>(nn), root=static_cast<size_t>(root_value);
    int64_t qlo[4],qhi[4];
    for(size_t d=0;d<4;++d){qlo[d]=v[2+d];qhi[d]=v[6+d];}
    if(!valid_box(qlo,qhi)) return -1;
    Node nodes[MaxNodes]{}; size_t parents[MaxNodes]{}, leaf_total=0, pos=10;
    bool seen[32]{};
    for(size_t ni=0;ni<n;++ni){
        if(pos+2>length) return -1;
        const int64_t level=v[pos++], count=v[pos++];
        if(level<0||level>2||count<1||count>static_cast<int64_t>(MaxEntries)||pos+static_cast<size_t>(count)*9>length) return -1;
        nodes[ni].level=level; nodes[ni].count=count;
        for(size_t ei=0;ei<static_cast<size_t>(count);++ei){
            Entry &e=nodes[ni].entries[ei];
            for(size_t d=0;d<4;++d)e.lo[d]=v[pos++];
            for(size_t d=0;d<4;++d)e.hi[d]=v[pos++];
            e.ref=v[pos++]; if(!valid_box(e.lo,e.hi)) return -1;
            if(level==0){if(e.ref<0||e.ref>=32||seen[e.ref]||++leaf_total>MaxRecords)return -1;seen[e.ref]=true;}
            else {if(e.ref<0||e.ref>=nn||++parents[e.ref]!=1)return -1;}
        }
    }
    if(pos!=length||parents[root]!=0)return -1;
    for(size_t ni=0;ni<n;++ni){
        if(ni!=root&&parents[ni]!=1)return -1;
        if(nodes[ni].level==0)continue;
        for(size_t ei=0;ei<static_cast<size_t>(nodes[ni].count);++ei){
            const Entry &branch=nodes[ni].entries[ei]; const Node &child=nodes[branch.ref];
            if(child.level!=nodes[ni].level-1)return -1;
            for(size_t ce=0;ce<static_cast<size_t>(child.count);++ce)for(size_t d=0;d<4;++d)
                if(branch.lo[d]>child.entries[ce].lo[d]||branch.hi[d]<child.entries[ce].hi[d])return -1;
        }
    }
    size_t stack[MaxNodes],top=0,matches[MaxRecords],match_count=0;stack[top++]=root;
    while(top){const size_t ni=stack[--top];const Node &node=nodes[ni];
        if(node.level==0){for(size_t ei=0;ei<static_cast<size_t>(node.count);++ei)if(intersects(node.entries[ei],qlo,qhi))matches[match_count++]=static_cast<size_t>(node.entries[ei].ref);}
        else {for(size_t rev=static_cast<size_t>(node.count);rev>0;--rev){const Entry &e=node.entries[rev-1];if(intersects(e,qlo,qhi))stack[top++]=static_cast<size_t>(e.ref);}}
    }
    const size_t bytes=match_count*8;
    if(output==nullptr||output_capacity<bytes)return -2;
    for(size_t i=0;i<match_count;++i)write_i64(output,i,static_cast<int64_t>(matches[i]));
    return static_cast<int64_t>(bytes);
}
