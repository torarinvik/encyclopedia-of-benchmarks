module point_location_sweep;
const usz MAX_N=16; const usz MAX_M=24; const usz MAX_Q=16; const usz MAX_EVENTS=64; const usz MAX_LENGTH=141;
struct Point { long x; long y; }
struct Edge { usz u; usz v; long face; }
struct Event { long x; long kind; usz id; }
struct Work { Point[MAX_N] points; Edge[MAX_M] edges; long[MAX_Q] qx; long[MAX_Q] qy; Event[MAX_EVENTS] events; usz[MAX_M] active; long[MAX_Q] response; }
fn long orient(Point a,Point b,Point c){return (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x);}
fn bool between(long x,long a,long b){return x>=(a<b?a:b)&&x<=(a>b?a:b);}
fn bool on_segment(Point a,Point b,Point p){return orient(a,b,p)==0&&between(p.x,a.x,b.x)&&between(p.y,a.y,b.y);}
fn bool intersects(Point a,Point b,Point c,Point d){long o1=orient(a,b,c),o2=orient(a,b,d),o3=orient(c,d,a),o4=orient(c,d,b);if(o1==0&&on_segment(a,b,c))return true;if(o2==0&&on_segment(a,b,d))return true;if(o3==0&&on_segment(c,d,a))return true;if(o4==0&&on_segment(c,d,b))return true;return ((o1<0&&o2>0)||(o1>0&&o2<0))&&((o3<0&&o4>0)||(o3>0&&o4<0));}
fn void endpoints(Work* w,usz e,Point* l,Point* r){Point a=w.points[w.edges[e].u],b=w.points[w.edges[e].v];if(a.x<b.x){*l=a;*r=b;}else{*l=b;*r=a;}}
fn void height(Work* w,usz e,long x,long* num,long* den){Point l,r;endpoints(w,e,&l,&r);*den=r.x-l.x;*num=l.y*(*den)+(r.y-l.y)*(x-l.x);}
fn bool edge_less(Work* w,usz a,usz b,long x){long na,da,nb,db;height(w,a,x,&na,&da);height(w,b,x,&nb,&db);if(na*db!=nb*da)return na*db<nb*da;Point la,ra,lb,rb;endpoints(w,a,&la,&ra);endpoints(w,b,&lb,&rb);long sa=(ra.y-la.y)*(rb.x-lb.x),sb=(rb.y-lb.y)*(ra.x-la.x);if(sa!=sb)return sa<sb;return a<b;}
fn bool event_less(Event a,Event b){if(a.x!=b.x)return a.x<b.x;if(a.kind!=b.kind)return a.kind<b.kind;return a.id<b.id;}
fn long point_location_sweep(long* input,usz length) @export("point_location_sweep") {
 if(input==null||length<4||length>MAX_LENGTH)return -1;long n=input[0],m=input[1],q=input[2],f=input[3];if(n<2||n>16||m<1||m>24||q<0||q>16||f<1||f>16||length!=4+2*(usz)n+3*(usz)m+2*(usz)q)return -1;
 Work w={};usz pos=4;
 for(usz i=0;i<(usz)n;i++){w.points[i].x=input[pos];w.points[i].y=input[pos+1];pos+=2;if(w.points[i].x< -300||w.points[i].x>300||w.points[i].y< -300||w.points[i].y>300)return -1;for(usz j=0;j<i;j++)if(w.points[i].x==w.points[j].x)return -1;}
 for(usz i=0;i<(usz)m;i++){long u=input[pos],v=input[pos+1],face=input[pos+2];pos+=3;if(u<0||u>=n||v<0||v>=n||u==v||face< -1||face>=f)return -1;w.edges[i]=(Edge){(usz)u,(usz)v,face};for(usz j=0;j<i;j++)if((w.edges[i].u==w.edges[j].u&&w.edges[i].v==w.edges[j].v)||(w.edges[i].u==w.edges[j].v&&w.edges[i].v==w.edges[j].u))return -1;}
 for(usz i=0;i<(usz)m;i++)for(usz j=0;j<i;j++){Edge e=w.edges[i],g=w.edges[j];long shared=-1;if(e.u==g.u||e.u==g.v)shared=(long)e.u;else if(e.v==g.u||e.v==g.v)shared=(long)e.v;if(shared>=0){usz oi=e.u==(usz)shared?e.v:e.u,oj=g.u==(usz)shared?g.v:g.u;if(orient(w.points[(usz)shared],w.points[oi],w.points[oj])==0)return -1;}else if(intersects(w.points[e.u],w.points[e.v],w.points[g.u],w.points[g.v]))return -1;}
 for(usz i=0;i<(usz)q;i++){w.qx[i]=input[pos];w.qy[i]=input[pos+1];pos+=2;if(w.qx[i]< -300||w.qx[i]>300||w.qy[i]< -300||w.qy[i]>300)return -1;for(usz j=0;j<(usz)n;j++)if(w.qx[i]==w.points[j].x)return -1;}
 usz ec=0;for(usz i=0;i<(usz)m;i++){Point l,r;endpoints(&w,i,&l,&r);w.events[ec++]=(Event){l.x,1,i};w.events[ec++]=(Event){r.x,0,i};}for(usz i=0;i<(usz)q;i++)w.events[ec++]=(Event){w.qx[i],2,i};
 for(usz i=1;i<ec;i++){Event key=w.events[i];usz j=i;while(j>0&&event_less(key,w.events[j-1])){w.events[j]=w.events[j-1];--j;}w.events[j]=key;}
 usz ac=0;for(usz z=0;z<ec;z++){Event e=w.events[z];if(e.kind==0){usz k=0;while(k<ac&&w.active[k]!=e.id)k++;if(k==ac)return -1;for(;k+1<ac;k++)w.active[k]=w.active[k+1];--ac;}else if(e.kind==1){usz k=0;while(k<ac&&edge_less(&w,w.active[k],e.id,e.x))k++;for(usz h=ac;h>k;h--)w.active[h]=w.active[h-1];w.active[k]=e.id;++ac;}else{usz lo=0,hi=ac;while(lo<hi){usz mid=(lo+hi)/2;long num,den;height(&w,w.active[mid],e.x,&num,&den);if(num<w.qy[e.id]*den)lo=mid+1;else hi=mid;}if(lo<ac){long num,den;height(&w,w.active[lo],e.x,&num,&den);if(num==w.qy[e.id]*den)w.response[e.id]=f+(long)w.active[lo]+1;else if(lo>0&&w.edges[w.active[lo-1]].face>=0)w.response[e.id]=w.edges[w.active[lo-1]].face+1;}else if(lo>0&&w.edges[w.active[lo-1]].face>=0)w.response[e.id]=w.edges[w.active[lo-1]].face+1;}}
 long result=0;for(usz i=0;i<(usz)q;i++)result+=(long)(i+1)*w.response[i];return result;
}
