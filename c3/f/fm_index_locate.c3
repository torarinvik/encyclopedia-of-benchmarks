module fm_index_locate;
const usz MAX_TEXT=32,MAX_PATTERN=8,MAX_INPUT=43,ALPHABET=5;
fn bool suffix_less(long* s,usz n,usz a,usz b){while(a<n&&b<n){if(s[a]!=s[b])return s[a]<s[b];a+=1;b+=1;}return a==n&&b!=n;}
fn void store_i64_le(char* out,usz off,long v){ulong bits=(ulong)v;for(usz b=0;b<8;b+=1){out[off+b]=(char)(bits&255);bits>>=8;}}
long fm_index_locate(long* input,usz length,char* output,usz capacity) @export("fm_index_locate") {
 if(input==null||length<5||length>MAX_INPUT)return -1;long n64=input[0];if(n64<1||n64>(long)MAX_TEXT||length<(usz)n64+4)return -1;usz n=(usz)n64,m_at=n+1;long m64=input[m_at];if(m64<1||m64>(long)MAX_PATTERN||length!=m_at+1+(usz)m64+1)return -1;usz m=(usz)m64;long stride64=input[length-1];if(stride64<1||stride64>n64)return -1;usz stride=(usz)stride64,N=n+1;
 long[MAX_TEXT+1] s=zeroed;long[MAX_PATTERN] pat=zeroed;for(usz i=0;i<n;i+=1){long x=input[1+i];if(x<1||x>4)return -1;s[i]=x;}for(usz i=0;i<m;i+=1){long x=input[m_at+1+i];if(x<1||x>4)return -1;pat[i]=x;}s[n]=0;
 usz[MAX_TEXT+1] sa=zeroed;for(usz i=0;i<N;i+=1)sa[i]=i;for(usz i=1;i<N;i+=1){usz key=sa[i],j=i;while(j>0&&suffix_less(&s[0],N,key,sa[j-1])){sa[j]=sa[j-1];j-=1;}sa[j]=key;}
 long[MAX_TEXT+1] bwt=zeroed;usz[ALPHABET] freq=zeroed;for(usz i=0;i<N;i+=1){bwt[i]=s[(sa[i]+N-1)%N];freq[(usz)bwt[i]]+=1;}usz[ALPHABET] C=zeroed;usz sum=0;for(usz c=0;c<ALPHABET;c+=1){C[c]=sum;sum+=freq[c];}
 usz left=0,right=N;for(usz j=m;j>0;j-=1){usz c=(usz)pat[j-1],rl=0,rr=0;for(usz x=0;x<left;x+=1)if((usz)bwt[x]==c)rl+=1;for(usz x=0;x<right;x+=1)if((usz)bwt[x]==c)rr+=1;left=C[c]+rl;right=C[c]+rr;if(left==right)break;}
 usz[MAX_TEXT+1] LF=zeroed,samples=zeroed;bool[MAX_TEXT+1] sampled=zeroed;for(usz row=0;row<N;row+=1){usz c=(usz)bwt[row],rank=0;for(usz x=0;x<row;x+=1)if((usz)bwt[x]==c)rank+=1;LF[row]=C[c]+rank;sampled[row]=sa[row]%stride==0;samples[row]=sa[row];}
 long[MAX_TEXT] loc=zeroed;usz count=0;for(usz origin=left;origin<right;origin+=1){usz row=origin,steps=0;while(!sampled[row]&&steps<N){row=LF[row];steps+=1;}if(!sampled[row])return -1;usz pos=(samples[row]+steps)%N;if(pos>=n)return -1;loc[count]=(long)pos;count+=1;}
 usz bytes=8*(count+1);if(output==null||capacity<bytes)return -2;store_i64_le(output,0,(long)count);for(usz i=0;i<count;i+=1)store_i64_le(output,8*(i+1),loc[i]);return (long)bytes;
}
