module bitmask_assignment_count;
const usz MAX_PEOPLE=8; const usz MAX_TASKS=12; const usz STATES=1<<MAX_PEOPLE;
fn long bitmask_assignment_count(long* input,usz length) @export("bitmask_assignment_count") {
 if(input==null||length<2||length>106||input[0]<0||input[0]>(long)MAX_PEOPLE||input[1]<0||input[1]>(long)MAX_TASKS)return -1;usz people=(usz)input[0],tasks=(usz)input[1],pos=2;int[MAX_TASKS+1][MAX_PEOPLE] freq=zeroed;
 for(usz p=0;p<people;p++){if(pos>=length)return -1;long count=input[pos++];if(count<0||count>(long)MAX_TASKS||pos+(usz)count>length)return -1;for(long j=0;j<count;j++){long task=input[pos++];if(task<1||task>(long)tasks)return -1;freq[(usz)task][p]++;}}if(pos!=length)return -1;
 usz states=1<<people,full=states-1;long[STATES][MAX_TASKS+2] dp=zeroed;for(usz mask=0;mask<states;mask++)dp[mask][tasks+1]=mask==full?1:0;
 for(long t=(long)tasks;t>=1;t--)for(usz mask=0;mask<states;mask++){long ways=dp[mask][(usz)t+1];for(usz p=0;p<people;p++)if(freq[(usz)t][p]>0&&(mask&(1<<p))==0)ways+=(long)freq[(usz)t][p]*dp[mask|(1<<p)][(usz)t+1];dp[mask][(usz)t]=ways;}return dp[0][1];
}
