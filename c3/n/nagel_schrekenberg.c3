module nagel_schrekenberg;
fn long nagel_schrekenberg(long*v,usz n,char*out,usz cap) @export("nagel_schrekenberg") {
 if(v==null||n<5||v[0]<2||v[0]>32||v[1]<0||v[1]>16||v[2]<0||v[2]>5||n!=(usz)v[0]+3)return -1;usz cells=(usz)v[0],steps=(usz)v[1];long[32] row;long[32] next;long[32] moved;for(usz i=0;i<cells;i++){if(v[i+3]< -1||v[i+3]>5)return -1;row[i]=v[i+3];}usz need=cells*(steps+1);if(need>cap||(need>0&&out==null))return -2;usz p=0;for(usz j=0;j<cells;j++){out[p]=(char)(row[j]+1);p++;}
 for(usz t=0;t<steps;t++){for(usz i=0;i<cells;i++){next[i]=-1;if(row[i]!=-1){usz d=0,j=i+1;while(j<cells&&row[j]==-1){d++;j++;}if(j==cells){j=0;while(row[j]==-1){d++;j++;}}long speed=row[i]+1;if(speed>v[2])speed=v[2];if(speed>(long)d-1)speed=(long)d-1;next[i]=speed;}}for(usz j=0;j<cells;j++)moved[j]=-1;for(usz i=0;i<cells;i++)if(next[i]!=-1)moved[(i+(usz)next[i])%cells]=next[i];for(usz j=0;j<cells;j++){row[j]=moved[j];out[p]=(char)(row[j]+1);p++;}}
 return (long)p;
}
