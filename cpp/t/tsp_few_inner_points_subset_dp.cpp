#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <climits>

namespace {
struct Point { int64_t x,y; };
constexpr int64_t INF=INT64_MAX/4;
int64_t dist_scaled(Point a,Point b){int64_t dx=a.x-b.x,dy=a.y-b.y,sq=(dx*dx+dy*dy)*INT64_C(1000000),lo=0,hi=3000000;while(lo<hi){int64_t mid=lo+(hi-lo+1)/2;if(mid*mid<=sq)lo=mid;else hi=mid-1;}int64_t up=lo+1;return up*up-sq<sq-lo*lo?up:lo;}
int64_t add(int64_t a,int64_t b){return a>=INF?INF:a+b;}
int64_t solve(const int *outer,int outer_n,const int *inner,int k,const Point *p){
 const int states=1<<k,sentinel=k;int64_t previous[64*7],current[64*7];
 for(int cell=0;cell<states*7;++cell)previous[cell]=INF;previous[sentinel]=0;
 for(int mask=0;mask<states;++mask)for(int last=0;last<=k;++last){
  if(last<k&&!(mask&(1<<last)))continue;auto prefix=previous[mask*7+last];if(prefix>=INF)continue;
  auto vertex=last==sentinel?outer[0]:inner[last];
  for(int next=0;next<k;++next){int bit=1<<next;if(mask&bit)continue;int next_mask=mask|bit;
   auto candidate=add(prefix,dist_scaled(p[vertex],p[inner[next]]));previous[next_mask*7+next]=std::min(previous[next_mask*7+next],candidate);
  }
 }
 for(int i=1;i<outer_n;++i){
  for(int cell=0;cell<states*7;++cell)current[cell]=INF;
  for(int mask=0;mask<states;++mask)for(int last=0;last<=k;++last){
   if(last<k&&!(mask&(1<<last)))continue;auto prefix=previous[mask*7+last];if(prefix>=INF)continue;
   auto vertex=last==sentinel?outer[i-1]:inner[last];auto candidate=add(prefix,dist_scaled(p[vertex],p[outer[i]]));
   current[mask*7+sentinel]=std::min(current[mask*7+sentinel],candidate);
  }
  for(int mask=0;mask<states;++mask)for(int last=0;last<=k;++last){
   if(last<k&&!(mask&(1<<last)))continue;auto prefix=current[mask*7+last];if(prefix>=INF)continue;
   auto vertex=last==sentinel?outer[i]:inner[last];
   for(int next=0;next<k;++next){int bit=1<<next;if(mask&bit)continue;int next_mask=mask|bit;
    auto candidate=add(prefix,dist_scaled(p[vertex],p[inner[next]]));
    current[next_mask*7+next]=std::min(current[next_mask*7+next],candidate);
   }
  }
  for(int cell=0;cell<states*7;++cell)previous[cell]=current[cell];
 }
 const int full=states-1;int64_t best=INF;
 for(int last=0;last<=k;++last){if(last<k&&!(full&(1<<last)))continue;auto vertex=last==sentinel?outer[outer_n-1]:inner[last];
  best=std::min(best,add(previous[full*7+last],dist_scaled(p[vertex],p[outer[0]])));}
 return best;
}
void put(uint8_t *out,int64_t x){uint64_t b=static_cast<uint64_t>(x);for(int i=0;i<8;++i)out[i]=static_cast<uint8_t>(b>>(8*i));}
}

extern "C" int64_t tsp_few_inner_points_subset_dp(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
 if(!input||length<2||length>51)return -1;int64_t n0=input[0],k0=input[1];if(n0<3||n0>16||k0<0||k0>6||k0>n0-3||length!=2+3*static_cast<size_t>(n0))return -1;
 int n=static_cast<int>(n0),k=static_cast<int>(k0),on=n-k,outer[16],inner[6];bool seen[16]{};
 for(int i=0;i<on;++i){int64_t id=input[2+i];if(id<0||id>=n0||seen[id])return -1;outer[i]=static_cast<int>(id);seen[id]=true;}
 for(int i=0;i<k;++i){int64_t id=input[2+on+i];if(id<0||id>=n0||seen[id])return -1;inner[i]=static_cast<int>(id);seen[id]=true;}
 for(int i=0;i<n;++i)if(!seen[i])return -1;Point p[16];size_t off=2+n;
 for(int i=0;i<n;++i){int64_t x=input[off+2*i],y=input[off+2*i+1];if(x< -1000||x>1000||y< -1000||y>1000)return -1;p[i]={x,y};for(int j=0;j<i;++j)if(p[i].x==x&&p[i].y==y)return -1;}
 int64_t best=solve(outer,on,inner,k,p);
 if(!output||capacity<8)return -2;put(output,best);return 8;
}
