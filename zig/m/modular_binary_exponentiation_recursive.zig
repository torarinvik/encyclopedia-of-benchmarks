fn power(a:i64,e:i64,m:i64)i64{if(e==0)return 1;if(@mod(e,2)==1)return @mod(power(a,e-1,m)*a,m);const h=power(a,@divTrunc(e,2),m);return @mod(h*h,m);}
export fn modular_binary_exponentiation_recursive(v:[*c]const i64,n:usize)i64{if(v==null or n!=3)return -1;const a=v[0];const e=v[1];const m=v[2];if(a<0 or a>1000000 or e<0 or e>60 or m<2 or m>1000000)return -1;return power(a,e,m);}
