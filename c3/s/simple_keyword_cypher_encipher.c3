module simple_keyword_cypher_encipher;
fn long simple_keyword_cypher_encipher(long* v, usz n, char* output, usz capacity) @export("simple_keyword_cypher_encipher") {
 if(v==null||n<2||n>323)return -1;long kl=v[0],ml=v[1];if(kl<0||kl>64||ml<0||ml>256||n!=2+(usz)kl+(usz)ml)return -1;
 char[26] key;char[26] map;char[256] result;usz count=0;
 for(usz i=0;i<(usz)kl;i++){long x=v[2+i];if(!((x>=65&&x<=90)||(x>=97&&x<=122)))return -1;if(x>=97)x-=32;usz j=0;while(j<count&&key[j]!=(char)x)j++;if(j==count){key[count]=(char)x;count++;}}
 usz k=0;for(usz i=0;i<count;i++){map[k]=key[i];k++;}for(long x=65;x<=90;x++){usz j=0;while(j<count&&key[j]!=(char)x)j++;if(j==count){map[k]=(char)x;k++;}}
 for(usz i=0;i<(usz)ml;i++){long x=v[2+(usz)kl+i];if(x<0||x>127)return -1;if(x>=97&&x<=122)x-=32;if(x>=65&&x<=90){result[i] = map[(usz)(x - 65)];}else result[i]=(char)x;}
 if(output==null||capacity<(usz)ml)return -2;for(usz i=0;i<(usz)ml;i++)output[i]=result[i];return ml;
}
