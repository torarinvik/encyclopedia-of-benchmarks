// Clean-room exact Delaunay graph construction by empty circumcircles.
module voronoi_delaunay_empty_circle
const max_n=8;const max_fields=37
struct Point{x i64;y i64}
fn orient(a Point,b Point,c Point)i64{return (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x)}
fn circle(a Point,b Point,c Point,d Point)i64{ax,ay:=a.x-d.x,a.y-d.y;bx,by:=b.x-d.x,b.y-d.y;cx,cy:=c.x-d.x,c.y-d.y;aa:=ax*ax+ay*ay;bb:=bx*bx+by*by;cc:=cx*cx+cy*cy;return aa*(bx*cy-by*cx)-bb*(ax*cy-ay*cx)+cc*(ax*by-ay*bx)}
fn put(mut out &u8,at int,x i64){mut bits:=u64(x);for i in 0..8{unsafe{out[at+i]=u8(bits&255)};bits>>=8}}
@[export:'voronoi_delaunay_empty_circle']
pub fn voronoi_delaunay_empty_circle(v &i64,n usize,mut out &u8,cap usize)i64{unsafe{
 if v==nil||n<7||n>17||v[0]<3||v[0]>max_n{return -1};count:=int(v[0]);if n!=usize(1+2*count){return -1};mut pts:=[max_n]Point{}
 for i in 0..count{x,y:=v[1+2*i],v[2+2*i];if x < -50||x>50||y < -50||y>50{return -1};for j in 0..i{if pts[j].x==x&&pts[j].y==y{return -1}};pts[i]=Point{x,y}}
 for a in 0..count{for b in a+1..count{for c in b+1..count{if orient(pts[a],pts[b],pts[c])==0{return -1}}}}
 for a in 0..count{for b in a+1..count{for c in b+1..count{for d in c+1..count{if circle(pts[a],pts[b],pts[c],pts[d])==0{return -1}}}}}
 mut edges:=[max_n][max_n]bool{};for a in 0..count{for b in a+1..count{for c in b+1..count{o:=orient(pts[a],pts[b],pts[c]);mut empty:=true;for d in 0..count{if d!=a&&d!=b&&d!=c{z:=circle(pts[a],pts[b],pts[c],pts[d]);if (o>0&&z>0)||(o<0&&z<0){empty=false;break}}};if empty{edges[a][b]=true;edges[b][a]=true;edges[a][c]=true;edges[c][a]=true;edges[b][c]=true;edges[c][b]=true}}}}
 mut fields:=[max_fields]i64{};mut at:=1;mut m:=0;for a in 0..count{for b in a+1..count{if edges[a][b]{fields[at]=i64(a);fields[at+1]=i64(b);at+=2;m++}}};fields[0]=i64(m);bytes:=8*at;if out==nil||cap<usize(bytes){return -2};for i in 0..at{put(mut out,8*i,fields[i])};return i64(bytes)
}}
