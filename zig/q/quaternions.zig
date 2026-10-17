const std = @import("std");
const MAX_INPUT: usize = 10;
export fn quaternions(input: [*c]const f64, length: usize, output: [*c]f64, capacity: usize) i64 {
    if (input == null or length < 1 or length > MAX_INPUT) return -1;
    for (0..length) |i| { if (!std.math.isFinite(input[i])) return -1; }
    const op=input[0];if(op!=0.0 and op!=1.0 and op!=2.0)return -1;const mode:u8=@intFromFloat(op);const expected:usize=if(mode==0)4 else if(mode==1)5 else 9;const count:usize=if(mode==1)3 else 4;if(length!=expected)return -1;
    var v=[_]f32{0}**8;
    if(mode==0){for(1..4)|i|{if(input[i]<-3.0 or input[i]>3.0)return -1;v[i-1]=@floatCast(input[i]);}}
    else if(mode==1){for(1..5)|i|{v[i-1]=@floatCast(input[i]);if(v[i-1]<-1.0 or v[i-1]>1.0)return -1;}const w=v[0];const a=v[1];const b=v[2];const c=v[3];var norm=w*w;norm=norm+a*a;norm=norm+b*b;norm=norm+c*c;if(@abs(norm-1.0)>1e-6)return -1;var pa=w*b+a*c;pa=2.0*pa;if(pa < -1.0 or pa>1.0)return -1;}
    else{for(1..9)|i|{if(input[i]<-1.0 or input[i]>1.0)return -1;v[i-1]=@floatCast(input[i]);}}
    if(output==null or capacity<count)return -2;var r=[_]f32{0}**4;
    if(mode==0){const y=v[0];const p=v[1];const roll=v[2];const cy=@cos(y*0.5);const sy=@sin(y*0.5);const cp=@cos(p*0.5);const sp=@sin(p*0.5);const cr=@cos(roll*0.5);const sr=@sin(roll*0.5);r[0]=(cr*cp)*cy+(sr*sp)*sy;r[1]=(sr*cp)*cy-(cr*sp)*sy;r[2]=(cr*sp)*cy+(sr*cp)*sy;r[3]=(cr*cp)*sy-(sr*sp)*cy;}
    else if(mode==1){const w=v[0];const a=v[1];const b=v[2];const c=v[3];const ry=2.0*(w*a+b*c);const rx=1.0-2.0*(a*a+b*b);const pitch=@asin(2.0*(w*b+a*c));const yy=2.0*(w*c+a*b);const yx=1.0-2.0*(b*b+c*c);r[0]=@atan2(ry,rx);r[1]=pitch;r[2]=@atan2(yy,yx);}
    else{const aw=v[0];const a1=v[1];const a2=v[2];const a3=v[3];const bw=v[4];const b1=v[5];const b2=v[6];const b3=v[7];r[0]=((aw*bw-a1*b1)-a2*b2)-a3*b3;r[1]=((aw*b1+a1*bw)+a2*b3)-a3*b2;r[2]=((aw*b2-a1*b3)+a2*bw)+a3*b1;r[3]=((aw*b3+a1*b2)-a2*b1)+a3*bw;}
    for(0..count)|i|output[i]=@floatCast(r[i]);return @intCast(count);
}
