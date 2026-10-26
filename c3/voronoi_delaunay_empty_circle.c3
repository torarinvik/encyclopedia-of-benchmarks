// Clean-room exact Delaunay graph construction by empty circumcircles.
module voronoi_delaunay_empty_circle;
const usz N=8;const usz F=37;
struct Point{long x;long y;}
fn long orient(Point a,Point b,Point c){return (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x);}
fn long circle(Point a,Point b,Point c,Point d){long ax=a.x-d.x,ay=a.y-d.y,bx=b.x-d.x,by=b.y-d.y,cx=c.x-d.x,cy=c.y-d.y;long aa=ax*ax+ay*ay,bb=bx*bx+by*by,cc=cx*cx+cy*cy;return aa*(bx*cy-by*cx)-bb*(ax*cy-ay*cx)+cc*(ax*by-ay*bx);}
fn void put(char*out,usz at,long x){ulong bits=(ulong)x;for(usz i=0;i<8;++i){out[at+i]=(char)(bits&255ul);bits>>=8;}}
fn long voronoi_delaunay_empty_circle(long*v,usz n,char*out,usz cap) @export("voronoi_delaunay_empty_circle"){
 if(v==null||n<7||n>17||v[0]<3||v[0]>8)return -1;usz count=(usz)v[0];if(n!=1+2*count)return -1;Point[N] pts={};for(usz i=0;i<count;++i){long x=v[1+2*i],y=v[2+2*i];if(x < -50||x>50||y < -50||y>50)return -1;for(usz j=0;j<i;++j)if(pts[j].x==x&&pts[j].y==y)return -1;pts[i]=Point{x,y};}
 for(usz a=0;a<count;++a)for(usz b=a+1;b<count;++b)for(usz c=b+1;c<count;++c)if(orient(pts[a],pts[b],pts[c])==0)return -1;for(usz a=0;a<count;++a)for(usz b=a+1;b<count;++b)for(usz c=b+1;c<count;++c)for(usz d=c+1;d<count;++d)if(circle(pts[a],pts[b],pts[c],pts[d])==0)return -1;
 bool[N][N] edges={};for(usz a=0;a<count;++a)for(usz b=a+1;b<count;++b)for(usz c=b+1;c<count;++c){long o=orient(pts[a],pts[b],pts[c]);bool empty=true;for(usz d=0;d<count;++d)if(d!=a&&d!=b&&d!=c){long z=circle(pts[a],pts[b],pts[c],pts[d]);if((o>0&&z>0)||(o<0&&z<0)){empty=false;break;}}if(empty){edges[a][b]=edges[b][a]=edges[a][c]=edges[c][a]=edges[b][c]=edges[c][b]=true;}}
 long[F] fields={};usz at=1,m=0;for(usz a=0;a<count;++a)for(usz b=a+1;b<count;++b)if(edges[a][b]){fields[at++]=(long)a;fields[at++]=(long)b;++m;}fields[0]=(long)m;usz bytes=8*at;if(out==null||cap<bytes)return -2;for(usz i=0;i<at;++i)put(out,8*i,fields[i]);return (long)bytes;
}
