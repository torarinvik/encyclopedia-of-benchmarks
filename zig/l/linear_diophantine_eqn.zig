fn gcdv(a0:i64,b0:i64)i64{var a=if(a0<0)-a0 else a0;var b=if(b0<0)-b0 else b0;while(b!=0){const r=@rem(a,b);a=b;b=r;}return a;}
export fn linear_diophantine_eqn(v:[*]const i64,n:usize)i64{if(n!=3)return -1;const a=v[0];const b=v[1];const c=v[2];if(a< -100000 or a>100000 or b==0 or b< -100000 or b>100000 or c< -1000000 or c>1000000)return -1;return if(@rem(c,gcdv(a,b))==0) 1 else 0;}
