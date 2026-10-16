module magicdiamondpattern;
fn long magicdiamondpattern(long n, char* out, usz cap) @export("magicdiamondpattern") {
 if(n>45)return -1;
 if(n<=0){char[] msg="       ...       ....        nothing printing :(";usz z=msg.len;if(out==null||cap<z)return -2;for(usz i=0;i<z;i++)out[i]=msg[i];return (long)z;}
 usz s=(usz)n,need=3*s*s+4*s;if(out==null||cap<need)return -2;usz p=0;
 for(usz i=0;i<s;i++){for(usz j=0;j<s-i-1;j++)out[p++]=' ';for(usz j=0;j<i+1;j++){out[p++]='*';out[p++]=' ';}out[p++]='\n';}
 for(usz i=s;i>0;i--){for(usz j=0;j<i;j++){out[p++]='*';out[p++]=' ';}out[p++]='\n';for(usz j=0;j<s-i+1;j++)out[p++]=' ';}
 return (long)p;
}
