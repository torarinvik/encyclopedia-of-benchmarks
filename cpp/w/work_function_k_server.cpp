// Clean-room bounded work-function algorithm for finite k-server metrics.
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t kMaxP = 6, kMaxK = 3, kMaxR = 8, kMaxConfigs = 20, kMaxInput = 50;
struct Config { std::int64_t point[kMaxK]{}; };
void store_i64_le(std::uint8_t* out, std::size_t offset, std::int64_t value) {
  std::uint64_t bits = static_cast<std::uint64_t>(value);
  for (std::size_t b = 0; b < 8; ++b) { out[offset+b] = static_cast<std::uint8_t>(bits & 255u); bits >>= 8; }
}
void sort_config(std::int64_t* x, std::size_t k) { std::sort(x, x+k); }
std::size_t find_config(const Config* configs, std::size_t count, const std::int64_t* x, std::size_t k) {
  for (std::size_t i=0;i<count;++i) if (std::equal(x,x+k,configs[i].point)) return i;
  return count;
}
std::int64_t config_distance(const std::int64_t* a,const std::int64_t* b,std::size_t k,
                              std::int64_t d[kMaxP][kMaxP]) {
  if(k==1) return d[a[0]][b[0]];
  if(k==2) return std::min(d[a[0]][b[0]]+d[a[1]][b[1]],d[a[0]][b[1]]+d[a[1]][b[0]]);
  constexpr std::size_t p[6][3]={{0,1,2},{0,2,1},{1,0,2},{1,2,0},{2,0,1},{2,1,0}};
  auto best=std::numeric_limits<std::int64_t>::max();
  for(auto& q:p) best=std::min(best,d[a[0]][b[q[0]]]+d[a[1]][b[q[1]]]+d[a[2]][b[q[2]]]);
  return best;
}
}

extern "C" std::int64_t work_function_k_server(const std::int64_t* input,std::size_t length,
    std::uint8_t* output,std::size_t capacity) {
  if(!input||length<3||length>kMaxInput) return -1;
  auto p64=input[0],k64=input[1],n64=input[2];
  if(p64<2||p64>6||k64<1||k64>3||k64>p64||n64<0||n64>8) return -1;
  auto p=static_cast<std::size_t>(p64),k=static_cast<std::size_t>(k64),n=static_cast<std::size_t>(n64);
  auto initial_start=3+p*p, requests_start=initial_start+k;
  if(length!=requests_start+n) return -1;
  std::int64_t d[kMaxP][kMaxP]{};
  for(std::size_t i=0;i<p;++i) for(std::size_t j=0;j<p;++j){auto x=input[3+i*p+j];if(x<0||x>1000||(i==j&&x!=0)||(i!=j&&x==0))return -1;d[i][j]=x;}
  for(std::size_t i=0;i<p;++i) for(std::size_t j=0;j<p;++j){if(d[i][j]!=d[j][i])return -1;for(std::size_t z=0;z<p;++z)if(d[i][j]>d[i][z]+d[z][j])return -1;}
  std::int64_t initial[kMaxK]{},requests[kMaxR]{};
  for(std::size_t i=0;i<k;++i){auto x=input[initial_start+i];if(x<0||x>=p64)return -1;initial[i]=x;for(std::size_t j=0;j<i;++j)if(initial[j]==x)return -1;}
  sort_config(initial,k);
  for(std::size_t t=0;t<n;++t){requests[t]=input[requests_start+t];if(requests[t]<0||requests[t]>=p64)return -1;}
  auto output_bytes=8*(2+n*k);if(!output||capacity<output_bytes)return -2;
  Config configs[kMaxConfigs]{};std::size_t count=0;
  for(std::size_t a=0;a<p;++a){if(k==1){configs[count++].point[0]=a;continue;}for(std::size_t b=a+1;b<p;++b){if(k==2){configs[count].point[0]=a;configs[count++].point[1]=b;continue;}for(std::size_t c=b+1;c<p;++c){configs[count].point[0]=a;configs[count].point[1]=b;configs[count++].point[2]=c;}}}
  std::int64_t work[kMaxConfigs]{},next[kMaxConfigs]{};
  for(std::size_t x=0;x<count;++x)work[x]=config_distance(initial,configs[x].point,k,d);
  std::int64_t staged[2+kMaxR*kMaxK]{};staged[0]=n;staged[1]=k;
  std::int64_t current[kMaxK]{};for(std::size_t j=0;j<k;++j)current[j]=initial[j];
  for(std::size_t t=0;t<n;++t){
    auto r=requests[t];
    for(std::size_t x=0;x<count;++x){next[x]=std::numeric_limits<std::int64_t>::max();for(std::size_t y=0;y<count;++y){bool contains=false;for(std::size_t j=0;j<k;++j)if(configs[y].point[j]==r)contains=true;if(!contains)continue;auto v=work[y]+config_distance(configs[y].point,configs[x].point,k,d);next[x]=std::min(next[x],v);}}
    auto best=std::numeric_limits<std::int64_t>::max();std::int64_t chosen[kMaxK]{};std::size_t bestslot=0;bool already=false;
    for(std::size_t j=0;j<k;++j){chosen[j]=current[j];if(current[j]==r)already=true;}
    if(!already)for(std::size_t slot=0;slot<k;++slot){std::int64_t cand[kMaxK]{};for(std::size_t j=0;j<k;++j)cand[j]=j==slot?r:current[j];sort_config(cand,k);auto idx=find_config(configs,count,cand,k);auto score=work[idx]+d[current[slot]][r];if(score<best||(score==best&&slot<bestslot)){best=score;bestslot=slot;for(std::size_t j=0;j<k;++j)chosen[j]=cand[j];}}
    for(std::size_t j=0;j<k;++j){staged[2+t*k+j]=chosen[j];current[j]=chosen[j];}
    for(std::size_t x=0;x<count;++x)work[x]=next[x];
  }
  for(std::size_t i=0;i<2+n*k;++i)store_i64_le(output,8*i,staged[i]);
  return static_cast<std::int64_t>(output_bytes);
}
