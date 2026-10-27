module min_hash_bottom_k;
const usz MAX_INPUT=35;
fn void put64(char*o,usz p,long x){ulong b=(ulong)x;for(usz j=0;j<8;j+=1){o[p+j]=(char)(b&255);b>>=8;}}
long min_hash_bottom_k(long*in,usz len,char*out,usz cap) @export("min_hash_bottom_k"){
 if(in==null||len<4||len>MAX_INPUT)return -1;long nr=in[0],kr=in[1];if(nr<1||nr>16||kr<1||kr>8||len!=2+2*(usz)nr)return -1;usz n=(usz)nr,k=(usz)kr;usz ids[16];long ranks[16];usz count=0;
 for(usz i=0;i<n;i+=1){long id=in[2+2*i],rank=in[3+2*i];if(id<0||id>=16||rank<0||rank>1000)return -1;for(usz j=0;j<i;j+=1)if(id==(long)ids[j])return -1;usz pos=0;while(pos<count&&(ranks[pos]<rank||(ranks[pos]==rank&&ids[pos]< (usz)id)))pos+=1;if(pos<k){usz next=count<k?count:k-1;while(next>pos){ids[next]=ids[next-1];ranks[next]=ranks[next-1];next-=1;}ids[pos]=(usz)id;ranks[pos]=rank;if(count<k)count+=1;}}
 usz bytes=8*(1+2*count);if(out==null||cap<bytes)return -2;put64(out,0,(long)count);for(usz i=0;i<count;i+=1){put64(out,8+16*i,(long)ids[i]);put64(out,16+16*i,ranks[i]);}return (long)bytes;
}
