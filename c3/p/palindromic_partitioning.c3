module palindromic_partitioning;
fn long palindromic_partitioning(long* v,usz n) @export("palindromic_partitioning"){
 if(v==null||n<2||n>65||v[0]<1||v[0]>64||n!=(usz)v[0]+1)return -1;usz m=(usz)v[0];bool[64][64] p;long[64] cuts;
 for(usz end=0;end<m;end++){long x=v[end+1];if(x<0||x>127)return -1;for(usz start=0;start<=end;start++)p[start][end]=v[start+1]==x&&(end-start<2||p[start+1][end-1]);}
 for(usz end=0;end<m;end++){if(p[0][end])cuts[end]=0;else{cuts[end]=64;for(usz start=1;start<=end;start++)if(p[start][end]&&cuts[start-1]+1<cuts[end])cuts[end]=cuts[start-1]+1;}}
 return cuts[m-1];
}
