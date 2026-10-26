module tsp_few_inner_points;
const long TSP_INF = 2305843009213693951;
struct Point { long x; long y; }

fn long dist_scaled(Point a, Point b) {
    long dx=a.x-b.x,dy=a.y-b.y,sq=(dx*dx+dy*dy)*1000000;
    long lo=0,hi=3000000;
    while(lo<hi){long mid=lo+(hi-lo+1)/2;if(mid*mid<=sq)lo=mid;else hi=mid-1;}
    long up=lo+1;if(up*up-sq<sq-lo*lo)return up;return lo;
}
fn long add_cost(long a,long b){if(a>=TSP_INF)return TSP_INF;return a+b;}
fn long solve_order(usz* outer,usz outer_n,usz* order,usz k,Point* points){
    long[7] po,pi,co,ci;for(usz j=0;j<=k;j++){po[j]=TSP_INF;pi[j]=TSP_INF;}po[0]=0;
    for(usz j=1;j<=k;j++){long a=add_cost(po[j-1],dist_scaled(points[outer[0]],points[order[j-1]]));long b=TSP_INF;if(j>1)b=add_cost(pi[j-1],dist_scaled(points[order[j-2]],points[order[j-1]]));pi[j]=a<b?a:b;}
    for(usz i=1;i<outer_n;i++){
        for(usz j=0;j<=k;j++){co[j]=TSP_INF;ci[j]=TSP_INF;}long edge=dist_scaled(points[outer[i-1]],points[outer[i]]);co[0]=add_cost(po[0],edge);
        for(usz j=1;j<=k;j++){long a=add_cost(po[j],edge);long b=add_cost(pi[j],dist_scaled(points[order[j-1]],points[outer[i]]));co[j]=a<b?a:b;}
        for(usz j=1;j<=k;j++){long a=add_cost(co[j-1],dist_scaled(points[outer[i]],points[order[j-1]]));long b=TSP_INF;if(j>1)b=add_cost(ci[j-1],dist_scaled(points[order[j-2]],points[order[j-1]]));ci[j]=a<b?a:b;}
        for(usz j=0;j<=k;j++){po[j]=co[j];pi[j]=ci[j];}
    }
    long best=add_cost(po[k],dist_scaled(points[outer[outer_n-1]],points[outer[0]]));if(k>0){long close=add_cost(pi[k],dist_scaled(points[order[k-1]],points[outer[0]]));if(close<best)best=close;}return best;
}
fn bool next_perm(usz[6]* a,usz n){if(n<2)return false;isz i=(isz)n-2;while(i>=0&&a[(usz)i]>=a[(usz)i+1])i--;if(i<0)return false;usz j=n-1;while(a[j]<=a[(usz)i])j--;usz t=a[(usz)i];a[(usz)i]=a[j];a[j]=t;usz l=(usz)i+1,r=n-1;while(l<r){t=a[l];a[l]=a[r];a[r]=t;l++;r--;}return true;}
fn void put_i64(uint8* out,long x){ulong b=(ulong)x;for(usz i=0;i<8;i++)out[i]=(uint8)(b>>(8*i));}

fn long tsp_few_inner_points(long* input,usz length,uint8* output,usz capacity) @export("tsp_few_inner_points") {
    if(input==null||length<2||length>51)return -1;long n0=input[0],k0=input[1];if(n0<3||n0>16||k0<0||k0>6||k0>n0-3||length!=(usz)(2+3*n0))return -1;
    usz n=(usz)n0,k=(usz)k0,on=n-k;usz[16] outer;usz[6] inner;bool[16] seen;
    for(usz i=0;i<on;i++){long id=input[2+i];if(id<0||id>=n0||seen[(usz)id])return -1;outer[i]=(usz)id;seen[(usz)id]=true;}
    for(usz i=0;i<k;i++){long id=input[2+on+i];if(id<0||id>=n0||seen[(usz)id])return -1;inner[i]=(usz)id;seen[(usz)id]=true;}
    for(usz i=0;i<n;i++)if(!seen[i])return -1;
    Point[16] points;usz off=2+n;
    for(usz i=0;i<n;i++){long x=input[off+2*i],y=input[off+2*i+1];if(x< -1000||x>1000||y< -1000||y>1000)return -1;for(usz j=0;j<i;j++)if(points[j].x==x&&points[j].y==y)return -1;points[i].x=x;points[i].y=y;}
    for(usz i=1;i<k;i++){usz x=inner[i],j=i;while(j>0&&inner[j-1]>x){inner[j]=inner[j-1];j--;}inner[j]=x;}
    long best=TSP_INF;while(true){long value=solve_order(&outer,on,&inner,k,&points);if(value<best)best=value;if(!next_perm(&inner,k))break;}
    if(output==null||capacity<8)return -2;put_i64(output,best);return 8;
}
