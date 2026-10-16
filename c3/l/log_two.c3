module log_two;
fn long log_two(long*v,usz n) @export("log_two"){if(v==null||n!=1||v[0]<0||v[0]>2147483647)return -1;long x=v[0];long r=0;while(x>>1){x=x>>1;r++;}return r;}
