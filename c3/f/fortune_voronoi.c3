import std::math;
const usz MAX_SITES=8; const usz MAX_ARCS=15; const usz MAX_VERTICES=32; const usz MAX_OUT=1024;
const double EPS=1e-10;
struct Pt { double x; double y; }
struct Arc { int site; int prev; int next; bool active; }
struct Circle { double y; double x; int arc; int left; int right; }
struct Rat { long n; long d; }
struct RPt { Rat x; Rat y; }
fn long abs_i(long x){return x<0 ? -x : x;}
fn long gcd_i(long a,long b){a=abs_i(a);b=abs_i(b);while(b!=0){long t=a%b;a=b;b=t;}return a==0?1:a;}
fn Rat rat(long n,long d){if(d<0){n= -n;d= -d;}long g=gcd_i(n,d);return Rat{n/g,d/g};}
fn Rat radd(Rat a,Rat b){return rat(a.n*b.d+b.n*a.d,a.d*b.d);}
fn Rat rsub(Rat a,Rat b){return rat(a.n*b.d-b.n*a.d,a.d*b.d);}
fn Rat rmul(Rat a,Rat b){return rat(a.n*b.n,a.d*b.d);}
fn Rat rdiv(Rat a,Rat b){return rat(a.n*b.d,a.d*b.n);}
fn int rcmp(Rat a,Rat b){long l=a.n*b.d,r=b.n*a.d;return l>r?1:l<r?-1:0;}
fn bool peq(RPt a,RPt b){return rcmp(a.x,b.x)==0&&rcmp(a.y,b.y)==0;}
fn bool pless(RPt a,RPt b){int x=rcmp(a.x,b.x);return x<0||(x==0&&rcmp(a.y,b.y)<0);}
fn int orient(Pt a,Pt b,Pt c){double v=(b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x);return v>0?1:v<0?-1:0;}
fn double breakpoint(Pt p,Pt q,double l){if(math.fabs(p.y-q.y)<EPS)return (p.x+q.x)*0.5;double dp=p.y-l,dq=q.y-l;double a=q.y-p.y;double b= -2.0*p.x*dq+2.0*q.x*dp;double c=(p.x*p.x+p.y*p.y-l*l)*dq-(q.x*q.x+q.y*q.y-l*l)*dp;double disc=b*b-4.0*a*c;if(disc<0.0&&disc> -EPS)disc=0.0;double root=math.sqrt(disc);double r1=(-b-root)/(2.0*a),r2=(-b+root)/(2.0*a);return p.y<q.y?(r1>r2?r1:r2):(r1<r2?r1:r2);}
fn bool circle(Pt a,Pt b,Pt c,double sweep,mutable Circle& out,int arc,int left,int right){if(orient(a,b,c)>=0)return false;double aa=a.x*a.x+a.y*a.y,bb=b.x*b.x+b.y*b.y,cc=c.x*c.x+c.y*c.y;double d=2.0*(a.x*(b.y-c.y)+b.x*(c.y-a.y)+c.x*(a.y-b.y));if(math.fabs(d)<EPS)return false;double x=(aa*(b.y-c.y)+bb*(c.y-a.y)+cc*(a.y-b.y))/d;double y=(aa*(c.x-b.x)+bb*(a.x-c.x)+cc*(b.x-a.x))/d;double dx=x-a.x,dy=y-a.y,bottom=y-math.sqrt(dx*dx+dy*dy);if(!(bottom<sweep-EPS))return false;out=Circle{bottom,x,arc,left,right};return true;}
fn Rat dist(RPt p,long a,long b,long c){return rsub(radd(rmul(rat(a,1),p.x),rmul(rat(b,1),p.y)),rat(c,1));}
fn RPt intersection(RPt p,RPt q,Rat dp,Rat dq){Rat t=rdiv(dp,rsub(dp,dq));return RPt{radd(p.x,rmul(t,rsub(q.x,p.x))),radd(p.y,rmul(t,rsub(q.y,p.y)))};}
fn void push(mutable RPt[32]& p,mutable usz& n,RPt q){if(n==0||!peq(p[n-1],q)){p[n]=q;n++;}}
fn usz clip(mutable RPt[32]& poly,usz count,long a,long b,long c){RPt[32] next;usz n=0;for(usz i=0;i<count;i++){RPt p=poly[i],q=poly[(i+1)%count];Rat dp=dist(p,a,b,c),dq=dist(q,a,b,c);bool pin=dp.n<=0,qin=dq.n<=0;if(pin&&qin)push(next,n,q);else if(pin&&!qin)push(next,n,intersection(p,q,dp,dq));else if(!pin&&qin){push(next,n,intersection(p,q,dp,dq));push(next,n,q);}}if(n>1&&peq(next[0],next[n-1]))n--;for(usz i=0;i<n;i++)poly[i]=next[i];return n;}
fn bool valid_general(long* v,usz n){for(usz i=0;i<n;i++)for(usz j=i+1;j<n;j++){if(v[1+2*i]==v[1+2*j]&&v[2+2*i]==v[2+2*j])return false;if(v[2+2*i]==v[2+2*j])return false;}for(usz i=0;i<n;i++)for(usz j=i+1;j<n;j++)for(usz k=j+1;k<n;k++){long ax=v[1+2*i],ay=v[2+2*i],bx=v[1+2*j],by=v[2+2*j],cx=v[1+2*k],cy=v[2+2*k];if((bx-ax)*(cy-ay)==(by-ay)*(cx-ax))return false;}for(usz i=0;i<n;i++)for(usz j=i+1;j<n;j++)for(usz k=j+1;k<n;k++)for(usz l=k+1;l<n;l++){long ax=v[1+2*i]-v[1+2*l],ay=v[2+2*i]-v[2+2*l],bx=v[1+2*j]-v[1+2*l],by=v[2+2*j]-v[2+2*l],cx=v[1+2*k]-v[1+2*l],cy=v[2+2*k]-v[2+2*l];long aa=ax*ax+ay*ay,bb=bx*bx+by*by,cc=cx*cx+cy*cy;long d=ax*(by*cc-bb*cy)-ay*(bx*cc-bb*cx)+aa*(bx*cy-by*cx);if(d==0)return false;}return true;}
fn void put(uint8* out,usz slot,long v){ulong bits=(ulong)v;for(usz i=0;i<8;i++){out[slot*8+i]=(uint8)(bits&255);bits>>=8;}}
fn long fortune_voronoi(long* input,usz length,uint8* output,usz capacity) @export("fortune_voronoi") {
 if(input==null||length<3||input[0]<1||input[0]>(long)MAX_SITES||length!=1+2*(usz)input[0])return -1;usz n=(usz)input[0];for(usz i=0;i<n;i++)if(input[1+2*i]< -8||input[1+2*i]>8||input[2+2*i]< -8||input[2+2*i]>8)return -1;if(!valid_general(input,n))return -1;
 Pt[MAX_SITES] sites;int[MAX_SITES] order;for(usz i=0;i<n;i++){sites[i]=Pt{(double)input[1+2*i],(double)input[2+2*i]};order[i]=(int)i;}for(usz i=1;i<n;i++){int v=order[i];usz j=i;while(j>0&&sites[order[j-1]].y<sites[v].y){order[j]=order[j-1];j--;}order[j]=v;}
 Arc[MAX_ARCS] arcs;usz arc_count=1;int first=0;arcs[0]=Arc{order[0],-1,-1,true};usz next_site=1;double sweep=sites[order[0]].y;bool[MAX_SITES][MAX_SITES] adjacent;
 while(next_site<n||first>=0){Circle best;bool has=false;for(int b=first;b>=0;b=arcs[b].next){int l=arcs[b].prev,r=arcs[b].next;if(l<0||r<0)continue;int si=arcs[l].site,sj=arcs[b].site,sk=arcs[r].site;if(si==sj||sj==sk||si==sk)continue;Circle cand;if(circle(sites[si],sites[sj],sites[sk],sweep,cand,b,l,r)&&(!has||cand.y>best.y+EPS||(math.fabs(cand.y-best.y)<=EPS&&b<best.arc))){best=cand;has=true;}}
  bool do_site=next_site<n&&(!has||sites[order[next_site]].y>best.y+EPS);if(!do_site&&!has)break;if(do_site){int site=order[next_site];next_site++;sweep=sites[site].y;int arc=first;while(arcs[arc].next>=0){int right=arcs[arc].next;if(sites[site].x<breakpoint(sites[arcs[arc].site],sites[arcs[right].site],sweep))break;arc=right;}int old_next=arcs[arc].next,old_site=arcs[arc].site;if(arc_count+2>MAX_ARCS)return -1;int middle=(int)arc_count++;arcs[middle]=Arc{site,arc,-1,true};int right=(int)arc_count++;arcs[right]=Arc{old_site,middle,old_next,true};arcs[arc].next=middle;arcs[middle].next=right;if(old_next>=0)arcs[old_next].prev=right;adjacent[old_site][site]=true;adjacent[site][old_site]=true;}else{int arc=best.arc,left=best.left,right=best.right;if(!arcs[arc].active||arcs[arc].prev!=left||arcs[arc].next!=right)return -1;sweep=best.y;int ls=arcs[left].site,rs=arcs[right].site;adjacent[ls][rs]=true;adjacent[rs][ls]=true;arcs[left].next=right;arcs[right].prev=left;arcs[arc].active=false;}}
 long[1024] values;usz used=0;values[used]=n;used++;for(usz i=0;i<n;i++){RPt[32] poly;poly[0]=RPt{Rat{-16,1},Rat{-16,1}};poly[1]=RPt{Rat{16,1},Rat{-16,1}};poly[2]=RPt{Rat{16,1},Rat{16,1}};poly[3]=RPt{Rat{-16,1},Rat{16,1}};usz count=4;for(usz j=0;j<n;j++)if(adjacent[i][j]){long x=input[1+2*j],y=input[2+2*j],sx=input[1+2*i],sy=input[2+2*i];count=clip(poly,count,2*(x-sx),2*(y-sy),x*x+y*y-sx*sx-sy*sy);}if(count<3||used+2+4*count>1024)return -1;usz start=0;for(usz j=1;j<count;j++)if(pless(poly[j],poly[start]))start=j;values[used]=i;used++;values[used]=count;used++;for(usz j=0;j<count;j++){RPt p=poly[(start+j)%count];values[used]=p.x.n;used++;values[used]=p.x.d;used++;values[used]=p.y.n;used++;values[used]=p.y.d;used++;}}
 usz bytes=used*8;if(output==null||capacity<bytes)return -2;for(usz i=0;i<used;i++)put(output,i,values[i]);return (long)bytes;
}
