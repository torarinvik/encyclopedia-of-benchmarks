#include <array>
#include <cstddef>
#include <cstdint>
#include <cmath>

namespace {
constexpr int max_cells = 400, inf_cost = 1000000;
int heuristic(int a, int b, int cols) { const int dy=a/cols-b/cols, dx=a%cols-b%cols; return static_cast<int>(std::sqrt(static_cast<double>(dy*dy+dx*dx))); }
void put(std::uint8_t* out, std::size_t slot, std::int64_t value) { const auto bits=static_cast<std::uint64_t>(value); for(std::size_t i=0;i<8;++i) out[slot*8+i]=static_cast<std::uint8_t>(bits>>(i*8)); }
}
extern "C" std::int64_t bidirectional_a_star(const std::int64_t* in,std::size_t length,std::uint8_t* out,std::size_t capacity) {
 if(!in||length<6||in[0]<1||in[0]>20||in[1]<1||in[1]>20)return -1;
 const int rows=static_cast<int>(in[0]),cols=static_cast<int>(in[1]),cells=rows*cols;
 if(in[2]<0||in[2]>=rows||in[3]<0||in[3]>=cols||in[4]<0||in[4]>=rows||in[5]<0||in[5]>=cols||length!=static_cast<std::size_t>(6+cells))return -1;
 const int start=static_cast<int>(in[2]*cols+in[3]),goal=static_cast<int>(in[4]*cols+in[5]);std::array<int,max_cells> blocked{};
 for(int i=0;i<cells;++i){if(in[6+i]!=0&&in[6+i]!=1)return -1;blocked[i]=static_cast<int>(in[6+i]);}if(blocked[start]||blocked[goal])return -1;
 std::array<std::array<int,max_cells>,2> g{},parent{},order{};std::array<std::array<bool,max_cells>,2> open{},closed{};std::array<int,2> seq{};
 for(int s=0;s<2;++s)for(int i=0;i<cells;++i){g[s][i]=inf_cost;parent[s][i]=-1;}g[0][start]=g[1][goal]=0;open[0][start]=open[1][goal]=true;order[0][start]=seq[0]++;order[1][goal]=seq[1]++;
 constexpr int dr[4]={-1,0,1,0},dc[4]={0,-1,0,1};int best=inf_cost,meet=-1;
 while(true){int min_g[2]={inf_cost,inf_cost};for(int s=0;s<2;++s)for(int v=0;v<cells;++v)if(open[s][v]&&g[s][v]<min_g[s])min_g[s]=g[s][v];if(best<inf_cost&&(min_g[0]==inf_cost||min_g[1]==inf_cost||min_g[0]+min_g[1]>=best))break;
  for(int s=0;s<2;++s){int target=s==0?goal:start,chosen=-1,best_f=inf_cost;for(int v=0;v<cells;++v)if(open[s][v]){int f=g[s][v]+heuristic(v,target,cols);if(chosen<0||f<best_f||(f==best_f&&order[s][v]<order[s][chosen])){chosen=v;best_f=f;}}if(chosen<0)continue;open[s][chosen]=false;closed[s][chosen]=true;if(g[1-s][chosen]<inf_cost&&g[s][chosen]+g[1-s][chosen]<best){best=g[s][chosen]+g[1-s][chosen];meet=chosen;}int y=chosen/cols,x=chosen%cols;
   for(int d=0;d<4;++d){int ny=y+dr[d],nx=x+dc[d];if(ny<0||ny>=rows||nx<0||nx>=cols)continue;int v=ny*cols+nx;if(blocked[v]||closed[s][v])continue;int ng=g[s][chosen]+1;if(ng<g[s][v]){g[s][v]=ng;parent[s][v]=chosen;open[s][v]=true;order[s][v]=seq[s]++;if(g[1-s][v]<inf_cost&&ng+g[1-s][v]<best){best=ng+g[1-s][v];meet=v;}}}
  }
  bool any=false;for(int s=0;s<2;++s)for(int v=0;v<cells;++v)any=any||open[s][v];if(!any)break;
 }
 std::array<int,max_cells> path{},rev{};int count=0;if(meet<0)path[count++]=start;else{int rn=0;for(int v=meet;v>=0;v=parent[0][v])rev[rn++]=v;while(rn>0)path[count++]=rev[--rn];for(int v=parent[1][meet];v>=0;v=parent[1][v])path[count++]=v;}
 const std::size_t bytes=(1+2*static_cast<std::size_t>(count))*8;if(!out||capacity<bytes)return -2;put(out,0,count);for(int i=0;i<count;++i){put(out,1+2*static_cast<std::size_t>(i),path[i]/cols);put(out,2+2*static_cast<std::size_t>(i),path[i]%cols);}return static_cast<std::int64_t>(bytes);
}
