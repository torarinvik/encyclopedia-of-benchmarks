module geohash;
const char[32] ALPHABET = "0123456789bcdefghjkmnpqrstuvwxyz";
fn long geohash(long* v,usz n,uint8* out,usz cap) @export("geohash") {
 if(v==null||n!=2||v[0]<-90000000||v[0]>90000000||v[1]<-180000000||v[1]>180000000)return -1;
 double lat=(double)v[0]/1000000.0;double lon=(double)v[1]/1000000.0;double latlo=-90.0;double lathi=90.0;double lonlo=-180.0;double lonhi=180.0;
 uint8[12] b;int bit=0;int value=0;bool islon=true;usz p=0;
 while(p<12){double mid;if(islon){mid=(lonlo+lonhi)/2.0;if(lon>mid){value|=1<<(4-bit);lonlo=mid;}else{lonhi=mid;}}else{mid=(latlo+lathi)/2.0;if(lat>mid){value|=1<<(4-bit);latlo=mid;}else{lathi=mid;}}islon=!islon;if(bit<4){bit++;}else{b[p]=(uint8)ALPHABET[value];p++;bit=0;value=0;}}
 if(out==null||cap<12)return -2;for(usz i=0;i<12;i++)out[i]=b[i];return 12;
}
