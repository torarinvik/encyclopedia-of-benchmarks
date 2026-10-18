module tabu_search;

const usz MAX_CITIES=6;
const usz MAX_ROUTE=7;
const usz MAX_CANDIDATES=10;
const usz MAX_OUTPUT=36;

fn long route_cost(int* route, usz length, long* edge) {
    long cost=0;
    for(usz i=0;i+1<length;i++) cost+=edge[route[i]*MAX_CITIES+route[i+1]];
    return cost;
}
fn bool same_route(int* a,int* b,usz length) {
    for(usz i=0;i<length;i++) if(a[i]!=b[i]) return false;
    return true;
}
fn void write_i32(uint8* out,usz* offset,int value) {
    uint bits=(uint)value;
    for(usz shift=0;shift<32;shift+=8) out[(*offset)++]=(uint8)(bits>>shift);
}

fn long tabu_search(long* input,usz input_length,uint8* output,usz capacity) @export("tabu_search") {
    if(input==null || input_length<3 || input_length>19) return -1L;
    long city_value=input[0], iteration_value=input[1], tabu_value=input[2];
    if(city_value<4 || city_value>6 || iteration_value<0 || iteration_value>8 || tabu_value<1 || tabu_value>3) return -1L;
    usz cities=(usz)city_value, iterations=(usz)iteration_value, tabu_size=(usz)tabu_value;
    if(input_length!=3+cities*(cities-1)/2) return -1L;
    long[36] edge=zeroed; usz offset=3;
    for(usz left=0;left<cities;left++) for(usz right=left+1;right<cities;right++) {
        long weight=input[offset++]; if(weight<1 || weight>99) return -1L;
        edge[left*MAX_CITIES+right]=weight; edge[right*MAX_CITIES+left]=weight;
    }
    int[MAX_ROUTE] solution=zeroed, best_solution=zeroed;
    usz route_len=0; int current=0;
    while(true) {
        bool visited=false;
        for(usz i=0;i<route_len;i++) if(solution[i]==current) { visited=true; break; }
        if(visited) break;
        long minimum=10000; int best_node=current;
        // Each city's insertion order is ascending city label.
        for(usz node=0;node<cities;node++) if(node!=(usz)current) {
            bool already=false;
            for(usz i=0;i<route_len;i++) if(solution[i]==(int)node) { already=true; break; }
            if(edge[(usz)current*MAX_CITIES+node]<minimum && !already) {
                minimum=edge[(usz)current*MAX_CITIES+node]; best_node=(int)node;
            }
        }
        solution[route_len++]=current; current=best_node;
    }
    solution[route_len++]=0;
    long best_cost=route_cost(&solution[0],route_len,&edge[0]);
    for(usz i=0;i<route_len;i++) best_solution[i]=solution[i];
    int[3] tabu_new=zeroed, tabu_old=zeroed; usz tabu_count=0;

    for(usz iteration=0;iteration<iterations;iteration++) {
        int[MAX_CANDIDATES*MAX_ROUTE] candidates=zeroed;
        long[MAX_CANDIDATES] costs=zeroed; usz candidate_count=0;
        for(usz first=1;first+1<route_len;first++) for(usz second=1;second+1<route_len;second++) {
            if(first==second) continue;
            int[MAX_ROUTE] candidate=zeroed;
            for(usz i=0;i<route_len;i++) candidate[i]=solution[i];
            int temp=candidate[first]; candidate[first]=candidate[second]; candidate[second]=temp;
            bool duplicate=false;
            for(usz old=0;old<candidate_count;old++)
                if(same_route(&candidate[0],&candidates[old*MAX_ROUTE],route_len)) { duplicate=true; break; }
            if(!duplicate) {
                for(usz i=0;i<route_len;i++) candidates[candidate_count*MAX_ROUTE+i]=candidate[i];
                costs[candidate_count]=route_cost(&candidate[0],route_len,&edge[0]);
                candidate_count++;
            }
        }
        // Stable insertion sort retains the first-seen order for ties.
        for(usz i=1;i<candidate_count;i++) {
            int[MAX_ROUTE] route=zeroed;
            for(usz j=0;j<route_len;j++) route[j]=candidates[i*MAX_ROUTE+j];
            long cost=costs[i]; usz j=i;
            while(j>0 && cost<costs[j-1]) {
                for(usz k=0;k<route_len;k++) candidates[j*MAX_ROUTE+k]=candidates[(j-1)*MAX_ROUTE+k];
                costs[j]=costs[j-1]; j--;
            }
            for(usz k=0;k<route_len;k++) candidates[j*MAX_ROUTE+k]=route[k];
            costs[j]=cost;
        }
        usz selected=0; int move_new=0,move_old=0;
        while(true) {
            usz difference=0;
            while(difference<route_len && candidates[selected*MAX_ROUTE+difference]==solution[difference]) difference++;
            move_new=candidates[selected*MAX_ROUTE+difference]; move_old=solution[difference];
            bool forbidden=false;
            for(usz i=0;i<tabu_count;i++) if((tabu_new[i]==move_new && tabu_old[i]==move_old) || (tabu_new[i]==move_old && tabu_old[i]==move_new)) { forbidden=true; break; }
            if(!forbidden) break;
            selected++;
        }
        tabu_new[tabu_count]=move_new; tabu_old[tabu_count]=move_old; tabu_count++;
        for(usz i=0;i<route_len;i++) solution[i]=candidates[selected*MAX_ROUTE+i];
        long cost=costs[selected];
        if(cost<best_cost) { best_cost=cost; for(usz i=0;i<route_len;i++) best_solution[i]=solution[i]; }
        if(tabu_count>=tabu_size) {
            for(usz i=1;i<tabu_count;i++) { tabu_new[i-1]=tabu_new[i]; tabu_old[i-1]=tabu_old[i]; }
            tabu_count--;
        }
    }
    uint8[MAX_OUTPUT] staged=zeroed; usz written=0;
    write_i32(&staged[0],&written,(int)route_len);
    for(usz i=0;i<route_len;i++) write_i32(&staged[0],&written,best_solution[i]);
    write_i32(&staged[0],&written,(int)best_cost);
    if(output==null || capacity<written) return -2L;
    for(usz i=0;i<written;i++) output[i]=staged[i];
    return (long)written;
}
