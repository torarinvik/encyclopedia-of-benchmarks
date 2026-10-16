package nearest_neighbour_search
import "core:c"
base :: proc(d,i:int)->int{return 2+d+i*(d+2)}
valid_tree :: proc(v:[^]i64,d,n,i:int,seen:^bool,reached:^int)->bool{if i<0{return true};if i>=n||seen[i]{return false};seen[i]=true;reached^ = reached^ + 1;b:=base(d,i);l:=int(v[b+d]);r:=int(v[b+d+1]);if l>=0&&l==r{return false};return valid_tree(v,d,n,l,seen,reached)&&valid_tree(v,d,n,r,seen,reached)}
search_tree :: proc(v:[^]i64,d,i,depth:int,q:[3]i64,best:^i64,bestd:^i64,visited:^i64){if i<0{return};visited^ = visited^ + 1;b:=base(d,i);dist:i64=0;for k:=0;k<d;k+=1{delta:=q[k]-v[b+k];dist+=delta*delta};if dist<bestd^{bestd^ = dist;for k:=0;k<d;k+=1{best[k]=v[b+k]}};axis:=depth%d;l:=int(v[b+d]);r:=int(v[b+d+1]);near,far:=l,r;if q[axis]>v[b+axis]{near,far=r,l};search_tree(v,d,near,depth+1,q,best,bestd,visited);split:=q[axis]-v[b+axis];if split*split<bestd^{search_tree(v,d,far,depth+1,q,best,bestd,visited)}}
put_i64 :: proc(outp:[^]u8,offset:int,x:i64){bits:=transmute(u64)x;for k:=0;k<8;k+=1{outp[offset+k]=u8(bits>>u64(8*k))}}
@(export)
nearest_neighbour_search :: proc "c"(v:[^]i64,n:c.size_t,outp:[^]u8,cap:c.size_t)->i64{
if v==nil||n<5{return -1};d0,n0:=v[0],v[1];if(d0!=2&&d0!=3)||n0<1||n0>15{return -1};d,count:=int(d0),int(n0);if n!=c.size_t(2+d+count*(d+2)){return -1};q:[3]i64;best:[3]i64
for k:=0;k<d;k+=1{q[k]=v[2+k];if q[k]< -1000||q[k]>1000{return -1}}
for i:=0;i<count;i+=1{b:=base(d,i);for k:=0;k<d;k+=1{if v[b+k]< -1000||v[b+k]>1000{return -1}};l,r:=v[b+d],v[b+d+1];if l < -1||l>=n0||r < -1||r>=n0||(l>=0&&l==r){return -1}}
seen:[15]bool;reached:=0;if !valid_tree(v,d,count,0,&seen[0],&reached)||reached!=count{return -1};bestd:=i64(9223372036854775807);visited:i64=0;search_tree(v,d,0,0,q,&best[0],&bestd,&visited);if outp==nil||cap<48{return -2};result:=[6]i64{d0,best[0],best[1],0,bestd,visited};if d==3{result[3]=best[2]};for k:=0;k<6;k+=1{put_i64(outp,k*8,result[k])};return 48
}
