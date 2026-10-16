module bentley_ottmann;
const usz N=24; const usz E=2*N+N*(N-1)/2; const usz P=N*(N-1)/2;
struct Seg { long x1; long y1; long x2; long y2; }
struct Ev { long x; long y; int a; int b; int t; bool done; }
fn long cross(long ax,long ay,long bx,long by){return ax*by-ay*bx;}
fn bool intersection(Seg a,Seg b,long* x,long* y){long rx=a.x2-a.x1,ry=a.y2-a.y1,sx=b.x2-b.x1,sy=b.y2-b.y1;long d=cross(rx,ry,sx,sy);if(d==0)return false;long qx=b.x1-a.x1,qy=b.y1-a.y1,t=cross(qx,qy,sx,sy),u=cross(qx,qy,rx,ry);if(d<0){d= -d;t= -t;u= -u;}if(t<=0||t>=d||u<=0||u>=d)return false;long xn=a.x1*d+t*rx,yn=a.y1*d+t*ry;if(xn%d!=0||yn%d!=0)return false;*x=xn/d;*y=yn/d;return true;}
fn bool less(Seg[N] s,int a,int b,long x){long da=s[a].x2-s[a].x1,db=s[b].x2-s[b].x1;long na=s[a].y1*da+(x-s[a].x1)*(s[a].y2-s[a].y1),nb=s[b].y1*db+(x-s[b].x1)*(s[b].y2-s[b].y1);long c=na*db-nb*da;if(c!=0)return c<0;long sl=(s[a].y2-s[a].y1)*db-(s[b].y2-s[b].y1)*da;if(sl!=0)return sl<0;return a<b;}
fn void put(char* out,usz slot,long v){ulong bits=(ulong)v;for(usz i=0;i<8;i++)out[slot*8+i]=(char)(bits>>(i*8));}
fn long bentley_ottmann(long* input,usz length,char* output,usz capacity) @export("bentley_ottmann") {
 if(input==null||length<1||input[0]<0||input[0]>(long)N)return -1;usz n=(usz)input[0];if(length!=1+4*n)return -1;Seg[N] s;
 for(usz i=0;i<n;i++){long x1=input[1+4*i],y1=input[2+4*i],x2=input[3+4*i],y2=input[4+4*i];if(x1< -1000||x1>1000||x2< -1000||x2>1000||y1< -1000||y1>1000||y2< -1000||y2>1000||x1==x2)return -1;if(x1<x2)s[i]=Seg{x1,y1,x2,y2};else s[i]=Seg{x2,y2,x1,y1};}
 Ev[E] ev;usz ec=0;for(usz i=0;i<n;i++){ev[ec]=Ev{s[i].x1,s[i].y1,(int)i,-1,0,false};ec++;ev[ec]=Ev{s[i].x2,s[i].y2,(int)i,-1,1,false};ec++;}bool[N][N] sched;int[N] active;usz ac=0;long[P][2] pts;usz pc=0;
 while(true){usz ei=ec;for(usz j=0;j<ec;j++)if(!ev[j].done&&(ei==ec||ev[j].x<ev[ei].x||(ev[j].x==ev[ei].x&&ev[j].y<ev[ei].y)))ei=j;if(ei==ec)break;Ev e=ev[ei];ev[ei].done=true;if(e.t==0){active[ac]=e.a;ac++;}else if(e.t==1){for(usz j=0;j<ac;j++)if(active[j]==e.a){for(usz k=j+1;k<ac;k++)active[k-1]=active[k];ac--;break;}}else{pts[pc][0]=e.x;pts[pc][1]=e.y;pc++;}
 for(usz i=1;i<ac;i++){int v=active[i];usz j=i;while(j>0&&less(s, v,active[j-1],e.x)){active[j]=active[j-1];j--;}active[j]=v;}
 for(usz i=1;i<ac;i++){int a=active[i-1],b=active[i];if(sched[a][b])continue;long x,y;if(intersection(s[a],s[b],&x,&y)&&x>e.x){if(ec>=E)return -1;ev[ec]=Ev{x,y,a,b,2,false};ec++;sched[a][b]=true;sched[b][a]=true;}}
 }
 for(usz i=1;i<pc;i++){long x=pts[i][0],y=pts[i][1];usz j=i;while(j>0&&(pts[j-1][0]>x||(pts[j-1][0]==x&&pts[j-1][1]>y))){pts[j][0]=pts[j-1][0];pts[j][1]=pts[j-1][1];j--;}pts[j][0]=x;pts[j][1]=y;}usz bytes=(1+2*pc)*8;if(output==null||capacity<bytes)return -2;put(output,0,(long)pc);for(usz i=0;i<pc;i++){put(output,1+2*i,pts[i][0]);put(output,2+2*i,pts[i][1]);}return (long)bytes;
}
