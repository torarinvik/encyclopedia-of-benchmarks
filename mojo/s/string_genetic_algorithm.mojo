from std.ffi import c_size_t
from std.memory import Pointer
from std.origin import ImmUntrackedOrigin, MutUntrackedOrigin

comptime POPULATION_SIZE = 200
comptime ELITE_SIZE = 66
comptime SELECTED_SIZE = 50
comptime MODULUS = UInt64(2147483647)


def next_random(mut state: UInt64) -> UInt64:
    state = (state * 48271) % MODULUS
    return state


def write_result(output: Pointer[UInt8, MutUntrackedOrigin], generation: Int) -> Int64:
    for byte in range(8):
        output[unsafe_offset=byte] = UInt8((UInt64(generation) >> UInt64(8 * byte)) & 255)
        output[unsafe_offset=8 + byte] = UInt8((UInt64(generation * POPULATION_SIZE) >> UInt64(8 * byte)) & 255)
    return 16


@export("string_genetic_algorithm")
def string_genetic_algorithm(
    input: Optional[Pointer[Int64, ImmUntrackedOrigin]],
    length: c_size_t,
    result: Optional[Pointer[UInt8, MutUntrackedOrigin]],
    capacity: c_size_t,
) abi("C") -> Int64:
    if input == None or length < 6 or length > 44:
        return -2
    var values = input.value()
    var target_length = Int(values[unsafe_offset=0])
    var gene_count = Int(values[unsafe_offset=1])
    var seed = values[unsafe_offset=2]
    var max_generations = Int(values[unsafe_offset=3])
    if target_length < 1 or target_length > 8 or gene_count < 1 or gene_count > 32:
        return -2
    if seed < 1 or seed >= Int64(MODULUS) or max_generations < 1 or max_generations > 1000:
        return -2
    if Int(length) != 4 + target_length + gene_count or result == None:
        return -2
    var output = result.value()
    var target_word: UInt64 = 0
    var target_symbols_storage = Array[UInt64, 2](fill=0)
    var target_symbols = target_symbols_storage.unsafe_ptr()
    var gene_symbols_storage = Array[UInt64, 2](fill=0)
    var gene_symbols = gene_symbols_storage.unsafe_ptr()
    var genes_storage = Array[UInt8, 32](fill=0)
    var genes = genes_storage.unsafe_ptr()
    for index in range(target_length):
        var value = values[unsafe_offset=4 + index]
        if value < 32 or value > 126:
            return -2
        target_word |= UInt64(value) << UInt64(8 * index)
        target_symbols[unsafe_offset=Int(value >> 6)] |= UInt64(1) << UInt64(value & 63)
    for index in range(gene_count):
        var value = values[unsafe_offset=4 + target_length + index]
        if value < 32 or value > 126:
            return -2
        genes[unsafe_offset=index] = UInt8(value)
        gene_symbols[unsafe_offset=Int(value >> 6)] |= UInt64(1) << UInt64(value & 63)
    if (target_symbols[unsafe_offset=0] & ~gene_symbols[unsafe_offset=0]) != 0 or (target_symbols[unsafe_offset=1] & ~gene_symbols[unsafe_offset=1]) != 0:
        return -2

    var state = UInt64(seed)
    var population_storage = Array[UInt64, POPULATION_SIZE](fill=0)
    var population = population_storage.unsafe_ptr()
    var next_population_storage = Array[UInt64, POPULATION_SIZE](fill=0)
    var next_population = next_population_storage.unsafe_ptr()
    var mismatches_storage = Array[Int, POPULATION_SIZE](fill=0)
    var mismatches = mismatches_storage.unsafe_ptr()
    var order_storage = Array[Int, POPULATION_SIZE](fill=0)
    var order = order_storage.unsafe_ptr()
    for individual in range(POPULATION_SIZE):
        var word: UInt64 = 0
        for position in range(target_length):
            var gene = genes[unsafe_offset=Int(next_random(state) % UInt64(gene_count))]
            word |= UInt64(gene) << UInt64(8 * position)
        if word == target_word:
            if capacity < 16:
                return -2
            return write_result(output, 1)
        population[unsafe_offset=individual] = word

    for generation in range(1, max_generations + 1):
        var offsets_storage = Array[Int, 9](fill=0)
        var offsets = offsets_storage.unsafe_ptr()
        for individual in range(POPULATION_SIZE):
            # The bias marks unequal ASCII bytes without carrying across bytes.
            var difference = population[unsafe_offset=individual] ^ target_word
            var unequal = ((difference + UInt64(0x7f7f7f7f7f7f7f7f)) >> 7) & UInt64(0x0101010101010101)
            var count = Int((unequal * UInt64(0x0101010101010101)) >> 56)
            if count == 0:
                if capacity < 16:
                    return -2
                return write_result(output, generation)
            mismatches[unsafe_offset=individual] = count
            offsets[unsafe_offset=count] += 1
        if generation == max_generations:
            break
        var start = 0
        for rank in range(9):
            var count = offsets[unsafe_offset=rank]
            offsets[unsafe_offset=rank] = start
            start += count
        for individual in range(POPULATION_SIZE):
            var count = mismatches[unsafe_offset=individual]
            order[unsafe_offset=offsets[unsafe_offset=count]] = individual
            offsets[unsafe_offset=count] += 1
        for rank in range(ELITE_SIZE):
            next_population[unsafe_offset=rank] = population[unsafe_offset=order[unsafe_offset=rank]]
        var next_count = ELITE_SIZE
        for rank in range(SELECTED_SIZE):
            if next_count == POPULATION_SIZE:
                break
            var first = population[unsafe_offset=order[unsafe_offset=rank]]
            var rounds = min(10, (target_length - mismatches[unsafe_offset=order[unsafe_offset=rank]]) * 100 // target_length + 1)
            for _ in range(rounds):
                if next_count == POPULATION_SIZE:
                    break
                var second = population[unsafe_offset=order[unsafe_offset=Int(next_random(state) % 51)]]
                var cut = next_random(state) % UInt64(target_length)
                var mask = (UInt64(1) << UInt64(8 * cut)) - 1
                var children_storage = Array[UInt64, 2](fill=0)
                var children = children_storage.unsafe_ptr()
                children[unsafe_offset=0] = (first & mask) | (second & ~mask)
                children[unsafe_offset=1] = (second & mask) | (first & ~mask)
                for child in range(2):
                    if next_random(state) % 5 < 2:
                        var shift = UInt64(8 * (next_random(state) % UInt64(target_length)))
                        var replacement = UInt64(genes[unsafe_offset=Int(next_random(state) % UInt64(gene_count))])
                        children[unsafe_offset=child] = (children[unsafe_offset=child] & ~(UInt64(255) << shift)) | (replacement << shift)
                    if next_count < POPULATION_SIZE:
                        next_population[unsafe_offset=next_count] = children[unsafe_offset=child]
                        next_count += 1
        for individual in range(POPULATION_SIZE):
            population[unsafe_offset=individual] = next_population[unsafe_offset=individual]
    return -1
