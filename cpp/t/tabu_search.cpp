#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_cities=6,max_route=7,max_candidates=10,max_output=36;
std::int64_t route_cost(const std::int32_t* route,std::size_t length,const std::int64_t edge[6][6]) noexcept {
    std::int64_t cost=0;for(std::size_t i=0;i+1<length;i++)cost+=edge[route[i]][route[i+1]];return cost;
}
bool same_route(const std::int32_t* a,const std::int32_t* b,std::size_t length) noexcept {
    for(std::size_t i=0;i<length;i++)if(a[i]!=b[i])return false;return true;
}
void write_i32(std::uint8_t* out,std::size_t& offset,std::int32_t value) noexcept {
    const auto bits=static_cast<std::uint32_t>(value);for(unsigned shift=0;shift<32;shift+=8)out[offset++]=static_cast<std::uint8_t>(bits>>shift);
}
}

extern "C" std::int64_t tabu_search(const std::int64_t* input,std::size_t input_length,
    std::uint8_t* output,std::size_t capacity) noexcept {
    if(input==nullptr||input_length<3||input_length>19)return -1;
    const auto city_value=input[0],iteration_value=input[1],tabu_value=input[2];
    if(city_value<4||city_value>6||iteration_value<0||iteration_value>8||tabu_value<1||tabu_value>3)return -1;
    const auto cities=static_cast<std::size_t>(city_value),iterations=static_cast<std::size_t>(iteration_value),tabu_size=static_cast<std::size_t>(tabu_value);
    if(input_length!=3+cities*(cities-1)/2)return -1;
    std::int64_t edge[max_cities][max_cities]{};std::size_t offset=3;
    for(std::size_t left=0;left<cities;left++)for(std::size_t right=left+1;right<cities;right++){
        const auto weight=input[offset++];if(weight<1||weight>99)return -1;edge[left][right]=edge[right][left]=weight;
    }
    std::int32_t solution[max_route]{},best_solution[max_route]{};std::size_t route_len=0;std::int32_t current=0;
    for(;;){
        bool visited=false;for(std::size_t i=0;i<route_len;i++)if(solution[i]==current){visited=true;break;}if(visited)break;
        std::int64_t minimum=10000;std::int32_t best_node=current;
        // Per-city adjacency insertion order is ascending city index.
        for(std::size_t node=0;node<cities;node++)if(node!=static_cast<std::size_t>(current)){
            bool already=false;for(std::size_t i=0;i<route_len;i++)if(solution[i]==static_cast<std::int32_t>(node)){already=true;break;}
            if(edge[current][node]<minimum&&!already){minimum=edge[current][node];best_node=static_cast<std::int32_t>(node);}
        }
        solution[route_len++]=current;current=best_node;
    }
    solution[route_len++]=0;std::int64_t best_cost=route_cost(solution,route_len,edge);
    for(std::size_t i=0;i<route_len;i++)best_solution[i]=solution[i];
    std::int32_t tabu_new[3]{},tabu_old[3]{};std::size_t tabu_count=0;
    for(std::size_t iteration=0;iteration<iterations;iteration++){
        std::int32_t candidates[max_candidates][max_route]{};std::int64_t costs[max_candidates]{};std::size_t candidate_count=0;
        for(std::size_t first=1;first+1<route_len;first++)for(std::size_t second=1;second+1<route_len;second++){
            if(first==second)continue;
            std::int32_t candidate[max_route];for(std::size_t i=0;i<route_len;i++)candidate[i]=solution[i];
            const auto temp=candidate[first];candidate[first]=candidate[second];candidate[second]=temp;
            bool duplicate=false;for(std::size_t i=0;i<candidate_count;i++)if(same_route(candidate,candidates[i],route_len)){duplicate=true;break;}
            if(!duplicate){for(std::size_t i=0;i<route_len;i++)candidates[candidate_count][i]=candidate[i];costs[candidate_count]=route_cost(candidate,route_len,edge);candidate_count++;}
        }
        for(std::size_t i=1;i<candidate_count;i++){
            std::int32_t route[max_route];for(std::size_t j=0;j<route_len;j++)route[j]=candidates[i][j];
            const auto cost=costs[i];std::size_t j=i;
            while(j>0&&cost<costs[j-1]){for(std::size_t k=0;k<route_len;k++)candidates[j][k]=candidates[j-1][k];costs[j]=costs[j-1];j--;}
            for(std::size_t k=0;k<route_len;k++)candidates[j][k]=route[k];costs[j]=cost;
        }
        std::size_t selected=0;std::int32_t move_new=0,move_old=0;
        for(;;selected++){
            std::size_t difference=0;while(difference<route_len&&candidates[selected][difference]==solution[difference])difference++;
            move_new=candidates[selected][difference];move_old=solution[difference];bool forbidden=false;
            for(std::size_t i=0;i<tabu_count;i++)if((tabu_new[i]==move_new&&tabu_old[i]==move_old)||(tabu_new[i]==move_old&&tabu_old[i]==move_new)){forbidden=true;break;}
            if(!forbidden)break;
        }
        tabu_new[tabu_count]=move_new;tabu_old[tabu_count]=move_old;tabu_count++;
        for(std::size_t i=0;i<route_len;i++)solution[i]=candidates[selected][i];
        const auto cost=costs[selected];if(cost<best_cost){best_cost=cost;for(std::size_t i=0;i<route_len;i++)best_solution[i]=solution[i];}
        if(tabu_count>=tabu_size){for(std::size_t i=1;i<tabu_count;i++){tabu_new[i-1]=tabu_new[i];tabu_old[i-1]=tabu_old[i];}tabu_count--;}
    }
    std::uint8_t staged[max_output];std::size_t written=0;
    write_i32(staged,written,static_cast<std::int32_t>(route_len));
    for(std::size_t i=0;i<route_len;i++)write_i32(staged,written,best_solution[i]);
    write_i32(staged,written,static_cast<std::int32_t>(best_cost));
    if(output==nullptr||capacity<written)return -2;
    for(std::size_t i=0;i<written;i++)output[i]=staged[i];
    return static_cast<std::int64_t>(written);
}
