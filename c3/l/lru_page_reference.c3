module lru_page_reference;
fn long lru_page_reference(long* input,usz length,char* output,usz capacity) @export("lru_page_reference") {
 if(input==null||length<2)return -1;long c64=input[0],n64=input[1];if(c64<1||c64>64||(c64&(c64-1))!=0||n64<0||n64>256||length!=(usz)n64+2)return -1;
 usz c=(usz)c64,n=(usz)n64;for(usz i=0;i<n;i++)if(input[2+i]<0||input[2+i]>1000000)return -1;
 long[64] cache;long[512] events;usz used=0;
 for(usz i=0;i<n;i++){long page=input[2+i],evicted=-1;usz p=0;while(p<used&&cache[p]!=page)p++;if(p<used){usz j=p;while(j>0){cache[j]=cache[j-1];j--;}cache[0]=page;events[2*i]=1;}else{if(used==c){evicted=cache[used-1];used--;}usz j=used;while(j>0){cache[j]=cache[j-1];j--;}cache[0]=page;used++;events[2*i]=0;}events[2*i+1]=evicted;}
 usz words=2*n+2+used;if(output==null||capacity<words*8)return -2;
 long[578] result;usz k=0;result[k++]=(long)n;for(usz i=0;i<2*n;i++)result[k++]=events[i];result[k++]=(long)used;for(usz i=0;i<used;i++)result[k++]=cache[i];
 for(usz i=0;i<k;i++){ulong bits=@bitcast(ulong,result[i]);for(usz b=0;b<8;b++){output[i*8+b]=(char)(bits&255);bits>>=8;}}return (long)(words*8);
}
