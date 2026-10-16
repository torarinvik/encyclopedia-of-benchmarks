module ibits;
fn long ibits(long*v,usz n) @export("ibits"){if(v==null||n!=1||v[0]<0||v[0]>=9007199254740992)return -1;long x=v[0],c=0;while(x!=0){c++;x>>=1;}return c;}
