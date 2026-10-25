module olden_voronoi;
import "math";
const int MAX_POINTS=5, MAX_EDGES=32;
const double SCALE=1000.0;
struct Point { double x; double y; double norm; }
struct EdgePair { int left; int right; }
Point[MAX_POINTS] points;
int[MAX_POINTS] left_child, right_child;
int[MAX_EDGES*4] onext, origin;
bool[MAX_EDGES] alive;
int edge_count;

fn int sym(int e){return e^2;}
fn int rot(int e){return (e&~3)|((e+1)&3);}
fn int rotinv(int e){return (e&~3)|((e+3)&3);}
fn int lnext(int e){return rot(onext[rotinv(e)]);}
fn int oprev(int e){return rot(onext[rot(e)]);}
fn int rprev(int e){return onext[sym(e)];}
fn int lprev(int e){return sym(onext[e]);}
fn int orig(int e){return origin[e];}
fn int dest(int e){return origin[sym(e)];}
fn bool ccw(int a,int b,int c){return (points[a].x-points[c].x)*(points[b].y-points[c].y)-(points[b].x-points[c].x)*(points[a].y-points[c].y)>0.0;}
fn bool incircle(int a,int b,int c,int d){
 double adx=points[a].x-points[d].x,ady=points[a].y-points[d].y;
 double bdx=points[b].x-points[d].x,bdy=points[b].y-points[d].y;
 double cdx=points[c].x-points[d].x,cdy=points[c].y-points[d].y;
 double r=(points[a].norm-points[d].norm)*(bdx*cdy-bdy*cdx);
 r+=(points[b].norm-points[d].norm)*(cdx*ady-cdy*adx);
 r+=(points[c].norm-points[d].norm)*(adx*bdy-ady*bdx);return r>0.0;
}
fn int make_edge(int a,int b){int e=edge_count*4;edge_count++;alive[e/4]=true;onext[e]=e;origin[e]=a;onext[e+1]=e+3;onext[e+2]=e+2;origin[e+2]=b;onext[e+3]=e+1;return e;}
fn void splice(int a,int b){int alpha=rot(onext[a]),beta=rot(onext[b]);int t1=onext[beta],tmp=onext[alpha];onext[alpha]=t1;onext[beta]=tmp;tmp=onext[a];t1=onext[b];onext[b]=tmp;onext[a]=t1;}
fn int connect_left(int a,int b){int e=make_edge(dest(a),orig(b));splice(e,lnext(a));splice(sym(e),b);return e;}
fn int connect_right(int a,int b){int e=make_edge(dest(a),orig(b));splice(e,sym(a));splice(sym(e),oprev(b));return e;}
fn void delete_edge(int e){int f=oprev(e);splice(e,f);f=oprev(sym(e));splice(sym(e),f);alive[e/4]=false;}
fn void swap_edge(int e){int a=oprev(e),se=sym(e),b=oprev(se);splice(e,a);splice(se,b);splice(e,lnext(a));splice(se,lnext(b));int a1=dest(a),b1=dest(b);origin[e]=a1;origin[sym(e)]=b1;}
fn bool valid(int l,int base){return ccw(orig(base),dest(l),dest(base));}
fn EdgePair do_merge(int ldo,int ldi,int rdi,int rdo){
 int basel,lcand,rcand,t;
 while(true){int t3=orig(rdi),t1=orig(ldi),t2=dest(ldi);while(ccw(t1,t2,t3)){ldi=lnext(ldi);t1=orig(ldi);t2=dest(ldi);}t2=dest(rdi);if(ccw(t2,t3,t1))rdi=rprev(rdi);else break;}
 basel=connect_left(sym(rdi),ldi);lcand=rprev(basel);rcand=oprev(basel);int t1=orig(basel),t2=dest(basel);if(t1==orig(rdo))rdo=basel;if(t2==orig(ldo))ldo=sym(basel);
 while(true){int v1,v2,v3,v4;t=onext[lcand];if(valid(t,basel)){v4=orig(basel);v1=dest(lcand);v3=orig(lcand);v2=dest(t);while(incircle(v1,v2,v3,v4)){delete_edge(lcand);lcand=t;t=onext[lcand];v1=dest(lcand);v3=orig(lcand);v2=dest(t);}}
 t=oprev(rcand);if(valid(t,basel)){v4=dest(basel);v1=dest(t);v2=dest(rcand);v3=orig(rcand);while(incircle(v1,v2,v3,v4)){delete_edge(rcand);rcand=t;t=oprev(rcand);v2=dest(rcand);v3=orig(rcand);v1=dest(t);}}
 bool lv=valid(lcand,basel),rv=valid(rcand,basel);if(!lv&&!rv)return EdgePair{ldo,rdo};v1=dest(lcand);v2=orig(lcand);v3=orig(rcand);v4=dest(rcand);if(!lv||(rv&&incircle(v1,v2,v3,v4))){basel=connect_left(rcand,sym(basel));rcand=lnext(sym(basel));}else{basel=sym(connect_right(lcand,basel));lcand=rprev(basel);}}
}
fn int get_low(int node){while(left_child[node]>=0)node=left_child[node];return node;}
fn EdgePair build_delaunay(int tree,int extra){
 if(tree>=0&&right_child[tree]>=0){int minx=get_low(tree),maxx=extra;EdgePair dr=build_delaunay(right_child[tree],extra),dl=build_delaunay(left_child[tree],tree);EdgePair r=do_merge(dl.left,dl.right,dr.left,dr.right);while(orig(r.left)!=minx)r.left=rprev(r.left);while(orig(r.right)!=maxx)r.right=lprev(r.right);return r;}
 if(tree<0)return EdgePair{-1,-1};if(left_child[tree]<0){int e=make_edge(tree,extra);return EdgePair{e,sym(e)};}int s1=left_child[tree],s2=tree,s3=extra;int a=make_edge(s1,s2),b=make_edge(s2,s3);splice(sym(a),b);int c=connect_left(b,a);if(ccw(s1,s3,s2))return EdgePair{sym(c),c};EdgePair r=EdgePair{a,sym(b)};if(!ccw(s1,s2,s3))delete_edge(c);return r;
}
fn double center_x(int a,int b,int c){double vx=points[b].x-points[a].x,vy=points[b].y-points[a].y,wx=points[c].x-points[a].x,wy=points[c].y-points[a].y;double d3=vx*wy-vy*wx,d2=-2.0*d3,d4=(points[c].x-points[b].x)*wx+(points[c].y-points[b].y)*wy;return 0.5*(points[a].x+points[b].x)+(d4/d2)*vy;}
fn double center_y(int a,int b,int c){double vx=points[b].x-points[a].x,vy=points[b].y-points[a].y,wx=points[c].x-points[a].x,wy=points[c].y-points[a].y;double d3=vx*wy-vy*wx,d2=-2.0*d3,d4=(points[c].x-points[b].x)*wx+(points[c].y-points[b].y)*wy;return 0.5*(points[a].y+points[b].y)-(d4/d2)*vx;}
fn bool face_center(int e, double* x, double* y){int e2=lnext(e),e3=lnext(e2);if(lnext(e3)!=e)return false;int a=orig(e),b=dest(e),c=dest(e2);if(a==b||b==c||a==c||!ccw(a,b,c))return false;x[0]=center_x(a,b,c);y[0]=center_y(a,b,c);return true;}
fn long quantize(double x){return (long)math.floor(x*SCALE+0.5);}

