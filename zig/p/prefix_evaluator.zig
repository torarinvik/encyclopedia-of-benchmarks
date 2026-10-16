const std = @import("std");
export fn prefix_evaluator(v:[*c]const i64,n:usize)i64{
 if(v==null||n<2||n>129||v[0]<1||v[0]>128||n!=@as(usize,@intCast(v[0]))+1)return -1;
 var st:[128]i32=undefined;var sp:usize=0;var i=n;
 while(i>1){i-=1;const t=v[i];if(t == -9000000000000000001 or t == -9000000000000000002 or t == -9000000000000000003 or t == -9000000000000000004){if(sp<2)return -1;const a=st[sp-1];const b=st[sp-2];sp-=2;var z:i32=0;if(t == -9000000000000000001)z=@bitCast(@as(u32,@bitCast(a))+%@as(u32,@bitCast(b)))else if(t == -9000000000000000002)z=@bitCast(@as(u32,@bitCast(a))-%@as(u32,@bitCast(b)))else if(t == -9000000000000000003)z=@bitCast(@as(u32,@bitCast(a))*%@as(u32,@bitCast(b)))else{if(b==0)return -1;z=if(a==std.math.minInt(i32) and b == -1)std.math.minInt(i32)else @divTrunc(a,b);}st[sp]=z;sp+=1;}else{if(t < -2147483648 or t > 2147483647 or sp>=128)return -1;st[sp]=@intCast(t);sp+=1;}}
 return if(sp==1)st[0]else -1;
}
