#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_OPS=128;
constexpr int MAX_LEVELS=8;
constexpr std::int64_t MIN_KEY=-2147483647LL,MAX_KEY=2147483646LL;
struct Node{std::int64_t key;void* value;int next[MAX_LEVELS];};
int marker=1;
int random_level(std::uint32_t&state){int level=1;do{state^=state<<13;state^=state>>17;state^=state<<5;if((state&1U)!=0)break;++level;}while(level<MAX_LEVELS);return level;}
int find_update(Node*nodes,int active,std::int64_t key,int update[MAX_LEVELS]){int current=0;for(int level=active-1;level>=0;--level){while(nodes[current].next[level]!=0&&nodes[nodes[current].next[level]].key<key)current=nodes[current].next[level];update[level]=current;}return nodes[current].next[0];}
bool contains(Node*nodes,int active,std::int64_t key){int update[MAX_LEVELS]{};const int found=find_update(nodes,active,key,update);return found!=0&&nodes[found].value!=nullptr;}
void insert(Node*nodes,int&next,int&active,std::uint32_t&rng,std::int64_t key){int update[MAX_LEVELS]{};(void)find_update(nodes,active,key,update);const int height=random_level(rng);if(height>active){for(int level=active;level<height;++level)update[level]=0;active=height;}const int id=next++;nodes[id].key=key;nodes[id].value=&marker;for(int level=0;level<height;++level){nodes[id].next[level]=nodes[update[level]].next[level];nodes[update[level]].next[level]=id;}}
bool erase(Node*nodes,int active,std::int64_t key){int update[MAX_LEVELS]{};const int found=find_update(nodes,active,key,update);if(found==0||nodes[found].key!=key)return false;for(int level=0;level<active;++level)if(nodes[update[level]].next[level]==found)nodes[update[level]].next[level]=nodes[found].next[level];return true;}
void put_i64(std::uint8_t*out,std::size_t offset,std::int64_t value){const auto bits=static_cast<std::uint64_t>(value);for(std::size_t byte=0;byte<8;++byte)out[offset+byte]=static_cast<std::uint8_t>(bits>>(8*byte));}
}
extern "C" std::int64_t skip_list_unique_key_set(const std::int64_t*input,std::size_t length,std::uint8_t*output,std::size_t capacity) noexcept{
 if(input==nullptr||length<1||input[0]<0||input[0]>static_cast<std::int64_t>(MAX_OPS)||length!=1+2*static_cast<std::size_t>(input[0]))return -1;
 const auto ops=static_cast<std::size_t>(input[0]);for(std::size_t i=0;i<ops;++i){const auto op=input[1+2*i],key=input[2+2*i];if(op<0||op>2||key<MIN_KEY||key>MAX_KEY)return -1;}
 Node nodes[MAX_OPS+1]{};int next=1,active=1;std::uint32_t rng=0x9e3779b9U;
 for(std::size_t i=0;i<ops;++i){const auto op=input[1+2*i],key=input[2+2*i];if(op==0){if(contains(nodes,active,key))return -1;insert(nodes,next,active,rng,key);}else if(op==1){(void)contains(nodes,active,key);}else if(!erase(nodes,active,key))return -1;}
 std::size_t count=0;for(int id=nodes[0].next[0];id!=0;id=nodes[id].next[0])++count;const std::size_t required=count*8;if(output==nullptr||capacity<required)return -2;
 std::size_t i=0;for(int id=nodes[0].next[0];id!=0;id=nodes[id].next[0])put_i64(output,8*i++,nodes[id].key);return static_cast<std::int64_t>(required);
}