fn long olden_voronoi(long* input,usz length) @export("olden_voronoi") {
 if(input==null||(length!=7&&length!=11))return -1;long nv=input[0];if(nv!=3&&nv!=5)return -1;int n=(int)nv;if(length!=(usz)(1+2*n))return -1;
 for(int i=0;i<MAX_POINTS;i++){left_child[i]=-1;right_child[i]=-1;alive[i]=false;}
 for(int i=0;i<n;i++){long x=input[1+2*i],y=input[2+2*i];if(x< -8||x>8||y< -8||y>8)return -1;points[i]=Point{(double)x,(double)y,(double)(x*x+y*y)};if(i>0&&points[i-1].x>=points[i].x)return -1;}
 if(n==3)left_child[1]=0;else{left_child[2]=1;right_child[2]=3;left_child[1]=0;}
 for(int a=0;a<n;a++)for(int b=a+1;b<n;b++)for(int c=b+1;c<n;c++)if(!ccw(a,b,c)&&!ccw(a,c,b))return -1;
 if(n==5)for(int a=0;a<n;a++)for(int b=a+1;b<n;b++)for(int c=b+1;c<n;c++)for(int d=c+1;d<n;d++)if(!incircle(a,b,c,d)&&!incircle(a,c,b,d))return -1;
 edge_count=0;(void)build_delaunay(n==3?1:2,n-1);int seen[16][3],faces=0,edges=0,dual=0,rays=0;long projection=0;
 for(int edge=0;edge<edge_count;edge++)if(alive[edge]){int e=4*edge;double x,y;bool left=face_center(e,&x,&y);if(left){int a=orig(e),b=dest(e),c=dest(lnext(e));bool duplicate=false;for(int f=0;f<faces;f++)if((seen[f][0]==a||seen[f][1]==a||seen[f][2]==a)&&(seen[f][0]==b||seen[f][1]==b||seen[f][2]==b)&&(seen[f][0]==c||seen[f][1]==c||seen[f][2]==c))duplicate=true;if(!duplicate){seen[faces][0]=a;seen[faces][1]=b;seen[faces][2]=c;faces++;projection+=quantize(x)+2*quantize(y);}}
 double rx,ry;bool right=face_center(sym(e),&rx,&ry);if(left||right){edges++;if(left&&right)dual++;else rays++;}}
 return projection+100*faces+10*dual+rays+edges;
}
