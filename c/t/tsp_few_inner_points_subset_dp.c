#include <stddef.h>
#include <stdint.h>

typedef struct { int64_t x, y; } Point;
static const int64_t INF = INT64_MAX / 4;

static int64_t distance_scaled(Point a, Point b) {
    int64_t dx=a.x-b.x, dy=a.y-b.y;
    int64_t square=(dx*dx+dy*dy)*INT64_C(1000000);
    int64_t lo=0,hi=3000000;
    while(lo<hi){int64_t mid=lo+(hi-lo+1)/2;if(mid*mid<=square)lo=mid;else hi=mid-1;}
    int64_t up=lo+1;
    if(up*up-square < square-lo*lo)return up;
    return lo;
}

static int64_t add_cost(int64_t a,int64_t b){return a>=INF?INF:a+b;}

static int64_t solve_subset_dp(const int *outer,int outer_n,const int *inner,int k,const Point *p){
    int states=1<<k,sentinel=k;
    int64_t previous[64*7],current[64*7];
    for(int cell=0;cell<states*7;++cell)previous[cell]=INF;
    previous[sentinel]=0;
    for(int mask=0;mask<states;++mask){
        for(int last=0;last<=k;++last){
            if(last<k && !(mask&(1<<last)))continue;
            int64_t prefix=previous[mask*7+last];if(prefix>=INF)continue;
            int vertex=last==sentinel?outer[0]:inner[last];
            for(int next=0;next<k;++next){
                int bit=1<<next;if(mask&bit)continue;
                int next_mask=mask|bit;
                int64_t candidate=add_cost(prefix,distance_scaled(p[vertex],p[inner[next]]));
                if(candidate<previous[next_mask*7+next])previous[next_mask*7+next]=candidate;
            }
        }
    }
    for(int i=1;i<outer_n;++i){
        for(int cell=0;cell<states*7;++cell)current[cell]=INF;
        for(int mask=0;mask<states;++mask){
            for(int last=0;last<=k;++last){
                if(last<k && !(mask&(1<<last)))continue;
                int64_t prefix=previous[mask*7+last];if(prefix>=INF)continue;
                int vertex=last==sentinel?outer[i-1]:inner[last];
                int64_t candidate=add_cost(prefix,distance_scaled(p[vertex],p[outer[i]]));
                if(candidate<current[mask*7+sentinel])current[mask*7+sentinel]=candidate;
            }
        }
        for(int mask=0;mask<states;++mask){
            for(int last=0;last<=k;++last){
                if(last<k && !(mask&(1<<last)))continue;
                int64_t prefix=current[mask*7+last];if(prefix>=INF)continue;
                int vertex=last==sentinel?outer[i]:inner[last];
                for(int next=0;next<k;++next){
                    int bit=1<<next;if(mask&bit)continue;
                    int next_mask=mask|bit;
                    int64_t candidate=add_cost(prefix,distance_scaled(p[vertex],p[inner[next]]));
                    if(candidate<current[next_mask*7+next])current[next_mask*7+next]=candidate;
                }
            }
        }
        for(int cell=0;cell<states*7;++cell)previous[cell]=current[cell];
    }
    int full=states-1;int64_t best=INF;
    for(int last=0;last<=k;++last){
        if(last<k && !(full&(1<<last)))continue;
        int vertex=last==sentinel?outer[outer_n-1]:inner[last];
        int64_t candidate=add_cost(previous[full*7+last],distance_scaled(p[vertex],p[outer[0]]));
        if(candidate<best)best=candidate;
    }
    return best;
}

static void put_i64(uint8_t *out,int64_t x){uint64_t b=(uint64_t)x;for(int i=0;i<8;++i)out[i]=(uint8_t)(b>>(8*i));}

int64_t tsp_few_inner_points_subset_dp(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
    if(!input||length<2||length>51)return -1;
    int64_t n0=input[0],k0=input[1];
    if(n0<3||n0>16||k0<0||k0>6||k0>n0-3||length!=2+3*(size_t)n0)return -1;
    int n=(int)n0,k=(int)k0,outer_n=n-k,outer[16],inner[6];uint8_t seen[16]={0};
    for(int i=0;i<outer_n;++i){int64_t id=input[2+i];if(id<0||id>=n0||seen[id])return -1;outer[i]=(int)id;seen[id]=1;}
    for(int i=0;i<k;++i){int64_t id=input[2+outer_n+i];if(id<0||id>=n0||seen[id])return -1;inner[i]=(int)id;seen[id]=1;}
    for(int i=0;i<n;++i)if(!seen[i])return -1;
    Point p[16];size_t coord=2+(size_t)n;
    for(int i=0;i<n;++i){int64_t x=input[coord+2*i],y=input[coord+2*i+1];if(x< -1000||x>1000||y< -1000||y>1000)return -1;p[i]=(Point){x,y};for(int j=0;j<i;++j)if(p[i].x==p[j].x&&p[i].y==p[j].y)return -1;}
    int64_t best=solve_subset_dp(outer,outer_n,inner,k,p);
    if(!output||capacity<8)return -2;put_i64(output,best);return 8;
}
