export fn uint53_is(v:[*c]const i64,n:usize)i64{if(v==null or n!=1)return -1;return if(v[0]>=0 and v[0]<9007199254740992) 1 else 0;}
