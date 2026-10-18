#include <stddef.h>
#include <stdint.h>

#define MAX_CITIES 6u
#define MAX_INPUT 19u
#define MAX_ROUTE 7u
#define MAX_CANDIDATES 10u
#define MAX_OUTPUT 36u

static int64_t route_cost(const int32_t *route,size_t route_len,const int64_t edge[MAX_CITIES][MAX_CITIES])
{
    int64_t cost=0;
    for(size_t i=0;i+1<route_len;i++)cost+=edge[route[i]][route[i+1]];
    return cost;
}

static int same_route(const int32_t *a,const int32_t *b,size_t length)
{
    for(size_t i=0;i<length;i++)if(a[i]!=b[i])return 0;
    return 1;
}

static void write_i32(uint8_t *out,size_t *offset,int32_t value)
{
    uint32_t bits=(uint32_t)value;
    for(unsigned shift=0;shift<32;shift+=8)out[(*offset)++]=(uint8_t)(bits>>shift);
}

int64_t tabu_search(const int64_t *input,size_t input_length,uint8_t *output,size_t capacity)
{
    if(input==NULL||input_length<3||input_length>MAX_INPUT)return -1;
    int64_t city_value=input[0],iteration_value=input[1],tabu_value=input[2];
    if(city_value<4||city_value>6||iteration_value<0||iteration_value>8||tabu_value<1||tabu_value>3)return -1;
    size_t cities=(size_t)city_value,iterations=(size_t)iteration_value,tabu_size=(size_t)tabu_value;
    size_t edge_count=cities*(cities-1)/2;
    if(input_length!=3+edge_count)return -1;
    int64_t edge[MAX_CITIES][MAX_CITIES]={{0}};
    size_t offset=3;
    for(size_t left=0;left<cities;left++)for(size_t right=left+1;right<cities;right++){
        int64_t weight=input[offset++];if(weight<1||weight>99)return -1;
        edge[left][right]=edge[right][left]=weight;
    }

    int32_t solution[MAX_ROUTE],best_solution[MAX_ROUTE];
    size_t route_len=0;int32_t current=0;
    while(1){
        int visited=0;for(size_t i=0;i<route_len;i++)if(solution[i]==current){visited=1;break;}
        if(visited)break;
        int64_t minimum=10000;int32_t best_node=current;
        /* Edge insertion gives each city's neighbors in ascending city order. */
        for(size_t node=0;node<cities;node++)if(node!=(size_t)current){
            int already=0;for(size_t i=0;i<route_len;i++)if(solution[i]==(int32_t)node){already=1;break;}
            if(edge[current][node]<minimum&&!already){minimum=edge[current][node];best_node=(int32_t)node;}
        }
        solution[route_len++]=current;current=best_node;
    }
    solution[route_len++]=0;
    int64_t best_cost=route_cost(solution,route_len,edge);
    for(size_t i=0;i<route_len;i++)best_solution[i]=solution[i];
    int32_t tabu_new[3],tabu_old[3];size_t tabu_count=0;

    for(size_t iteration=0;iteration<iterations;iteration++){
        int32_t candidates[MAX_CANDIDATES][MAX_ROUTE];
        int64_t costs[MAX_CANDIDATES];size_t candidate_count=0;
        for(size_t first=1;first+1<route_len;first++)for(size_t second=1;second+1<route_len;second++){
            if(first==second)continue;
            int32_t candidate[MAX_ROUTE];for(size_t i=0;i<route_len;i++)candidate[i]=solution[i];
            int32_t temp=candidate[first];candidate[first]=candidate[second];candidate[second]=temp;
            int duplicate=0;for(size_t i=0;i<candidate_count;i++)if(same_route(candidate,candidates[i],route_len)){duplicate=1;break;}
            if(!duplicate){
                for(size_t i=0;i<route_len;i++)candidates[candidate_count][i]=candidate[i];
                costs[candidate_count]=route_cost(candidate,route_len,edge);candidate_count++;
            }
        }
        /* Stable insertion sort: equal-cost candidates keep first-seen order. */
        for(size_t i=1;i<candidate_count;i++){
            int32_t route[MAX_ROUTE];for(size_t j=0;j<route_len;j++)route[j]=candidates[i][j];
            int64_t cost=costs[i];size_t j=i;
            while(j>0&&cost<costs[j-1]){
                for(size_t k=0;k<route_len;k++)candidates[j][k]=candidates[j-1][k];
                costs[j]=costs[j-1];j--;
            }
            for(size_t k=0;k<route_len;k++)candidates[j][k]=route[k];costs[j]=cost;
        }
        size_t selected=0;int32_t move_new=0,move_old=0;
        for(;;selected++){
            size_t difference=0;while(difference<route_len&&candidates[selected][difference]==solution[difference])difference++;
            move_new=candidates[selected][difference];move_old=solution[difference];
            int forbidden=0;
            for(size_t i=0;i<tabu_count;i++)if((tabu_new[i]==move_new&&tabu_old[i]==move_old)||(tabu_new[i]==move_old&&tabu_old[i]==move_new)){forbidden=1;break;}
            if(!forbidden)break;
        }
        tabu_new[tabu_count]=move_new;tabu_old[tabu_count]=move_old;tabu_count++;
        for(size_t i=0;i<route_len;i++)solution[i]=candidates[selected][i];
        int64_t cost=costs[selected];
        if(cost<best_cost){best_cost=cost;for(size_t i=0;i<route_len;i++)best_solution[i]=solution[i];}
        if(tabu_count>=tabu_size){for(size_t i=1;i<tabu_count;i++){tabu_new[i-1]=tabu_new[i];tabu_old[i-1]=tabu_old[i];}tabu_count--;}
    }
    uint8_t staged[MAX_OUTPUT];size_t written=0;
    write_i32(staged,&written,(int32_t)route_len);
    for(size_t i=0;i<route_len;i++)write_i32(staged,&written,best_solution[i]);
    write_i32(staged,&written,(int32_t)best_cost);
    if(output==NULL||capacity<written)return -2;
    for(size_t i=0;i<written;i++)output[i]=staged[i];
    return (int64_t)written;
}
