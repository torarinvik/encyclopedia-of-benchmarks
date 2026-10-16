#include <stddef.h>
#include <stdint.h>
#define MAX_PEOPLE 8
#define MAX_TASKS 12
int64_t bitmask_assignment_count(const int64_t *input,size_t length){
 if(!input||length<2||length>106)return -1;int64_t pv=input[0],tv=input[1];if(pv<0||pv>MAX_PEOPLE||tv<0||tv>MAX_TASKS)return -1;int people=(int)pv,tasks=(int)tv;int frequency[MAX_TASKS+1][MAX_PEOPLE]={0};size_t pos=2;
 for(int p=0;p<people;p++){if(pos>=length)return -1;int64_t count=input[pos++];if(count<0||count>MAX_TASKS||pos+(size_t)count>length)return -1;for(int j=0;j<count;j++){int64_t task=input[pos++];if(task<1||task>tasks)return -1;frequency[task][p]++;}}
 if(pos!=length)return -1;int states=1<<people,full=states-1;int64_t dp[1<<MAX_PEOPLE][MAX_TASKS+2]={0};for(int mask=0;mask<states;mask++)dp[mask][tasks+1]=(mask==full)?1:0;
 for(int task=tasks;task>=1;task--)for(int mask=0;mask<states;mask++){int64_t ways=dp[mask][task+1];for(int p=0;p<people;p++)if(frequency[task][p]&&!(mask&(1<<p)))ways+=(int64_t)frequency[task][p]*dp[mask|(1<<p)][task+1];dp[mask][task]=ways;}
 return dp[0][1];
}
