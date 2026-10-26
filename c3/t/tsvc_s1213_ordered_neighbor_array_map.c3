// Clean-room TSVC s1213 profile; see package rights note.
module tsvc_s1213_ordered_neighbor_array_map;
fn void put64(&usz o,usz p,long v){usz b=(usz)v;for(usz k=0;k<8;k++){o[k]=(u8)(b&255);b>>=8;}}
fn long tsvc_s1213_ordered_neighbor_array_map(&long in,usz len,&u8 out,usz cap){if(in==null||len<13||len>129)return -1;long nr=in[0];if(nr<3||nr>32)return -1;usz n=(usz)nr;if(len!=1+4*n)return -1;long a[32];long b[32];long cv[32];long d[32];for(usz i=0;i<n;i++){long x=in[1+i],y=in[1+n+i],z=in[1+2*n+i],w=in[1+3*n+i];if(x< -1||x>1||y< -1||y>1||z< -1||z>1||w< -1||w>1)return -1;a[i]=x;b[i]=y;cv[i]=z;d[i]=w;}if(out==null||cap<16*n)return -2;for(usz i=1;i<n-1;i++){a[i]=b[i-1]+cv[i];b[i]=a[i+1]*d[i];}for(usz i=0;i<n;i++){put64(out+8*i,a[i]);put64(out+8*(n+i),b[i]);}return (2*n).long();}
