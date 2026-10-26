// Clean-room exact Delaunay graph construction by empty circumcircles.
package voronoi_delaunay_empty_circle
import "core:c"
import "core:math"
const MAX_N :: 8
const MAX_FIELDS :: 37
Point :: struct{x,y:i64}
orient :: proc "contextless"(a,b,c:Point)->i64{return (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x)}
circle :: proc "contextless"(a,b,c,d:Point)->i64{ax,ay:=a.x-d.x,a.y-d.y;bx,by:=b.x-d.x,b.y-d.y;cx,cy:=c.x-d.x,c.y-d.y;aa:=ax*ax+ay*ay;bb:=bx*bx+by*by;cc:=cx*cx+cy*cy;return aa*(bx*cy-by*cx)-bb*(ax*cy-ay*cx)+cc*(ax*by-ay*bx)}
put :: proc "contextless"(out:[^]u8,at:int,x:i64){bits:=u64(x);for i:=0;i<8;i+=1{out[at+i]=u8(bits&255);bits>>=8}}
@(export)
voronoi_delaunay_empty_circle :: proc "c"(v:[^]i64,n:c.size_t,out:[^]u8,cap:c.size_t)->i64{
 if v==nil||n<7||n>17||v[0]<3||v[0]>MAX_N do return -1;count:=int(v[0]);if n!=c.size_t(1+2*count) do return -1;points:[MAX_N]Point
 for i:=0;i<count;i+=1{x,y:=v[1+2*i],v[2+2*i];if x < -50||x>50||y < -50||y>50 do return -1;for j:=0;j<i;j+=1{if points[j].x==x&&points[j].y==y do return -1};points[i]=Point{x,y}}
 for a:=0;a<count;a+=1{for b:=a+1;b<count;b+=1{for c0:=b+1;c0<count;c0+=1{if orient(points[a],points[b],points[c0])==0 do return -1}}}}
 for a:=0;a<count;a+=1{for b:=a+1;b<count;b+=1{for c0:=b+1;c0<count;c0+=1{for d:=c0+1;d<count;d+=1{if circle(points[a],points[b],points[c0],points[d])==0 do return -1}}}}}
 edges:[MAX_N][MAX_N]bool;for a:=0;a<count;a+=1{for b:=a+1;b<count;b+=1{for c0:=b+1;c0<count;c0+=1{o:=orient(points[a],points[b],points[c0]);empty:=true;for d:=0;d<count;d+=1{if d!=a&&d!=b&&d!=c0{z:=circle(points[a],points[b],points[c0],points[d]);if (o>0&&z>0)||(o<0&&z<0){empty=false;break}}};if empty{edges[a][b]=true;edges[b][a]=true;edges[a][c0]=true;edges[c0][a]=true;edges[b][c0]=true;edges[c0][b]=true}}}}
 fields:[MAX_FIELDS]i64;at:=1;m:=0;for a:=0;a<count;a+=1{for b:=a+1;b<count;b+=1{if edges[a][b]{fields[at]=i64(a);fields[at+1]=i64(b);at+=2;m+=1}}};fields[0]=i64(m);bytes:=8*at;if out==nil||cap<c.size_t(bytes) do return -2;for i:=0;i<at;i+=1{put(&out[0],8*i,fields[i])};return i64(bytes)
}
