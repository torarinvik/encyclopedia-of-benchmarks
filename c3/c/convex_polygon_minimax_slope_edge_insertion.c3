module convex_polygon_minimax_slope_edge_insertion;
const int MAX_N=4; const usz MAX_LEN=14;
struct Point { long x; long y; long z; }
struct Tri { int a; int b; int c; }
struct Rat { long num; long den; }
fn long orient(Point[MAX_N] p,int a,int b,int c){return (p[b].x-p[a].x)*(p[c].y-p[a].y)-(p[b].y-p[a].y)*(p[c].x-p[a].x);}
fn Rat slope(Point[MAX_N] p,Tri t){
 Point a=p[t.a]; Point b=p[t.b]; Point c=p[t.c];
 long dx1=b.x-a.x; long dy1=b.y-a.y; long dz1=b.z-a.z; long dx2=c.x-a.x; long dy2=c.y-a.y; long dz2=c.z-a.z;
 long det=dx1*dy2-dx2*dy1; long gx=dz1*dy2-dz2*dy1; long gy=dx1*dz2-dz1*dx2;
 return Rat{gx*gx+gy*gy,det*det};
}
fn int cmp(Rat a,Rat b){long x=a.num*b.den;long y=b.num*a.den;return if x>y:1 else:if x<y:-1 else:0;}
fn bool anchor(Point[MAX_N] p,Tri t,int q){
 Point a=p[t.a];Point b=p[t.b];Point c=p[t.c];long dx1=b.x-a.x;long dy1=b.y-a.y;long dz1=b.z-a.z;long dx2=c.x-a.x;long dy2=c.y-a.y;long dz2=c.z-a.z;
 long det=dx1*dy2-dx2*dy1;long gx=dz1*dy2-dz2*dy1;long gy=dx1*dz2-dz1*dx2;if gx==0&&gy==0{return false;}
 int[3] vertices={t.a,t.b,t.c};int[2] o=zeroed;int used=0;for(int i=0;i<3;i++){int v=vertices[i];if(v!=q){o[used]=v;used++;}}
 long sign=if det>0:1 else:-1;long dx=-gx*sign;long dy=-gy*sign;
 long ux=p[o[0]].x-p[q].x;long uy=p[o[0]].y-p[q].y;long vx=p[o[1]].x-p[q].x;long vy=p[o[1]].y-p[q].y;
 long turn=ux*vy-uy*vx;long side=if turn>0:1 else:-1;
 return side*(ux*dy-uy*dx)>=0&&side*(dx*vy-dy*vx)>=0;
}
fn bool cross(Point[MAX_N] p,int a,int b,int c,int d){return orient(p,a,b,c)*orient(p,a,b,d)<0&&orient(p,c,d,a)*orient(p,c,d,b)<0;}
fn long volume6(Point[MAX_N] p){long ax=p[1].x-p[0].x;long ay=p[1].y-p[0].y;long az=p[1].z-p[0].z;long bx=p[2].x-p[0].x;long by=p[2].y-p[0].y;long bz=p[2].z-p[0].z;long cx=p[3].x-p[0].x;long cy=p[3].y-p[0].y;long cz=p[3].z-p[0].z;return ax*(by*cz-bz*cy)-ay*(bx*cz-bz*cx)+az*(bx*cy-by*cx);}
fn Rat max2(Point[MAX_N] p,Tri a,Tri b){Rat x=slope(p,a);Rat y=slope(p,b);return if cmp(x,y)>=0:x else:y;}
fn long rank(Point[MAX_N] p,int n,Rat target){Rat[4] all=zeroed;int count=0;for(int a=0;a<n;a++)for(int b=a+1;b<n;b++)for(int c=b+1;c<n;c++){all[count]=slope(p,Tri{a,b,c});count++;}int distinct=0;for(int i=0;i<count;i++)if(cmp(all[i],target)<0){bool seen=false;for(int j=0;j<i;j++)if(cmp(all[j],all[i])==0)seen=true;if(!seen)distinct++;}return distinct+1;}
fn long convex_polygon_minimax_slope_edge_insertion(long* input,usz length){
 if(input==null||length<1||length>MAX_LEN)return -1;long n0=input[0];if(n0<3||n0>4)return -1;int n=(int)n0;if(length!=(usz)(1+3*n))return -1;
 Point[MAX_N] p=zeroed;for(int i=0;i<n;i++){p[i]=Point{input[1+3*i],input[2+3*i],input[3+3*i]};if(p[i].x < -8||p[i].x>8||p[i].y < -8||p[i].y>8||p[i].z < -8||p[i].z>8)return -1;}
 long area=0;for(int i=0;i<n;i++){int j=(i+1)%n;area+=p[i].x*p[j].y-p[i].y*p[j].x;}if(area==0)return -1;int sign=if area>0:1 else:-1;
 for(int a=0;a<n;a++)for(int b=a+1;b<n;b++)for(int c=b+1;c<n;c++)if(orient(p,a,b,c)==0)return -1;
 for(int e=0;e<n;e++){int j=(e+1)%n;for(int k=0;k<n;k++)if(k!=e&&k!=j&&sign*orient(p,e,j,k)<=0)return -1;}
 if(n==4&&volume6(p)==0)return -1;
 Tri[2] fan={Tri{0,1,2},Tri{0,2,3}};Rat worst=if n==3:slope(p,fan[0]) else:max2(p,fan[0],fan[1]);
 if(n==4){bool accepted=false;for(int ti=0;ti<2&&!accepted;ti++){Tri t=fan[ti];if(cmp(slope(p,t),worst)!=0)continue;int[3] v={t.a,t.b,t.c};for(int k=0;k<3&&!accepted;k++){int q=v[k];if(!anchor(p,t,q))continue;int[2] o=zeroed;int u=0;int s=-1;for(int j=0;j<3;j++)if(j!=k){o[u]=v[j];u++;}for(int j=0;j<4;j++)if(j!=v[0]&&j!=v[1]&&j!=v[2])s=j;if(!cross(p,q,s,o[0],o[1]))continue;Rat cand=max2(p,Tri{q,s,o[0]},Tri{q,s,o[1]});if(cmp(cand,worst)<0){worst=cand;accepted=true;}}}}
 return rank(p,n,worst);
}
