module gcounter;
fn ulong gcounter_hash(ulong h, long value) { ulong bits=(ulong)value; for(int i=0;i<8;i++) h=(h^((bits>>(8*i))&255))*0x100000001b3; return h; }
fn long gcounter(long* a, usz n) @export("gcounter") {
 if(a==null||n<2||n>386||a[0]<1||a[0]>8||a[1]<0||a[1]>128||n!=2+3*(usz)a[1])return -1;
 long[8][8] s; for(int i=0;i<8;i++)for(int j=0;j<8;j++)s[i][j]=0;
 int nodes=(int)a[0];ulong h=0xcbf29ce484222325;
 for(int i=0;i<(int)a[1];i++){long op=a[2+3*i];long aa=a[3+3*i];long bb=a[4+3*i];if(aa<0||aa>=nodes)return -1;
 if(op==0){if(bb!=0||s[aa][aa]>=1000000)return -1;s[aa][aa]++;}
 else if(op==1){if(bb!=0)return -1;long total=0;for(int j=0;j<nodes;j++)total+=s[aa][j];h=gcounter_hash(h,total);}
 else if(op==2){if(bb<0||bb>=nodes)return -1;bool yes=true;for(int j=0;j<nodes;j++)if(s[aa][j]>s[bb][j])yes=false;h=gcounter_hash(h,yes?1:0);}
 else if(op==3){if(bb<0||bb>=nodes)return -1;for(int j=0;j<nodes;j++)if(s[bb][j]>s[aa][j])s[aa][j]=s[bb][j];}
 else { return -1; }
 }
 for(int i=0;i<nodes;i++)for(int j=0;j<nodes;j++)h=gcounter_hash(h,s[i][j]);return (long)h;
}
