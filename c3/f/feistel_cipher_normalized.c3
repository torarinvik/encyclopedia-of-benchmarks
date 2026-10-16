module feistel_cipher_normalized;
fn uint round_key(uint key,uint round){uint p=1;for(uint i=0;i<round+2;i++)p*=key;return p^key;}
fn bool valid_key(uint key){for(uint i=0;i<32;i++)if(round_key(key,i)==0)return false;return true;}
fn uint f(uint x,uint key){for(int i=0;i<32;i++){x=((x^0x55555555)*x)%key;x^=key;}return x;}
fn long feistel_cipher_normalized(long* a,usz n) @export("feistel_cipher_normalized"){if(a==null||n!=3||a[0]<0||a[0]>1||a[1]<1||a[1]>4294967295)return -1;ulong b=(ulong)a[2];uint l=(uint)(b>>32);uint r=(uint)b;uint key=(uint)a[1];if(!valid_key(key))return -1;if(a[0]==0){for(uint i=0;i<32;i++){uint t=r^f(l,round_key(key,i));r=l;l=t;}}else{for(int i=31;i>=0;i--){uint t=l^f(r,round_key(key,(uint)i));l=r;r=t;}}return (long)((ulong)l<<32|(ulong)r);}
