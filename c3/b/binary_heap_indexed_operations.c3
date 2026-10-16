module binary_heap_indexed_operations;
const long I32_MIN = -2147483648;
const long I32_MAX = 2147483647;
fn void put_i64(char* out, usz slot, long value) { ulong bits = @bitcast(ulong, value); for (usz b=0;b<8;b++) { out[slot*8+b]=(char)(bits&255); bits>>=8; } }
fn void down(long* h, usz n, usz i) { while (true) { usz l=2*i+1,r=l+1,s=i; if(l<n&&h[l]<h[s])s=l; if(r<n&&h[r]<h[s])s=r; if(s==i)return; long t=h[i];h[i]=h[s];h[s]=t;i=s; } }
fn void up(long* h, usz i) { while(i>0) { usz p=(i-1)/2; if(h[p]<=h[i])return; long t=h[i];h[i]=h[p];h[p]=t;i=p; } }
fn long binary_heap_indexed_operations(long* v, usz n, char* out, usz cap) @export("binary_heap_indexed_operations") {
 if(v==null||n<2||v[0]<1||v[0]>256||v[1]<0||v[1]>512||n!=2+(usz)v[1]*3)return -1;
 long[256] h; usz size=0, outputs=0;
 for(usz i=0;i<(usz)v[1];i++){long op=v[2+3*i],a=v[3+3*i],b=v[4+3*i];
  if(op==0){if(a<I32_MIN||a>I32_MAX||b!=0)return -1;if(size<(usz)v[0]){h[size]=a;up(&h,size);size++;}}
  else if(op==1||op==2){if(a!=0||b!=0||(op==1&&size==0))return -1;if(out==null||(outputs+1)*8>cap)return -2;long result=if(size==0) I32_MAX else h[0];if(op==2&&size>0){size--;h[0]=h[size];if(size>0)down(&h,size,0);}put_i64(out,outputs++,result);}
  else if(op==3){if(a<0||(usz)a>=size||b<I32_MIN||b>I32_MAX||b>h[(usz)a])return -1;h[(usz)a]=b;up(&h,(usz)a);}
  else if(op==4){if(a<0||(usz)a>=size||b!=0)return -1;h[(usz)a]=I32_MIN;up(&h,(usz)a);size--;h[0]=h[size];if(size>0)down(&h,size,0);}
  else return -1;
 }
 usz bytes=outputs*8;if(bytes>cap||(bytes>0&&out==null))return -2;return (long)bytes;
}
