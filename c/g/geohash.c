#include <stddef.h>
#include <stdint.h>
static const char alphabet[]="0123456789bcdefghjkmnpqrstuvwxyz";
int64_t geohash(const int64_t *v,size_t n,uint8_t *out,size_t cap){
 if(!v||n!=2||v[0]<-90000000||v[0]>90000000||v[1]<-180000000||v[1]>180000000)return -1;
 double lat=(double)v[0]/1000000.0,lon=(double)v[1]/1000000.0,lat_lo=-90,lat_hi=90,lon_lo=-180,lon_hi=180;
 uint8_t b[12];int bit=0,value=0;int lon_turn=1;size_t p=0;
 while(p<12){double mid;if(lon_turn){mid=(lon_lo+lon_hi)/2;if(lon>mid){value|=1<<(4-bit);lon_lo=mid;}else lon_hi=mid;}else{mid=(lat_lo+lat_hi)/2;if(lat>mid){value|=1<<(4-bit);lat_lo=mid;}else lat_hi=mid;}lon_turn=!lon_turn;if(bit<4)bit++;else{b[p++]=(uint8_t)alphabet[value];bit=0;value=0;}}
 if(!out||cap<12)return -2;for(size_t i=0;i<12;i++)out[i]=b[i];return 12;
}
