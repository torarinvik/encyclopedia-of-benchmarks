fn gcdPos(a0:i64,b0:i64)i64{var a=@as(i64,@intCast(@abs(a0)));var b=@as(i64,@intCast(@abs(b0)));while(b!=0){const r=@rem(a,b);a=b;b=r;}return a;}
fn putI64(o:[*]u8,p:usize,x:i64)void{const bits=@as(u64,@bitCast(x));for(0..8)|k|o[p+k]=@truncate(bits>>(8*k));}
export fn fraction(v:[*]const i64,n:usize,o:[*]u8,cap:usize)i64{
 if(n!=4)return -1;const n1=v[0];const d1=v[1];const n2=v[2];const d2=v[3];
 if(n1 < -10000 or n1>10000 or n2 < -10000 or n2>10000 or d1 < -1000 or d1>1000 or d2 < -1000 or d2>1000 or d1==0 or d2==0)return -1;
 if(cap<16)return -2;const g=gcdPos(d1,d2);var num=(d2/@as(i64,g))*n1+(d1/@as(i64,g))*n2;var den=(d1/@as(i64,g))*d2;
 const r=gcdPos(num,den);num=@divTrunc(num,r);den=@divTrunc(den,r);if(den<0){num = -num;den = -den;}putI64(o,0,num);putI64(o,8,den);return 16;
}
