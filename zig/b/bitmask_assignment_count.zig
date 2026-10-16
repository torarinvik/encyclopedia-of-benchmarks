const MAX_PEOPLE:usize=8;const MAX_TASKS:usize=12;const MAX_INPUT:usize=106;
export fn bitmask_assignment_count(input:[*c]const i64,length:usize)i64{
 if(input==null or length<2 or length>MAX_INPUT)return -1;const pv=input[0];const tv=input[1];if(pv<0 or pv>MAX_PEOPLE or tv<0 or tv>MAX_TASKS)return -1;const people:usize=@intCast(pv);const tasks:usize=@intCast(tv);var freq:[MAX_TASKS+1][MAX_PEOPLE]i64=@splat(@splat(0));var pos:usize=2;
 for(0..people)|p|{if(pos>=length)return -1;const count=input[pos];pos+=1;if(count<0 or count>@as(i64,@intCast(MAX_TASKS)) or pos+@as(usize,@intCast(count))>length)return -1;for(0..@as(usize,@intCast(count))) |_|{const task=input[pos];pos+=1;if(task<1 or task>@as(i64,@intCast(tasks)))return -1;freq[@intCast(task)][p]+=1;}}
 if(pos!=length)return -1;const states:usize=1<<@intCast(people);const full=states-1;var dp:[1<<MAX_PEOPLE][MAX_TASKS+2]i64=@splat(@splat(0));for(0..states)|mask|{if(mask==full)dp[mask][tasks+1]=1;}
 var task:usize=tasks;while(task>0){for(0..states)|mask|{var ways=dp[mask][task+1];var bit:usize=1;for(0..people)|p|{if(freq[task][p]>0 and (mask&bit)==0)ways+=freq[task][p]*dp[mask|bit][task+1];bit<<=1;}dp[mask][task]=ways;}task-=1;}
 return dp[0][1];
}
