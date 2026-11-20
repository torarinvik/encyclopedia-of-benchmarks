module tsp_few_inner_points_subset_dp;
const long TSP_INF = 2305843009213693951;
struct Point { long x; long y; }

fn long dist_scaled(Point a, Point b) {
    long dx=a.x-b.x,dy=a.y-b.y,sq=(dx*dx+dy*dy)*1000000;
    long lo=0,hi=3000000;
    while(lo<hi){long mid=lo+(hi-lo+1)/2;if(mid*mid<=sq)lo=mid;else hi=mid-1;}
    long up=lo+1;if(up*up-sq<sq-lo*lo)return up;return lo;
}
fn long add_cost(long a,long b){if(a>=TSP_INF)return TSP_INF;return a+b;}
fn long solve_subset(usz* outer,usz outer_n,usz* inner,usz k,Point* points){
    usz states=(usz)1<<k,sentinel=k;long[448] previous,current;
    for(usz cell=0;cell<states*7;cell++)previous[cell]=TSP_INF;previous[sentinel]=0;
    for(usz mask=0;mask<states;mask++)for(usz last=0;last<=k;last++){
        if(last<k&&(mask&((usz)1<<last))==0)continue;long prefix=previous[mask*7+last];if(prefix>=TSP_INF)continue;
        usz vertex=last==sentinel?outer[0]:inner[last];
        for(usz next=0;next<k;next++){usz bit=(usz)1<<next;if(mask&bit)continue;usz next_mask=mask|bit;
            long candidate=add_cost(prefix,dist_scaled(points[vertex],points[inner[next]]));if(candidate<previous[next_mask*7+next])previous[next_mask*7+next]=candidate;
        }
    }
    for(usz i=1;i<outer_n;i++){
        for(usz cell=0;cell<states*7;cell++)current[cell]=TSP_INF;
        for(usz mask=0;mask<states;mask++)for(usz last=0;last<=k;last++){
            if(last<k&&(mask&((usz)1<<last))==0)continue;long prefix=previous[mask*7+last];if(prefix>=TSP_INF)continue;
            usz vertex=last==sentinel?outer[i-1]:inner[last];long candidate=add_cost(prefix,dist_scaled(points[vertex],points[outer[i]]));
            if(candidate<current[mask*7+sentinel])current[mask*7+sentinel]=candidate;
        }
        for(usz mask=0;mask<states;mask++)for(usz last=0;last<=k;last++){
            if(last<k&&(mask&((usz)1<<last))==0)continue;long prefix=current[mask*7+last];if(prefix>=TSP_INF)continue;
            usz vertex=last==sentinel?outer[i]:inner[last];
            for(usz next=0;next<k;next++){usz bit=(usz)1<<next;if(mask&bit)continue;usz next_mask=mask|bit;
                long candidate=add_cost(prefix,dist_scaled(points[vertex],points[inner[next]]));
                if(candidate<current[next_mask*7+next])current[next_mask*7+next]=candidate;
            }
        }
        for(usz cell=0;cell<states*7;cell++)previous[cell]=current[cell];
    }
    usz full=states-1;long best=TSP_INF;
    for(usz last=0;last<=k;last++){if(last<k&&(full&((usz)1<<last))==0)continue;usz vertex=last==sentinel?outer[outer_n-1]:inner[last];long candidate=add_cost(previous[full*7+last],dist_scaled(points[vertex],points[outer[0]]));if(candidate<best)best=candidate;}
    return best;
}
fn void put_i64(char* out,long x){ulong b=(ulong)x;for(usz i=0;i<8;i++)out[i]=(char)(b>>(8*i));}

fn long tsp_few_inner_points_subset_dp(long* input,usz length,char* output,usz capacity) @export("tsp_few_inner_points_subset_dp") {
    if(input==null||length<2||length>51)return -1;long n0=input[0],k0=input[1];if(n0<3||n0>16||k0<0||k0>6||k0>n0-3||length!=(usz)(2+3*n0))return -1;
    usz n=(usz)n0,k=(usz)k0,on=n-k;usz[16] outer;usz[6] inner;bool[16] seen;
    for(usz i=0;i<on;i++){long id=input[2+i];if(id<0||id>=n0||seen[(usz)id])return -1;outer[i]=(usz)id;seen[(usz)id]=true;}
    for(usz i=0;i<k;i++){long id=input[2+on+i];if(id<0||id>=n0||seen[(usz)id])return -1;inner[i]=(usz)id;seen[(usz)id]=true;}
    for(usz i=0;i<n;i++)if(!seen[i])return -1;
    Point[16] points;usz off=2+n;
    for(usz i=0;i<n;i++){long x=input[off+2*i],y=input[off+2*i+1];if(x< -1000||x>1000||y< -1000||y>1000)return -1;for(usz j=0;j<i;j++)if(points[j].x==x&&points[j].y==y)return -1;points[i].x=x;points[i].y=y;}
    long best=solve_subset(&outer,on,&inner,k,&points);
    if(output==null||capacity<8)return -2;put_i64(output,best);return 8;
}
