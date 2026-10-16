export fn ibits(v:[*]const i64,n:usize)i64{if(n!=1)return -1;var x=v[0];if(x<0 or x>=9007199254740992)return -1;var c:i64=0;while(x!=0){c+=1;x>>=1;}return c;}
