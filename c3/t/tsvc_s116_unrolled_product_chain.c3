// Clean-room TSVC s116 profile; see package rights note.
module tsvc_s116_unrolled_product_chain;
fn void put64(&usz o,usz p,long v){usz b=(usz)v;for(usz j=0;j<8;j++){o[j]=(u8)(b&255);b>>=8;}}
fn long tsvc_s116_unrolled_product_chain(&long in,usz len,&u8 out,usz cap){if(in==null||len<8||len>23)return -1;long nr=in[0],passes=in[1];if(nr<6||nr>21||(nr-1)%5!=0||passes<1||passes>4)return -1;usz n=(usz)nr;if(len!=2+n)return -1;long a[21];for(usz k=0;k<n;k++){long x=in[2+k];if(x != -1&&x != 1)return -1;a[k]=x;}if(out==null||cap<8*n)return -2;for(usz p=0;p<(usz)passes;p++){usz i=0;while(i<n-5){a[i]=a[i+1]*a[i];a[i+1]=a[i+2]*a[i+1];a[i+2]=a[i+3]*a[i+2];a[i+3]=a[i+4]*a[i+3];a[i+4]=a[i+5]*a[i+4];i+=5;}}for(usz k=0;k<n;k++)put64(out+8*k,a[k]);return n.long();}
