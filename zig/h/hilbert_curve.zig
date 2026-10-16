const std=@import("std");
fn reverse(o:*[8192]i64,start:usize,n:usize)void{var i:usize=0;while(i<n/2):(i+=1){const a=start+2*i;const b=start+2*(n-1-i);std.mem.swap(i64,&o[a],&o[b]);std.mem.swap(i64,&o[a+1],&o[b+1]);}}
fn curve(x:i64,y:i64,side:i64,level:i32,angle:i32,o:*[8192]i64,off:usize)usize{
 const q=@divTrunc(side,4);const P=[4][2]i64.{.{x+q,y+q},.{x-q,y+q},.{x-q,y-q},.{x+q,y-q}};const a=@mod(angle,4);var r:[4][2]i64=undefined;for(0..4)|i|{r[i]=P[(i+@as(usize,@intCast(a)))%4];}
 if(level==1){for(0..4)|i|{o[off+2*i]=r[i][0];o[off+2*i+1]=r[i][1];}return 4;}
 const h=@divTrunc(side,2);const n=curve(r[0][0],r[0][1],h,level-1,a+1,o,off);reverse(o,off,n);const n1=curve(r[1][0],r[1][1],h,level-1,a,o,off+2*n);const n2=curve(r[2][0],r[2][1],h,level-1,a,o,off+2*(n+n1));const n3=curve(r[3][0],r[3][1],h,level-1,a-1,o,off+2*(n+n1+n2));reverse(o,off+2*(n+n1+n2),n3);return n+n1+n2+n3;
}
export fn hilbert_curve(v:[*]const i64,n:usize,out:[*]u8,cap:usize)i64{if(n!=2)return -1;const level=v[0];const angle=v[1];if(level<1 or level>6 or angle<0 or angle>3)return -1;const l:usize=@intCast(level);const points=@as(usize,1)<<(2*l);const bytes=points*16;if(cap<bytes)return -2;var coords:[8192]i64=undefined;_=curve(0,0,@as(i64,1)<<@intCast(l+1),@intCast(l),@intCast(angle),&coords,0);for(0..points*2)|i|{const b=@as(u64,@bitCast(coords[i]));for(0..8)|k|{out[i*8+k]=@truncate(b>>(8*k));}}return @intCast(bytes);}
