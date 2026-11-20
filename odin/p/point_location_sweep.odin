// Offline point location by sweeping edge endpoints and query x-coordinates.
package point_location_sweep
import "core:c"

Point :: struct { x:i64, y:i64 }
Edge :: struct { u:int, v:int, face:int }
Event :: struct { x:i64, kind:int, id:int }
State :: struct { points:[16]Point, edges:[24]Edge }

cross :: proc "contextless" (a,b,c:Point)->i64{return (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x)}
on_segment :: proc "contextless" (a,b,p:Point)->bool{return cross(a,b,p)==0&&p.x>=min(a.x,b.x)&&p.x<=max(a.x,b.x)&&p.y>=min(a.y,b.y)&&p.y<=max(a.y,b.y)}
intersects :: proc "contextless" (a,b,c,d:Point)->bool{o1:=cross(a,b,c);o2:=cross(a,b,d);o3:=cross(c,d,a);o4:=cross(c,d,b);if (o1==0&&on_segment(a,b,c))||(o2==0&&on_segment(a,b,d))||(o3==0&&on_segment(c,d,a))||(o4==0&&on_segment(c,d,b)){return true};return ((o1<0&&o2>0)||(o1>0&&o2<0))&&((o3<0&&o4>0)||(o3>0&&o4<0))}
left_id :: proc "contextless" (s:^State,e:Edge)->int{return if s.points[e.u].x<s.points[e.v].x do e.u else e.v}
right_id :: proc "contextless" (s:^State,e:Edge)->int{return if s.points[e.u].x<s.points[e.v].x do e.v else e.u}
height_num :: proc "contextless" (s:^State,e:Edge,x:i64,den:^i64)->i64{l:=left_id(s,e);r:=right_id(s,e);den^ =s.points[r].x-s.points[l].x;return s.points[l].y*den^+(s.points[r].y-s.points[l].y)*(x-s.points[l].x)}
edge_less :: proc "contextless" (s:^State,a,b:int,x:i64)->bool{var d1,d2:i64;n1:=height_num(s,s.edges[a],x,&d1);n2:=height_num(s,s.edges[b],x,&d2);if n1*d2!=n2*d1{return n1*d2<n2*d1};l1:=left_id(s,s.edges[a]);r1:=right_id(s,s.edges[a]);l2:=left_id(s,s.edges[b]);r2:=right_id(s,s.edges[b]);s1:=(s.points[r1].y-s.points[l1].y)*(s.points[r2].x-s.points[l2].x);s2:=(s.points[r2].y-s.points[l2].y)*(s.points[r1].x-s.points[l1].x);if s1!=s2{return s1<s2};return a<b}
event_less :: proc "contextless" (a,b:Event)->bool{if a.x!=b.x{return a.x<b.x};if a.kind!=b.kind{return a.kind<b.kind};return a.id<b.id}
query_answer :: proc "contextless" (s:^State,active:[^]int,count:int,x,y:i64,faces:int)->i64{lo,hi:=0,count;for lo<hi{mid:=lo+(hi-lo)/2;var den:i64;num:=height_num(s,s.edges[active[mid]],x,&den);if num<y*den{lo=mid+1}else{hi=mid}};if lo<count{var den:i64;num:=height_num(s,s.edges[active[lo]],x,&den);if num==y*den{return i64(faces+active[lo]+1)}};if lo==0||s.edges[active[lo-1]].face<0{return 0};return i64(s.edges[active[lo-1]].face+1)}

@(export)
point_location_sweep :: proc "c" (input:[^]i64,length:c.size_t)->i64{
 if input==nil||length<4||length>141 do return -1
 nr,mr,qr,fr:=input[0],input[1],input[2],input[3];if nr<2||nr>16||mr<1||mr>24||qr<0||qr>16||fr<1||fr>16 do return -1
 n,m,q,faces:=int(nr),int(mr),int(qr),int(fr);if int(length)!=4+2*n+3*m+2*q do return -1
 s:State={};queries:[16]Point={};cursor:=4
 for i:=0;i<n;i+=1{s.points[i]=Point{input[cursor],input[cursor+1]};cursor+=2;if s.points[i].x< -300||s.points[i].x>300||s.points[i].y< -300||s.points[i].y>300 do return -1;for j:=0;j<i;j+=1{if s.points[j].x==s.points[i].x do return -1}}
 for i:=0;i<m;i+=1{u,v,f:=input[cursor],input[cursor+1],input[cursor+2];cursor+=3;if u<0||u>=nr||v<0||v>=nr||u==v||f< -1||f>=fr do return -1;s.edges[i]=Edge{int(u),int(v),int(f)};for j:=0;j<i;j+=1{if(s.edges[j].u==int(u)&&s.edges[j].v==int(v))||(s.edges[j].u==int(v)&&s.edges[j].v==int(u)) do return -1;su:=s.edges[j].u==int(u)||s.edges[j].u==int(v);sv:=s.edges[j].v==int(u)||s.edges[j].v==int(v);if su||sv{common:=if su do s.edges[j].u else s.edges[j].v;oa:=if int(u)==common do int(v) else int(u);ob:=if s.edges[j].u==common do s.edges[j].v else s.edges[j].u;if cross(s.points[common],s.points[oa],s.points[ob])==0 do return -1}else if intersects(s.points[int(u)],s.points[int(v)],s.points[s.edges[j].u],s.points[s.edges[j].v]) do return -1}}
 for i:=0;i<q;i+=1{queries[i]=Point{input[cursor],input[cursor+1]};cursor+=2;if queries[i].x< -300||queries[i].x>300||queries[i].y< -300||queries[i].y>300 do return -1;for j:=0;j<n;j+=1{if queries[i].x==s.points[j].x do return -1}}
 events:[64]Event={};ec:=0;for i:=0;i<m;i+=1{l:=left_id(&s,s.edges[i]);r:=right_id(&s,s.edges[i]);events[ec]=Event{s.points[l].x,1,i};ec+=1;events[ec]=Event{s.points[r].x,0,i};ec+=1};for i:=0;i<q;i+=1{events[ec]=Event{queries[i].x,2,i};ec+=1};for i:=1;i<ec;i+=1{key:=events[i];j:=i;for j>0&&event_less(key,events[j-1]){events[j]=events[j-1];j-=1};events[j]=key}
 active:[24]int={};ac:=0;answers:[16]i64={};for ei:=0;ei<ec;ei+=1{ev:=events[ei];if ev.kind==0{pos:=0;for pos<ac&&active[pos]!=ev.id{pos+=1};if pos==ac do return -1;for j:=pos+1;j<ac;j+=1{active[j-1]=active[j]};ac-=1}else if ev.kind==1{lo,hi:=0,ac;for lo<hi{mid:=lo+(hi-lo)/2;if edge_less(&s,active[mid],ev.id,ev.x){lo=mid+1}else{hi=mid}};for j:=ac;j>lo;j-=1{active[j]=active[j-1]};active[lo]=ev.id;ac+=1}else{answers[ev.id]=query_answer(&s,&active[0],ac,ev.x,queries[ev.id].y,faces)}}
 result:i64=0;for i:=0;i<q;i+=1{result+=i64(i+1)*answers[i]};return result
}
