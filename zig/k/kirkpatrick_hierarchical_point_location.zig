const max_vertices: usize = 16;
const max_levels: usize = 4;
const max_faces: usize = 8;
const max_input: usize = 268;

fn cross(ax:i64,ay:i64,bx:i64,by:i64,cx:i64,cy:i64)i64{return (bx-ax)*(cy-ay)-(by-ay)*(cx-ax);}
fn on_segment(ax:i64,ay:i64,bx:i64,by:i64,px:i64,py:i64)bool{return cross(ax,ay,bx,by,px,py)==0 and px>=@min(ax,bx) and px<=@max(ax,bx) and py>=@min(ay,by) and py<=@max(ay,by);}
fn inside(qx:i64,qy:i64,t:[]const i64,xy:[]const i64)bool{const a:usize=@intCast(2*t[0]);const b:usize=@intCast(2*t[1]);const c:usize=@intCast(2*t[2]);return cross(xy[a],xy[a+1],xy[b],xy[b+1],qx,qy)>0 and cross(xy[b],xy[b+1],xy[c],xy[c+1],qx,qy)>0 and cross(xy[c],xy[c+1],xy[a],xy[a+1],qx,qy)>0;}
fn boundary(qx:i64,qy:i64,t:[]const i64,xy:[]const i64)bool{for(0..3)|e|{const a:usize=@intCast(2*t[e]);const b:usize=@intCast(2*t[(e+1)%3]);if(on_segment(xy[a],xy[a+1],xy[b],xy[b+1],qx,qy))return true;}return false;}
fn seg_hit(ax:i64,ay:i64,bx:i64,by:i64,cx:i64,cy:i64,dx:i64,dy:i64)bool{const o1=cross(ax,ay,bx,by,cx,cy);const o2=cross(ax,ay,bx,by,dx,dy);const o3=cross(cx,cy,dx,dy,ax,ay);const o4=cross(cx,cy,dx,dy,bx,by);if(o1==0 and on_segment(ax,ay,bx,by,cx,cy))return true;if(o2==0 and on_segment(ax,ay,bx,by,dx,dy))return true;if(o3==0 and on_segment(cx,cy,dx,dy,ax,ay))return true;if(o4==0 and on_segment(cx,cy,dx,dy,bx,by))return true;return o1*o2<0 and o3*o4<0;}
fn closed_inside(px:i64,py:i64,t:[]const i64,xy:[]const i64)bool{for(0..3)|e|{const a:usize=@intCast(2*t[e]);const b:usize=@intCast(2*t[(e+1)%3]);if(cross(xy[a],xy[a+1],xy[b],xy[b+1],px,py)<0)return false;}return true;}
fn tri_hit(a:[]const i64,b:[]const i64,xy:[]const i64)bool{for(0..3)|i|{const p:usize=@intCast(2*a[i]);if(closed_inside(xy[p],xy[p+1],b,xy))return true;const q:usize=@intCast(2*b[i]);if(closed_inside(xy[q],xy[q+1],a,xy))return true;}for(0..3)|i|{for(0..3)|j|{const a0:usize=@intCast(2*a[i]);const a1:usize=@intCast(2*a[(i+1)%3]);const b0:usize=@intCast(2*b[j]);const b1:usize=@intCast(2*b[(j+1)%3]);if(seg_hit(xy[a0],xy[a0+1],xy[a1],xy[a1+1],xy[b0],xy[b0+1],xy[b1],xy[b1+1]))return true;}}return false;}
fn put64(out:[*]u8,pos:usize,value:i64)void{const bits:u64=@bitCast(value);for(0..8)|j|out[pos+j]=@truncate(bits>>@intCast(8*j));}

export fn kirkpatrick_hierarchical_point_location(input_opt:?[*]const i64,length:usize,output_opt:?[*]u8,capacity:usize)i64{
    if(input_opt==null or length<14 or length>max_input)return -1;
    const input=input_opt.?;const nv64=input[0];const nl64=input[1];const qx=input[2];const qy=input[3];
    if(nv64<3 or nv64>16 or nl64<1 or nl64>4 or qx< -1000 or qx>1000 or qy< -1000 or qy>1000)return -1;
    const nv:usize=@intCast(nv64);const nl:usize=@intCast(nl64);
    var xy:[max_vertices*2]i64=@splat(0);var faces:[max_levels*max_faces*3]i64=@splat(0);var fc:[max_levels]usize=@splat(0);var cc:[max_levels*max_faces]usize=@splat(0);var ids:[max_levels*max_faces*max_faces]usize=@splat(0);var pos:usize=4;
    for(0..nv)|v|{xy[2*v]=input[pos];xy[2*v+1]=input[pos+1];pos+=2;if(xy[2*v]< -1000 or xy[2*v]>1000 or xy[2*v+1]< -1000 or xy[2*v+1]>1000)return -1;}
    for(0..nl)|level|{if(pos>=length)return -1;const count64=input[pos];pos+=1;if(count64<1 or count64>8 or(level==0 and count64!=1))return -1;const count:usize=@intCast(count64);fc[level]=count;
        for(0..count)|f|{if(pos+3>length)return -1;const base=(level*max_faces+f)*3;for(0..3)|k|{const id=input[pos];pos+=1;if(id<0 or id>=nv64)return -1;faces[base+k]=id;}const a:usize=@intCast(2*faces[base]);const b:usize=@intCast(2*faces[base+1]);const c:usize=@intCast(2*faces[base+2]);if(faces[base]==faces[base+1] or faces[base]==faces[base+2] or faces[base+1]==faces[base+2] or cross(xy[a],xy[a+1],xy[b],xy[b+1],xy[c],xy[c+1])<=0)return -1;}
        if(level+1<nl){for(0..count)|f|{if(pos>=length)return -1;const n64=input[pos];pos+=1;if(n64<1 or n64>8)return -1;const n:usize=@intCast(n64);if(pos+n>length)return -1;cc[level*max_faces+f]=n;for(0..n)|j|{const id=input[pos];pos+=1;if(id<0 or id>=8)return -1;const child:usize=@intCast(id);const slot=(level*max_faces+f)*max_faces+j;if(j>0 and child<=ids[slot-1])return -1;ids[slot]=child;}}}
    }
    if(pos!=length)return -1;
    for(0..(nl-1))|level|{for(0..fc[level])|f|{for(0..cc[level*max_faces+f])|j|{const child=ids[(level*max_faces+f)*max_faces+j];if(child>=fc[level+1])return -1;const a=(level*max_faces+f)*3;const b=((level+1)*max_faces+child)*3;if(!tri_hit(faces[a..a+3],faces[b..b+3],xy[0..]))return -1;}}}
    for(0..nl)|level|{var hits:usize=0;for(0..fc[level])|f|{const base=(level*max_faces+f)*3;if(boundary(qx,qy,faces[base..base+3],xy[0..]))return -1;if(inside(qx,qy,faces[base..base+3],xy[0..]))hits+=1;}if(hits!=1)return -1;}
    var face:usize=0;var predicates:i64=1;for(0..(nl-1))|level|{var found:?usize=null;for(0..cc[level*max_faces+face])|j|{const child=ids[(level*max_faces+face)*max_faces+j];predicates+=1;const base=((level+1)*max_faces+child)*3;if(inside(qx,qy,faces[base..base+3],xy[0..])){found=child;break;}}if(found==null)return -1;face=found.?;}
    if(output_opt==null or capacity<16)return -2;var staged:[16]u8=@splat(0);put64(&staged,0,@intCast(face));put64(&staged,8,predicates);const output=output_opt.?;for(0..16)|i|output[i]=staged[i];return 16;
}
