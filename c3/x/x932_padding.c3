module x932_padding;
fn long x932_padding(long* values, usz length, char* output, usz capacity) @export("x932_padding") {
 if(values==null||length<1||length>257)return -1; if(values[0]<1||values[0]>64)return -1; usz block=(usz)values[0], n=length-1; for(usz i=1;i<length;i++)if(values[i]<0||values[i]>255)return -1; usz pad=block-(n%block), total=n+pad; if(total>capacity||output==null)return -2; for(usz i=0;i<n;i++)output[i]=(char)values[i+1]; for(usz i=n;i<total-1;i++)output[i]=0; output[total-1]=(char)pad; return (long)total;
}
