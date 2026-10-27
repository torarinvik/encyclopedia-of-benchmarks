package kirkpatrick_hierarchical_point_location
import "core:c"

MAX_VERTICES :: 16
MAX_LEVELS :: 4
MAX_FACES :: 8
MAX_INPUT :: 268

cross :: proc(ax,ay,bx,by,cx,cy:i64)->i64{return (bx-ax)*(cy-ay)-(by-ay)*(cx-ax)}
on_segment :: proc(ax,ay,bx,by,px,py:i64)->bool{return cross(ax,ay,bx,by,px,py)==0&&px>=min(ax,bx)&&px<=max(ax,bx)&&py>=min(ay,by)&&py<=max(ay,by)}
inside :: proc(qx,qy:i64,t,xy:[^]i64)->bool{a:=int(t[0]*2);b:=int(t[1]*2);c0:=int(t[2]*2);return cross(xy[a],xy[a+1],xy[b],xy[b+1],qx,qy)>0&&cross(xy[b],xy[b+1],xy[c0],xy[c0+1],qx,qy)>0&&cross(xy[c0],xy[c0+1],xy[a],xy[a+1],qx,qy)>0}
boundary :: proc(qx,qy:i64,t,xy:[^]i64)->bool{for e:=0;e<3;e+=1{a:=int(t[e]*2);b:=int(t[(e+1)%3]*2);if on_segment(xy[a],xy[a+1],xy[b],xy[b+1],qx,qy){return true}}return false}
seg_hit :: proc(ax,ay,bx,by,cx,cy,dx,dy:i64)->bool{o1:=cross(ax,ay,bx,by,cx,cy);o2:=cross(ax,ay,bx,by,dx,dy);o3:=cross(cx,cy,dx,dy,ax,ay);o4:=cross(cx,cy,dx,dy,bx,by);if o1==0&&on_segment(ax,ay,bx,by,cx,cy){return true};if o2==0&&on_segment(ax,ay,bx,by,dx,dy){return true};if o3==0&&on_segment(cx,cy,dx,dy,ax,ay){return true};if o4==0&&on_segment(cx,cy,dx,dy,bx,by){return true};return o1*o2<0&&o3*o4<0}
closed_inside :: proc(px,py:i64,t,xy:[^]i64)->bool{for e:=0;e<3;e+=1{a:=int(t[e]*2);b:=int(t[(e+1)%3]*2);if cross(xy[a],xy[a+1],xy[b],xy[b+1],px,py)<0{return false}}return true}
tri_hit :: proc(a,b,xy:[^]i64)->bool{for i:=0;i<3;i+=1{p:=int(a[i]*2);if closed_inside(xy[p],xy[p+1],b,xy){return true};p=int(b[i]*2);if closed_inside(xy[p],xy[p+1],a,xy){return true}};for i:=0;i<3;i+=1{for j:=0;j<3;j+=1{a0:=int(a[i]*2);a1:=int(a[(i+1)%3]*2);b0:=int(b[j]*2);b1:=int(b[(j+1)%3]*2);if seg_hit(xy[a0],xy[a0+1],xy[a1],xy[a1+1],xy[b0],xy[b0+1],xy[b1],xy[b1+1]){return true}}}return false}
put64 :: proc(out:[^]u8,pos:int,value:i64){bits:=u64(value);for j:=0;j<8;j+=1{out[pos+j]=u8(bits&255);bits>>=8}}

@(export)
kirkpatrick_hierarchical_point_location :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
    if input==nil||length<14||length>MAX_INPUT do return -1
    nv:=input[0];nl:=input[1];qx:=input[2];qy:=input[3]
    if nv<3||nv>MAX_VERTICES||nl<1||nl>MAX_LEVELS||qx< -1000||qx>1000||qy< -1000||qy>1000 do return -1
    n:=int(nv);levels:=int(nl)
    length_i:=int(length)
    xy:[MAX_VERTICES*2]i64={};faces:[MAX_LEVELS*MAX_FACES*3]i64={};fc:[MAX_LEVELS]int={};cc:[MAX_LEVELS*MAX_FACES]int={};ids:[MAX_LEVELS*MAX_FACES*MAX_FACES]int={}
    pos:=4
    for v:=0;v<n;v+=1{xy[2*v]=input[pos];xy[2*v+1]=input[pos+1];pos+=2;if xy[2*v]< -1000||xy[2*v]>1000||xy[2*v+1]< -1000||xy[2*v+1]>1000{return -1}}
    for level:=0;level<levels;level+=1{if pos>=length_i{return -1};count64:=input[pos];pos+=1;if count64<1||count64>MAX_FACES||(level==0&&count64!=1){return -1};count:=int(count64);fc[level]=count
        for f:=0;f<count;f+=1{if pos+3>length_i{return -1};base:=(level*MAX_FACES+f)*3;for k:=0;k<3;k+=1{faces[base+k]=input[pos];pos+=1;if faces[base+k]<0||faces[base+k]>=nv{return -1}};a:=int(faces[base]*2);b:=int(faces[base+1]*2);c0:=int(faces[base+2]*2);if faces[base]==faces[base+1]||faces[base]==faces[base+2]||faces[base+1]==faces[base+2]||cross(xy[a],xy[a+1],xy[b],xy[b+1],xy[c0],xy[c0+1])<=0{return -1}}
        if level+1<levels{for f:=0;f<count;f+=1{if pos>=length_i{return -1};count64:=input[pos];pos+=1;if count64<1||count64>MAX_FACES||pos+int(count64)>length_i{return -1};n:=int(count64);cc[level*MAX_FACES+f]=n;for j:=0;j<n;j+=1{child64:=input[pos];pos+=1;if child64<0||child64>=MAX_FACES{return -1};child:=int(child64);if j>0&&child<=ids[(level*MAX_FACES+f)*MAX_FACES+j-1]{return -1};ids[(level*MAX_FACES+f)*MAX_FACES+j]=child}}}
    }
    if pos!=length_i{return -1}
    for level:=0;level+1<levels;level+=1{for f:=0;f<fc[level];f+=1{for j:=0;j<cc[level*MAX_FACES+f];j+=1{child:=ids[(level*MAX_FACES+f)*MAX_FACES+j];if child>=fc[level+1]||!tri_hit(&faces[(level*MAX_FACES+f)*3],&faces[((level+1)*MAX_FACES+child)*3],&xy[0]){return -1}}}}
    for level:=0;level<levels;level+=1{hits:=0;for f:=0;f<fc[level];f+=1{base:=(level*MAX_FACES+f)*3;if boundary(qx,qy,&faces[base],&xy[0]){return -1};if inside(qx,qy,&faces[base],&xy[0]){hits+=1}};if hits!=1{return -1}}
    face:=i64(0);predicates:=i64(1)
    for level:=0;level+1<levels;level+=1{found:=i64(-1);for j:=0;j<cc[level*MAX_FACES+int(face)];j+=1{child:=ids[(level*MAX_FACES+int(face))*MAX_FACES+j];predicates+=1;if inside(qx,qy,&faces[((level+1)*MAX_FACES+child)*3],&xy[0]){found=i64(child);break}};if found<0{return -1};face=found}
    if output==nil||capacity<c.size_t(16) do return -2
    staged:[16]u8={};put64(&staged[0],0,face);put64(&staged[0],8,predicates);for i:=0;i<16;i+=1{output[i]=staged[i]};return 16
}
