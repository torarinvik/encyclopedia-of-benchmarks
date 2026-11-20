module gpsr_perimeter_recovery_trace;

const usz MAX_N=8; const usz MAX_M=18; const usz MAX_INPUT=57; const usz MAX_OUTPUT=896; const usz MAX_PATH=37;
struct Point { long x; long y; }

fn long cross(long ax,long ay,long bx,long by){return ax*by-ay*bx;}
fn long orient(Point a,Point b,Point c){return cross(b.x-a.x,b.y-a.y,c.x-a.x,c.y-a.y);}
fn int half(long x,long y){return y>0||(y==0&&x>=0)?0:1;}
fn bool angle_less(long ax,long ay,usz ai,long bx,long by,usz bi){int ha=half(ax,ay),hb=half(bx,by);if(ha!=hb)return ha<hb;long turn=cross(ax,ay,bx,by);return turn!=0?turn>0:ai<bi;}
fn long gcd64(long a,long b){if(a<0)a=-a;if(b<0)b=-b;while(b!=0){long r=a%b;a=b;b=r;}return a;}
fn bool proper_crossing(Point p,Point q,Point a,Point b,long* out_num,long* out_den){
    long rx=q.x-p.x,ry=q.y-p.y,sx=b.x-a.x,sy=b.y-a.y;long den=cross(rx,ry,sx,sy);if(den==0)return false;
    long ax=a.x-p.x,ay=a.y-p.y,tn=cross(ax,ay,sx,sy),un=cross(ax,ay,rx,ry);
    if(den<0){den=-den;tn=-tn;un=-un;}if(!(tn>0&&tn<den&&un>0&&un<den))return false;
    long g=gcd64(tn,den);*out_num=tn/g;*out_den=den/g;return true;
}
fn bool segments_cross(Point a,Point b,Point c,Point d){return orient(a,b,c)*orient(a,b,d)<0&&orient(c,d,a)*orient(c,d,b)<0;}
fn int next_ccw(usz node,usz incoming,usz* degree,usz* rotation){
    usz base=node*MAX_N;for(usz i=0;i<degree[node];i+=1)if(rotation[base+i]==incoming)return (int)rotation[base+(i+1)%degree[node]];return -1;
}
fn int first_ccw(usz node,usz target,Point* points,usz* degree,usz* adjacency){
    long rx=points[target].x-points[node].x,ry=points[target].y-points[node].y;int best=-1;long bestx=0,besty=0;
    for(usz i=0;i<degree[node];i+=1){usz v=adjacency[node*MAX_N+i];long dx=points[v].x-points[node].x,dy=points[v].y-points[node].y;long x=rx*dx+ry*dy,y=cross(rx,ry,dx,dy);
        if(best<0||angle_less(x,y,v,bestx,besty,(usz)best)){best=(int)v;bestx=x;besty=y;}}
    return best;
}
fn int edge_id(usz u,usz v,usz m,usz* eu,usz* ev){if(u>v){usz t=u;u=v;v=t;}for(usz i=0;i<m;i+=1)if(eu[i]==u&&ev[i]==v)return (int)i;return -1;}
fn void put64(long value,char* output,usz at){ulong bits=bitcast(value,ulong);for(usz b=0;b<8;b+=1){output[at+b]=(char)(bits&255);bits>>=8;}}

