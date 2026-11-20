#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxN=8,kMaxM=9,kMaxStates=1023,kMaxZdd=511,kMaxInput=23,kRadix=2048;
struct Edge{int u=0,v=0;};
struct Memo{int level=0;std::array<std::uint8_t,kMaxN> mate{};int result=0;};
struct ZNode{int level=0,low=0,high=0;};
struct Context{
 int n=0,m=0,source=0,target=0,memo_count=0,node_count=0;
 std::array<Edge,kMaxM> edges{};std::array<int,kMaxN> last{};
 std::array<Memo,kMaxStates> memo{};std::array<ZNode,kMaxZdd> nodes{};
};
int degree_of(const std::array<std::uint8_t,kMaxN>& mate,int v){if(mate[v]==v+1)return 0;if(mate[v]==0)return 2;return 1;}
int transition(const Context& c,int level,const std::array<std::uint8_t,kMaxN>& mate,int selected,
               std::array<std::uint8_t,kMaxN>& next){
 next=mate;
 if(selected){
  const int u=c.edges[level].u,v=c.edges[level].v,du=degree_of(next,u),dv=degree_of(next,v);
  if(du==2||dv==2)return 0;
  if((u==c.source||u==c.target)&&du==1)return 0;
  if((v==c.source||v==c.target)&&dv==1)return 0;
  const int mu=next[u],mv=next[v];if(mu==v+1&&mv==u+1)return 0;
  if((mu==c.source+1&&mv==c.target+1)||(mu==c.target+1&&mv==c.source+1)){
   for(int w=0;w<c.n;w++)if(w!=c.source&&w!=c.target&&w!=u&&w!=v&&degree_of(next,w)==1)return 0;
   return 2;
  }
  next[u]=0;next[v]=0;next[mu-1]=static_cast<std::uint8_t>(mv);next[mv-1]=static_cast<std::uint8_t>(mu);
 }
 for(int w=0;w<c.n;w++)if(c.last[w]==level){
  const int d=degree_of(next,w);
  if(w==c.source||w==c.target){if(d==0)return 0;}
  else{if(d==1)return 0;next[w]=static_cast<std::uint8_t>(w+1);}
 }
 return 1;
}
int make_node(Context& c,int level,int low,int high){
 if(high==0)return low;
 for(int i=0;i<c.node_count;i++){const auto& node=c.nodes[i];if(node.level==level&&node.low==low&&node.high==high)return i+2;}
 if(c.node_count>=kMaxZdd)return -1;
 c.nodes[c.node_count]={level,low,high};return (c.node_count++)+2;
}
int memo_find(const Context& c,int level,const std::array<std::uint8_t,kMaxN>& mate){
 for(int i=0;i<c.memo_count;i++)if(c.memo[i].level==level){bool equal=true;for(int v=0;v<c.n;v++)if(c.memo[i].mate[v]!=mate[v]){equal=false;break;}if(equal)return c.memo[i].result;}
 return -1;
}
int solve(Context& c,int level,const std::array<std::uint8_t,kMaxN>& mate){
 if(level==c.m)return 0;const int cached=memo_find(c,level,mate);if(cached>=0)return cached;
 std::array<std::uint8_t,kMaxN> next{};int low=transition(c,level,mate,0,next)?solve(c,level+1,next):0;
 const int status=transition(c,level,mate,1,next);int high=status==0?0:(status==2?1:solve(c,level+1,next));
 const int result=make_node(c,level,low,high);if(result<0||c.memo_count>=kMaxStates)return -1;
 auto& entry=c.memo[c.memo_count++];entry.level=level;entry.mate=mate;entry.result=result;return result;
}
int reachable_nodes(const Context& c,int root){
 std::array<bool,kMaxZdd+2> seen{};std::array<int,2*kMaxZdd+3> stack{};int top=0,count=0;stack[top++]=root;
 while(top){const int id=stack[--top];if(id<=1||seen[id])continue;seen[id]=true;++count;const auto node=c.nodes[id-2];stack[top++]=node.low;stack[top++]=node.high;}
 return count;
}
}

extern "C" std::int64_t simpath_st_paths_zdd(const std::int64_t* input,std::size_t length){
 if(input==nullptr||length<4||length>kMaxInput)return -1;
 const auto n64=input[0],m64=input[1],s64=input[2],t64=input[3];
 if(n64<2||n64>kMaxN||m64<0||m64>kMaxM||s64<0||s64>=n64||t64<0||t64>=n64||s64==t64||length!=4+2*static_cast<std::size_t>(m64))return -1;
 Context c{};c.n=static_cast<int>(n64);c.m=static_cast<int>(m64);c.source=static_cast<int>(s64);c.target=static_cast<int>(t64);c.last.fill(-1);
 for(int i=0;i<c.m;i++){const auto u=input[4+2*i],v=input[5+2*i];if(u<0||u>=v||v>=n64)return -1;for(int j=0;j<i;j++)if(c.edges[j].u==u&&c.edges[j].v==v)return -1;c.edges[i]={static_cast<int>(u),static_cast<int>(v)};c.last[u]=c.last[v]=i;}
 std::array<std::uint8_t,kMaxN> initial{};for(int v=0;v<c.n;v++)initial[v]=static_cast<std::uint8_t>(v+1);
 const int root=solve(c,0,initial);if(root<0)return -1;
 std::array<std::uint16_t,kMaxZdd+2> ways{};ways[1]=1;
 for(int id=2;id<c.node_count+2;id++){const auto node=c.nodes[id-2];ways[id]=static_cast<std::uint16_t>(ways[node.low]+ways[node.high]);}
 const int zdd_count=reachable_nodes(c,root),path_count=ways[root];if(path_count>=kRadix)return -1;
 return static_cast<std::int64_t>(zdd_count)*kRadix+path_count;
}
