export fn star_delta_conversions(v:?[*]const i64,n:usize)i64{
 if(v==null or n!=4)return -1;const input=v.?;if(input[0]!=0 and input[0]!=1)return -1;for(1..4)|i|{if(input[i]<1000 or input[i]>100000)return -1;}
 const a=@as(f64,@floatFromInt(input[1]));const b=@as(f64,@floatFromInt(input[2]));const c=@as(f64,@floatFromInt(input[3]));var out:[3]f64=undefined;
 if(input[0]==0){const p=a*b+b*c+c*a;out=[_]f64{p/a,p/b,p/c};}else{const s=a+b+c;out=[_]f64{b*c/s,c*a/s,a*b/s};}
 var h:u64=0xcbf29ce484222325;for(out)|x|{const q:i64=@intFromFloat(@floor(x+0.5));const u=@as(u64,@bitCast(q));for(0..8)|j|{h=(h^((u>>(8*j))&255))*%0x100000001b3;}}
 return @bitCast(h);
}