fn long gpsr_perimeter_recovery_trace(long* input,usz length,char* output,usz capacity) @export("gpsr_perimeter_recovery_trace") {
    if(input==null||length<4||length>MAX_INPUT)return -1;long n64=input[0],m64=input[1],s64=input[2],d64=input[3];
    if(n64<3||n64>(long)MAX_N||m64<n64-1||m64>3*n64-6||m64>(long)MAX_M||s64<0||s64>=n64||d64<0||d64>=n64||s64==d64)return -1;
    usz n=(usz)n64,m=(usz)m64,source=(usz)s64,target=(usz)d64;if(length!=4+2*n+2*m)return -1;
    Point[MAX_N] points=zeroed;
    for(usz i=0;i<n;i+=1){points[i].x=input[4+i];points[i].y=input[4+n+i];if(points[i].x< -16||points[i].x>16||points[i].y< -16||points[i].y>16)return -1;
        for(usz j=0;j<i;j+=1)if(points[i].x==points[j].x&&points[i].y==points[j].y)return -1;}
    for(usz i=0;i<n;i+=1)for(usz j=i+1;j<n;j+=1)for(usz k=j+1;k<n;k+=1)if(orient(points[i],points[j],points[k])==0)return -1;
    usz[MAX_M] eu=zeroed,ev=zeroed;usz[MAX_N][MAX_N] adjacency=zeroed,rotation=zeroed;usz[MAX_N] degree=zeroed;usz offset=4+2*n;
    for(usz i=0;i<m;i+=1){long u64=input[offset+2*i],v64=input[offset+2*i+1];if(u64<0||v64>=(long)n||u64>=v64)return -1;usz u=(usz)u64,v=(usz)v64;eu[i]=u;ev[i]=v;
        if(i>0&&(eu[i-1]>u||(eu[i-1]==u&&ev[i-1]>=v)))return -1;adjacency[u][degree[u]]=v;degree[u]+=1;adjacency[v][degree[v]]=u;degree[v]+=1;}
    bool[MAX_N] seen=zeroed;usz[MAX_N] queue=zeroed;usz head=0,tail=0;seen[source]=true;queue[tail]=source;tail+=1;
    while(head<tail){usz u=queue[head];head+=1;for(usz i=0;i<degree[u];i+=1){usz v=adjacency[u][i];if(!seen[v]){seen[v]=true;queue[tail]=v;tail+=1;}}}
    if(tail!=n)return -1;
    for(usz i=0;i<m;i+=1)for(usz j=i+1;j<m;j+=1){usz a=eu[i],b=ev[i],c=eu[j],d=ev[j];if(a!=c&&a!=d&&b!=c&&b!=d&&segments_cross(points[a],points[b],points[c],points[d]))return -1;}
    long dx=points[source].x-points[target].x,dy=points[source].y-points[target].y,start_dist=dx*dx+dy*dy;
    for(usz i=0;i<degree[source];i+=1){usz v=adjacency[source][i];long x=points[v].x-points[target].x,y=points[v].y-points[target].y;if(x*x+y*y<start_dist)return -1;}
    for(usz u=0;u<n;u+=1){for(usz i=0;i<degree[u];i+=1)rotation[u][i]=adjacency[u][i];for(usz i=1;i<degree[u];i+=1){usz v=rotation[u][i],j=i;while(j>0){usz w=rotation[u][j-1];if(!angle_less(points[v].x-points[u].x,points[v].y-points[u].y,v,points[w].x-points[u].x,points[w].y-points[u].y,w))break;rotation[u][j]=w;j-=1;}rotation[u][j]=v;}}
    if(output==null||capacity<MAX_OUTPUT)return -2;
    usz[MAX_PATH] path=zeroed;path[0]=source;usz path_count=1,cross_count=0;long[MAX_M*4] events=zeroed;int current=(int)source,previous=-1,e0u=-1,e0v=-1,status=0;long lf_num=0,lf_den=1;
    for(;;){long x=points[current].x-points[target].x,y=points[current].y-points[target].y;if((usz)current==target){status=2;break;}if(x*x+y*y<start_dist){status=1;break;}if(path_count-1>=2*m){status=0;break;}
        int cand=previous<0?first_ccw((usz)current,target,&points[0],&degree[0],&adjacency[0][0]):next_ccw((usz)current,(usz)previous,&degree[0],&rotation[0][0]);if(cand<0){status=0;break;}bool changed=false;
        for(;;){long t_num=0,t_den=1;if(!proper_crossing(points[source],points[target],points[current],points[cand],&t_num,&t_den)||t_num*lf_den<=lf_num*t_den)break;int id=edge_id((usz)current,(usz)cand,m,&eu[0],&ev[0]);if(id<0||cross_count>=MAX_M){status=0;goto done;}
            events[4*cross_count]=path_count-1;events[4*cross_count+1]=id;events[4*cross_count+2]=t_num;events[4*cross_count+3]=t_den;cross_count+=1;lf_num=t_num;lf_den=t_den;changed=true;cand=next_ccw((usz)current,(usz)cand,&degree[0],&rotation[0][0]);if(cand<0){status=0;goto done;}}
        if(changed||e0u<0){e0u=current;e0v=cand;}else if(e0u==current&&e0v==cand){status=0;break;}previous=current;current=cand;path[path_count]=(usz)current;path_count+=1;
    }
done:
    ;usz word=0;put64(status,output,word*8);word+=1;put64((long)(path_count-1),output,word*8);word+=1;
    for(usz i=0;i<path_count;i+=1){put64((long)path[i],output,word*8);word+=1;}put64((long)cross_count,output,word*8);word+=1;
    for(usz i=0;i<cross_count*4;i+=1){put64(events[i],output,word*8);word+=1;}return (long)(word*8);
}
