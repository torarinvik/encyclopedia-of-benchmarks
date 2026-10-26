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

static int64_t solve_order(const int *outer,int outer_n,const int *order,int k,const Point *p){
    int64_t po[7],pi[7],co[7],ci[7];
    for(int j=0;j<=k;++j)po[j]=pi[j]=INF;
    po[0]=0;
    for(int j=1;j<=k;++j){
        int64_t from_outer=add_cost(po[j-1],distance_scaled(p[outer[0]],p[order[j-1]]));
        int64_t from_inner= j>1?add_cost(pi[j-1],distance_scaled(p[order[j-2]],p[order[j-1]])):INF;
        pi[j]=from_outer<from_inner?from_outer:from_inner;
    }
    for(int i=1;i<outer_n;++i){
        for(int j=0;j<=k;++j)co[j]=ci[j]=INF;
        int64_t boundary=distance_scaled(p[outer[i-1]],p[outer[i]]);
        co[0]=add_cost(po[0],boundary);
        for(int j=1;j<=k;++j){
            int64_t a=add_cost(po[j],boundary);
            int64_t b=add_cost(pi[j],distance_scaled(p[order[j-1]],p[outer[i]]));
            co[j]=a<b?a:b;
        }
        for(int j=1;j<=k;++j){
            int64_t a=add_cost(co[j-1],distance_scaled(p[outer[i]],p[order[j-1]]));
            int64_t b=j>1?add_cost(ci[j-1],distance_scaled(p[order[j-2]],p[order[j-1]])):INF;
            ci[j]=a<b?a:b;
        }
        for(int j=0;j<=k;++j){po[j]=co[j];pi[j]=ci[j];}
    }
    int64_t best=add_cost(po[k],distance_scaled(p[outer[outer_n-1]],p[outer[0]]));
    if(k){int64_t close=add_cost(pi[k],distance_scaled(p[order[k-1]],p[outer[0]]));if(close<best)best=close;}
    return best;
}

static void sort_inner(int *a,int n){for(int i=1;i<n;++i){int x=a[i],j=i;while(j>0&&a[j-1]>x){a[j]=a[j-1];--j;}a[j]=x;}}
static int next_perm(int *a,int n){int i=n-2;while(i>=0&&a[i]>=a[i+1])--i;if(i<0)return 0;int j=n-1;while(a[j]<=a[i])--j;int t=a[i];a[i]=a[j];a[j]=t;for(int l=i+1,r=n-1;l<r;++l,--r){t=a[l];a[l]=a[r];a[r]=t;}return 1;}
static void put_i64(uint8_t *out,int64_t x){uint64_t b=(uint64_t)x;for(int i=0;i<8;++i)out[i]=(uint8_t)(b>>(8*i));}

int64_t tsp_few_inner_points(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
    if(!input||length<2||length>51)return -1;
    int64_t n0=input[0],k0=input[1];
    if(n0<3||n0>16||k0<0||k0>6||k0>n0-3||length!=2+3*(size_t)n0)return -1;
    int n=(int)n0,k=(int)k0,outer_n=n-k,outer[16],inner[6];uint8_t seen[16]={0};
    for(int i=0;i<outer_n;++i){int64_t id=input[2+i];if(id<0||id>=n0||seen[id])return -1;outer[i]=(int)id;seen[id]=1;}
    for(int i=0;i<k;++i){int64_t id=input[2+outer_n+i];if(id<0||id>=n0||seen[id])return -1;inner[i]=(int)id;seen[id]=1;}
    for(int i=0;i<n;++i)if(!seen[i])return -1;
    Point p[16];size_t coord=2+(size_t)n;
    for(int i=0;i<n;++i){int64_t x=input[coord+2*i],y=input[coord+2*i+1];if(x< -1000||x>1000||y< -1000||y>1000)return -1;p[i]=(Point){x,y};for(int j=0;j<i;++j)if(p[i].x==p[j].x&&p[i].y==p[j].y)return -1;}
    sort_inner(inner,k);int64_t best=INF;
    do{int64_t value=solve_order(outer,outer_n,inner,k,p);if(value<best)best=value;}while(k>1&&next_perm(inner,k));
    if(!output||capacity<8)return -2;put_i64(output,best);return 8;
}
