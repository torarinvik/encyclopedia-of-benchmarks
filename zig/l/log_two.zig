export fn log_two(v:[*]const i64,n:usize)i64{if(n!=1)return -1;var x=v[0];if(x<0 or x>2147483647)return -1;var r:i64=0;while((x>>1)!=0){x=x>>1;r+=1;}return r;}
