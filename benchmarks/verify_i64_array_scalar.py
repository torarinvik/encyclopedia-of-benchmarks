#!/usr/bin/env python3
"""Check i64-array scalar ports against independent algorithm oracles."""

from __future__ import annotations

import argparse
from collections.abc import Callable
from concurrent.futures import ThreadPoolExecutor, as_completed
import heapq
import datetime as dt
from fractions import Fraction
from itertools import combinations, product
import json
import math
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from ceil_in_binary_search_tree_oracle import MAX_NODE_COUNT as MAX_CEIL_IN_BST_NODES
from ceil_in_binary_search_tree_oracle import expected_result as ceil_in_bst_oracle
from inorder_successor_of_bst_oracle import INT32_MAX as INORDER_SUCCESSOR_OF_BST_INT32_MAX
from inorder_successor_of_bst_oracle import MAX_INPUT_LENGTH as MAX_INORDER_SUCCESSOR_OF_BST_INPUT_LENGTH
from inorder_successor_of_bst_oracle import MAX_NODE_COUNT as MAX_INORDER_SUCCESSOR_OF_BST_NODES
from inorder_successor_of_bst_oracle import expected_result as inorder_successor_of_bst_oracle
from linear_recurrence_matrix_oracle import MAX_INPUT_LENGTH as MAX_LINEAR_RECURRENCE_MATRIX_INPUT_LENGTH
from linear_recurrence_matrix_oracle import expected_result as linear_recurrence_matrix_oracle
from recursive_linear_search_oracle import MAX_COUNT as MAX_RECURSIVE_LINEAR_SEARCH_COUNT
from recursive_linear_search_oracle import MAX_INPUT_LENGTH as MAX_RECURSIVE_LINEAR_SEARCH_INPUT_LENGTH
from recursive_linear_search_oracle import MAX_VALUE as MAX_RECURSIVE_LINEAR_SEARCH_VALUE
from recursive_linear_search_oracle import MIN_VALUE as MIN_RECURSIVE_LINEAR_SEARCH_VALUE
from recursive_linear_search_oracle import expected_result as recursive_linear_search_oracle
from wildcard_matching_oracle import MAX_INPUT_LENGTH as MAX_WILDCARD_MATCHING_INPUT_LENGTH
from wildcard_matching_oracle import MAX_PATTERN_LENGTH as MAX_WILDCARD_MATCHING_PATTERN_LENGTH
from wildcard_matching_oracle import MAX_TEXT_LENGTH as MAX_WILDCARD_MATCHING_TEXT_LENGTH
from wildcard_matching_oracle import expected_result as wildcard_matching_oracle
from primitive_root_oracle import MAX_INPUT_LENGTH as MAX_PRIMITIVE_ROOT_INPUT_LENGTH
from primitive_root_oracle import MAX_MODULUS as MAX_PRIMITIVE_ROOT_MODULUS
from primitive_root_oracle import expected_result as primitive_root_oracle
from dijkstras_two_stack_algorithm_oracle import MAX_INPUT_LENGTH as MAX_DIJKSTRAS_TWO_STACK_INPUT_LENGTH
from dijkstras_two_stack_algorithm_oracle import expected_result as dijkstras_two_stack_oracle
from check_cycle_oracle import MAX_EDGES as MAX_CHECK_CYCLE_EDGES
from check_cycle_oracle import MAX_INPUT_LENGTH as MAX_CHECK_CYCLE_INPUT_LENGTH
from check_cycle_oracle import MAX_VERTICES as MAX_CHECK_CYCLE_VERTICES
from check_cycle_oracle import expected_result as check_cycle_oracle
from undirected_cycle_check_oracle import MAX_EDGES as MAX_UNDIRECTED_CYCLE_CHECK_EDGES
from undirected_cycle_check_oracle import MAX_INPUT_LENGTH as MAX_UNDIRECTED_CYCLE_CHECK_INPUT_LENGTH
from undirected_cycle_check_oracle import MAX_VERTICES as MAX_UNDIRECTED_CYCLE_CHECK_VERTICES
from undirected_cycle_check_oracle import expected_result as undirected_cycle_check_oracle
from count_singly_linked_list_recursion_oracle import I32_MAX as COUNT_SINGLY_LINKED_LIST_I32_MAX
from count_singly_linked_list_recursion_oracle import I32_MIN as COUNT_SINGLY_LINKED_LIST_I32_MIN
from count_singly_linked_list_recursion_oracle import MAX_NODES as MAX_COUNT_SINGLY_LINKED_LIST_NODES
from count_singly_linked_list_recursion_oracle import expected_result as count_singly_linked_list_oracle
from count_homogenous_oracle import MAX_INPUT_LENGTH as MAX_COUNT_HOMOGENOUS_INPUT_LENGTH
from count_homogenous_oracle import MAX_TEXT_BYTES as MAX_COUNT_HOMOGENOUS_BYTES
from count_homogenous_oracle import expected_result as count_homogenous_oracle
from car_pool_oracle import MAX_TRIPS as MAX_CAR_POOL_TRIPS
from car_pool_oracle import expected_result as car_pool_oracle
from chaining_oracle import MAX_BUCKETS as MAX_CHAINING_BUCKETS
from chaining_oracle import MAX_KEY as MAX_CHAINING_KEY
from chaining_oracle import MAX_OPERATIONS as MAX_CHAINING_OPERATIONS
from chaining_oracle import MAX_QUERIES as MAX_CHAINING_QUERIES
from chaining_oracle import expected_result as chaining_oracle
from burkes_dithering_oracle import MAX_INPUT_LENGTH as MAX_BURKES_DITHERING_INPUT_LENGTH
from burkes_dithering_oracle import MAX_SIDE as MAX_BURKES_DITHERING_SIDE
from burstballoons_oracle import expected_result as burstballoons_oracle
from brightness_oracle import expected_result as brightness_oracle
from bron_kerbosch_oracle import MAX_VERTICES as MAX_BRON_KERBOSCH_VERTICES
from bst_from_sorted_array_oracle import I32_MAX as BST_FROM_SORTED_ARRAY_I32_MAX
from bst_from_sorted_array_oracle import I32_MIN as BST_FROM_SORTED_ARRAY_I32_MIN
from bst_from_sorted_array_oracle import MAX_VALUES as MAX_BST_FROM_SORTED_ARRAY_VALUES
from checkequal_oracle import expected_result as checkequal_oracle
from celebrity_finder_oracle import MAX_INPUT_LENGTH as MAX_CELEBRITY_FINDER_INPUT_LENGTH
from celebrity_finder_oracle import expected_result as celebrity_finder_oracle
from coinchange_oracle import expected_result as coinchange_oracle
from dice_throw_oracle import MAX_DICE as MAX_DICE_THROW_DICE
from dice_throw_oracle import MAX_FACES as MAX_DICE_THROW_FACES
from dice_throw_oracle import MAX_TARGET as MAX_DICE_THROW_TARGET
from dice_throw_oracle import expected_result as dice_throw_oracle
from depth_first_search_iterative_oracle import MAX_EDGES as MAX_DFS_ITERATIVE_EDGES
from depth_first_search_iterative_oracle import MAX_INPUT_LENGTH as MAX_DFS_ITERATIVE_VALID_INPUT_LENGTH
from depth_first_search_iterative_oracle import MAX_VERTICES as MAX_DFS_ITERATIVE_VERTICES
from depth_first_search_iterative_oracle import expected_result as depth_first_search_iterative_oracle
from depth_first_search_recursive_oracle import INVALID_RESULT as DFS_RECURSIVE_INVALID_RESULT
from depth_first_search_recursive_oracle import MAX_EDGES as MAX_DFS_RECURSIVE_EDGES
from depth_first_search_recursive_oracle import MAX_INPUT_LENGTH as MAX_DFS_RECURSIVE_INPUT_LENGTH
from depth_first_search_recursive_oracle import MAX_VERTICES as MAX_DFS_RECURSIVE_VERTICES
from depth_first_search_recursive_oracle import expected_result as depth_first_search_recursive_oracle
from elf_hash_oracle import MAX_INPUT_LENGTH as MAX_ELF_HASH_INPUT_LENGTH
from elf_hash_oracle import MAX_VALID_INPUT_LENGTH as MAX_ELF_HASH_VALID_INPUT_LENGTH
from elf_hash_oracle import expected_result as elf_hash_oracle
from is_isomorphic_oracle import MAX_CODEPOINTS_PER_STRING as MAX_ISOMORPHIC_CODEPOINTS
from is_isomorphic_oracle import MAX_INPUT_LENGTH as MAX_ISOMORPHIC_INPUT_LENGTH
from is_isomorphic_oracle import expected_result as is_isomorphic_oracle
from is_graph_bipartite_oracle import MAX_EDGES as MAX_BIPARTITE_EDGES
from is_graph_bipartite_oracle import MAX_INPUT_LENGTH as MAX_BIPARTITE_INPUT_LENGTH
from is_graph_bipartite_oracle import MAX_VERTICES as MAX_BIPARTITE_VERTICES
from is_graph_bipartite_oracle import expected_result as is_graph_bipartite_oracle
from karatsuba_oracle import MAX_INPUT_LENGTH as MAX_KARATSUBA_INPUT_LENGTH
from karatsuba_oracle import MAX_OPERAND as MAX_KARATSUBA_OPERAND
from karatsuba_oracle import expected_result as karatsuba_oracle
from parse_integer_oracle import MAX_INPUT_LENGTH as MAX_PARSE_INTEGER_INPUT_LENGTH
from parse_integer_oracle import expected_result as parse_integer_oracle
from good_pairs_oracle import MAX_INPUT_LENGTH as MAX_GOOD_PAIRS_INPUT_LENGTH
from good_pairs_oracle import MAX_N as MAX_GOOD_PAIRS_N
from good_pairs_oracle import MAX_VALUE as MAX_GOOD_PAIRS_VALUE
from good_pairs_oracle import MIN_VALUE as MIN_GOOD_PAIRS_VALUE
from good_pairs_oracle import expected_result as good_pairs_oracle
from good_pairs_hash_oracle import MAX_ARRAY_LENGTH as MAX_GOOD_PAIRS_HASH_N
from good_pairs_hash_oracle import MAX_INPUT_LENGTH as MAX_GOOD_PAIRS_HASH_INPUT_LENGTH
from good_pairs_hash_oracle import MAX_VALUE as MAX_GOOD_PAIRS_HASH_VALUE
from good_pairs_hash_oracle import expected_result as good_pairs_hash_oracle
from find_kth_number_oracle import I32_MAX as MAX_FIND_KTH_NUMBER_VALUE
from find_kth_number_oracle import I32_MIN as MIN_FIND_KTH_NUMBER_VALUE
from find_kth_number_oracle import MAX_INPUT_LENGTH as MAX_FIND_KTH_NUMBER_INPUT_LENGTH
from find_kth_number_oracle import MAX_VALUES as MAX_FIND_KTH_NUMBER_VALUES
from find_kth_number_oracle import expected_result as find_kth_number_oracle
from non_repeating_element_oracle import MAX_INPUT_LENGTH as MAX_NON_REPEATING_ELEMENT_INPUT_LENGTH
from non_repeating_element_oracle import MAX_VALUE as MAX_NON_REPEATING_ELEMENT_VALUE
from non_repeating_element_oracle import expected_result as non_repeating_element_oracle
from in_static_equilibrium_oracle import MAX_COMPONENT as MAX_STATIC_EQUILIBRIUM_COMPONENT
from in_static_equilibrium_oracle import MAX_INPUT_LENGTH as MAX_STATIC_EQUILIBRIUM_INPUT_LENGTH
from in_static_equilibrium_oracle import MAX_N as MAX_STATIC_EQUILIBRIUM_N
from in_static_equilibrium_oracle import expected_result as in_static_equilibrium_oracle
from index_2d_array_in_1d_oracle import MAX_COLUMNS as MAX_INDEX_2D_COLUMNS
from index_2d_array_in_1d_oracle import MAX_INPUT_LENGTH as MAX_INDEX_2D_ARRAY_IN_1D_INPUT_LENGTH
from index_2d_array_in_1d_oracle import MAX_ROWS as MAX_INDEX_2D_ROWS
from index_2d_array_in_1d_oracle import MAX_VALUE as MAX_INDEX_2D_VALUE
from index_2d_array_in_1d_oracle import expected_result as index_2d_array_in_1d_oracle
from gas_station_oracle import MAX_INPUT_LENGTH as MAX_GAS_STATION_INPUT_LENGTH
from gas_station_oracle import MAX_STATIONS as MAX_GAS_STATION_STATIONS
from gas_station_oracle import expected_result as gas_station_oracle
from find_second_largest_element_oracle import INVALID_RESULT as FIND_SECOND_LARGEST_ELEMENT_INVALID_RESULT
from find_second_largest_element_oracle import INT32_MAX as FIND_SECOND_LARGEST_ELEMENT_INT32_MAX
from find_second_largest_element_oracle import INT32_MIN as FIND_SECOND_LARGEST_ELEMENT_INT32_MIN
from find_second_largest_element_oracle import MAX_ARRAY_LENGTH as MAX_FIND_SECOND_LARGEST_ELEMENT_VALUES
from find_second_largest_element_oracle import MAX_INPUT_LENGTH as MAX_FIND_SECOND_LARGEST_ELEMENT_INPUT_LENGTH
from find_second_largest_element_oracle import expected_result as find_second_largest_element_oracle
from second_min_max_oracle import INT32_MAX as SECOND_MIN_MAX_INT32_MAX
from second_min_max_oracle import INT32_MIN as SECOND_MIN_MAX_INT32_MIN
from second_min_max_oracle import MAX_ARRAY_LENGTH as MAX_SECOND_MIN_MAX_VALUES
from second_min_max_oracle import MAX_INPUT_LENGTH as MAX_SECOND_MIN_MAX_INPUT_LENGTH
from second_min_max_oracle import expected_result as second_min_max_oracle
from constrained_shortest_path_oracle import INVALID_RESULT as CONSTRAINED_SHORTEST_PATH_INVALID_RESULT
from constrained_shortest_path_oracle import MAX_EDGE_COUNT as MAX_CONSTRAINED_SHORTEST_PATH_EDGES
from constrained_shortest_path_oracle import MAX_INPUT_LENGTH as MAX_CONSTRAINED_SHORTEST_PATH_INPUT_LENGTH
from constrained_shortest_path_oracle import expected_result as constrained_shortest_path_oracle
from jump_game_oracle import INVALID_RESULT as JUMP_GAME_INVALID_RESULT
from jump_game_oracle import MAX_ARRAY_LENGTH as MAX_JUMP_GAME_VALUES
from jump_game_oracle import MAX_INPUT_LENGTH as MAX_JUMP_GAME_INPUT_LENGTH
from jump_game_oracle import MAX_JUMP as MAX_JUMP_GAME_JUMP
from jump_game_oracle import expected_result as jump_game_oracle
from pairs_with_given_sum_oracle import INVALID_RESULT as PAIRS_WITH_GIVEN_SUM_INVALID_RESULT
from pairs_with_given_sum_oracle import MAX_INPUT_LENGTH as MAX_PAIRS_WITH_GIVEN_SUM_INPUT_LENGTH
from pairs_with_given_sum_oracle import MAX_VALUE_COUNT as MAX_PAIRS_WITH_GIVEN_SUM_VALUES
from pairs_with_given_sum_oracle import expected_result as pairs_with_given_sum_oracle
from comparison_oracle import MAX_INPUT_LENGTH as MAX_COMPARISON_INPUT_LENGTH
from comparison_oracle import expected_result as comparison_oracle
from count_less_equal_in_sorted_array_oracle import INT32_MAX as COUNT_LESS_EQUAL_INT32_MAX
from count_less_equal_in_sorted_array_oracle import INT32_MIN as COUNT_LESS_EQUAL_INT32_MIN
from count_less_equal_in_sorted_array_oracle import MAX_INPUT_LENGTH as MAX_COUNT_LESS_EQUAL_INPUT_LENGTH
from count_less_equal_in_sorted_array_oracle import MAX_VALUES as MAX_COUNT_LESS_EQUAL_VALUES
from count_less_equal_in_sorted_array_oracle import expected_result as count_less_equal_in_sorted_array_oracle
from lipogram_oracle import ASCII_WHITESPACE as LIPOGRAM_ASCII_WHITESPACE
from lipogram_oracle import MAX_MISSING_MASK as MAX_LIPOGRAM_MISSING_MASK
from lipogram_oracle import MAX_TEXT_BYTES as MAX_LIPOGRAM_TEXT_BYTES
from lipogram_oracle import expected_result as lipogram_oracle
from s.saddleback_search_oracle import I32_MAX as MAX_SADDLEBACK_SEARCH_VALUE
from s.saddleback_search_oracle import I32_MIN as MIN_SADDLEBACK_SEARCH_VALUE
from s.saddleback_search_oracle import MAX_COLUMNS as MAX_SADDLEBACK_SEARCH_COLUMNS
from s.saddleback_search_oracle import MAX_INPUT_LENGTH as MAX_SADDLEBACK_SEARCH_INPUT_LENGTH
from s.saddleback_search_oracle import MAX_ROWS as MAX_SADDLEBACK_SEARCH_ROWS
from s.saddleback_search_oracle import expected_result as saddleback_search_oracle
from max_area_of_island_oracle import MAX_COLUMNS as MAX_MAX_AREA_OF_ISLAND_COLUMNS
from max_area_of_island_oracle import MAX_INPUT_LENGTH as MAX_MAX_AREA_OF_ISLAND_INPUT_LENGTH
from max_area_of_island_oracle import MAX_ROWS as MAX_MAX_AREA_OF_ISLAND_ROWS
from max_area_of_island_oracle import expected_result as max_area_of_island_oracle
from directed_dfs_forest_count_oracle import INVALID_RESULT as DIRECTED_DFS_FOREST_COUNT_INVALID_RESULT
from directed_dfs_forest_count_oracle import MAX_EDGE_COUNT as MAX_DIRECTED_DFS_FOREST_COUNT_EDGES
from directed_dfs_forest_count_oracle import MAX_INPUT_LENGTH as MAX_DIRECTED_DFS_FOREST_COUNT_INPUT_LENGTH
from directed_dfs_forest_count_oracle import MAX_VERTEX_ID as MAX_DIRECTED_DFS_FOREST_COUNT_VERTEX_ID
from directed_dfs_forest_count_oracle import expected_result as directed_dfs_forest_count_oracle
from hamming_distance_bytes_oracle import expected_result as hamming_distance_bytes_oracle
from hamming_distance_strings_oracle import MAX_INPUT_LENGTH as MAX_HAMMING_DISTANCE_STRINGS_INPUT_LENGTH
from hamming_distance_strings_oracle import MAX_STRING_LENGTH as MAX_HAMMING_DISTANCE_STRINGS_LENGTH
from hamming_distance_strings_oracle import expected_result as hamming_distance_strings_oracle
from djb2_oracle import MAX_INPUT_LENGTH as MAX_DJB2_INPUT_LENGTH
from djb2_oracle import MAX_STRING_LENGTH as MAX_DJB2_STRING_LENGTH
from djb2_oracle import expected_result as djb2_oracle
from hash_djb2_oracle import MAX_BYTES as HASH_DJB2_MAX_BYTES
from hash_djb2_oracle import MAX_INPUT_LENGTH as MAX_HASH_DJB2_INPUT_LENGTH
from hash_djb2_oracle import expected_result as hash_djb2_oracle
from hash_xor8_oracle import INVALID_RESULT as HASH_XOR8_INVALID_RESULT
from hash_xor8_oracle import MAX_INPUT_LENGTH as MAX_HASH_XOR8_INPUT_LENGTH
from hash_xor8_oracle import expected_result as hash_xor8_oracle
from hex_to_oct_oracle import INVALID_RESULT as HEX_TO_OCT_INVALID_RESULT
from hex_to_oct_oracle import MAX_INPUT_LENGTH as MAX_HEX_TO_OCT_INPUT_LENGTH
from hex_to_oct_oracle import MAX_PARSEABLE_INPUT_LENGTH as MAX_HEX_TO_OCT_PARSEABLE_INPUT_LENGTH
from hex_to_oct_oracle import expected_result as hex_to_oct_oracle
from grid_get_oracle import MAX_COLUMNS as MAX_GRID_GET_COLUMNS
from grid_get_oracle import MAX_INDEX as MAX_GRID_GET_INDEX
from grid_get_oracle import MAX_INPUT_LENGTH as MAX_GRID_GET_INPUT_LENGTH
from grid_get_oracle import expected_result as grid_get_oracle
from number_of_subarrays_with_odd_sum_oracle import MAX_INPUT_LENGTH as MAX_ODD_SUM_SUBARRAY_INPUT_LENGTH
from number_of_subarrays_with_odd_sum_oracle import MAX_VALUE as MAX_ODD_SUM_SUBARRAY_VALUE
from number_of_subarrays_with_odd_sum_oracle import MIN_VALUE as MIN_ODD_SUM_SUBARRAY_VALUE
from number_of_subarrays_with_odd_sum_oracle import expected_result as odd_sum_subarray_oracle
from maximum_circular_subarray_oracle import MAX_INPUT_LENGTH as MAX_MAX_CIRCULAR_SUBARRAY_INPUT_LENGTH
from maximum_circular_subarray_oracle import MAX_VALID_INPUT_LENGTH as MAX_MAX_CIRCULAR_SUBARRAY_VALID_INPUT_LENGTH
from maximum_circular_subarray_oracle import MAX_VALUE as MAX_MAX_CIRCULAR_SUBARRAY_VALUE
from maximum_circular_subarray_oracle import MIN_VALUE as MIN_MAX_CIRCULAR_SUBARRAY_VALUE
from maximum_circular_subarray_oracle import expected_result as maximum_circular_subarray_oracle
from maximum_product_subarray_oracle import MAX_INPUT_LENGTH as MAX_MAX_PRODUCT_SUBARRAY_INPUT_LENGTH
from maximum_product_subarray_oracle import MAX_VALID_INPUT_LENGTH as MAX_MAX_PRODUCT_SUBARRAY_VALID_INPUT_LENGTH
from maximum_product_subarray_oracle import MAX_VALUE as MAX_MAX_PRODUCT_SUBARRAY_VALUE
from maximum_product_subarray_oracle import MIN_VALUE as MIN_MAX_PRODUCT_SUBARRAY_VALUE
from maximum_product_subarray_oracle import expected_result as maximum_product_subarray_oracle
from maximum_subarray_int32_oracle import MAX_ABS_VALUE as MAX_MAXIMUM_SUBARRAY_INT32_ABS_VALUE
from maximum_subarray_int32_oracle import MAX_INPUT_LENGTH as MAX_MAXIMUM_SUBARRAY_INT32_INPUT_LENGTH
from maximum_subarray_int32_oracle import MAX_LENGTH as MAX_MAXIMUM_SUBARRAY_INT32_LENGTH
from maximum_subarray_int32_oracle import expected_result as maximum_subarray_int32_oracle
from maximum_subarray_allow_empty_oracle import MAX_INPUT_LENGTH as MAX_MAXIMUM_SUBARRAY_ALLOW_EMPTY_INPUT_LENGTH
from maximum_subarray_allow_empty_oracle import MAX_LENGTH as MAX_MAXIMUM_SUBARRAY_ALLOW_EMPTY_LENGTH
from maximum_subarray_allow_empty_oracle import expected_result as maximum_subarray_allow_empty_oracle
from median_search_oracle import INT32_MAX as MEDIAN_SEARCH_INT32_MAX
from median_search_oracle import MAX_ELEMENT_COUNT as MAX_MEDIAN_SEARCH_ELEMENT_COUNT
from median_search_oracle import MAX_INPUT_LENGTH as MAX_MEDIAN_SEARCH_INPUT_LENGTH
from median_search_oracle import expected_result as median_search_oracle
from largest_rectangle_histogram_oracle import MAX_HEIGHT as MAX_LARGEST_RECTANGLE_HISTOGRAM_HEIGHT
from largest_rectangle_histogram_oracle import MAX_INPUT_LENGTH as MAX_LARGEST_RECTANGLE_HISTOGRAM_INPUT_LENGTH
from largest_rectangle_histogram_oracle import MAX_VALID_INPUT_LENGTH as MAX_LARGEST_RECTANGLE_HISTOGRAM_VALID_INPUT_LENGTH
from largest_rectangle_histogram_oracle import MIN_HEIGHT as MIN_LARGEST_RECTANGLE_HISTOGRAM_HEIGHT
from largest_rectangle_histogram_oracle import expected_result as largest_rectangle_histogram_oracle
from hamiltonian_path_exists_oracle import MAX_INPUT_LENGTH as MAX_HAMILTONIAN_PATH_EXISTS_INPUT_LENGTH
from hamiltonian_path_exists_oracle import MAX_VALID_VERTICES as MAX_HAMILTONIAN_PATH_EXISTS_VERTICES
from hamiltonian_path_exists_oracle import expected_output as hamiltonian_path_exists_oracle
from fast_searcher_oracle import MAX_ARRAY_LENGTH as MAX_FAST_SEARCHER_ARRAY_LENGTH
from fast_searcher_oracle import MAX_INPUT_LENGTH as MAX_FAST_SEARCHER_INPUT_LENGTH
from fast_searcher_oracle import MAX_VALUE as MAX_FAST_SEARCHER_VALUE
from fast_searcher_oracle import MIN_VALUE as MIN_FAST_SEARCHER_VALUE
from fast_searcher_oracle import expected_result as fast_searcher_oracle
from minimum_sum_partition_oracle import MAX_INPUT_LENGTH as MAX_MINIMUM_SUM_PARTITION_INPUT_LENGTH
from minimum_sum_partition_oracle import MAX_TOTAL_SUM as MAX_MINIMUM_SUM_PARTITION_TOTAL
from minimum_sum_partition_oracle import MAX_VALID_INPUT_LENGTH as MAX_MINIMUM_SUM_PARTITION_VALID_LENGTH
from minimum_sum_partition_oracle import expected_result as minimum_sum_partition_oracle
from upper_bound_oracle import INT32_MAX as UPPER_BOUND_INT32_MAX
from upper_bound_oracle import INT32_MIN as UPPER_BOUND_INT32_MIN
from upper_bound_oracle import MAX_ARRAY_LENGTH as MAX_UPPER_BOUND_ARRAY_LENGTH
from upper_bound_oracle import MAX_INPUT_LENGTH as MAX_UPPER_BOUND_INPUT_LENGTH
from upper_bound_oracle import expected_result as upper_bound_oracle
from hexa_decimal_to_decimal_oracle import MAX_ASCII_VALUE as HEXA_DECIMAL_MAX_ASCII_VALUE
from hexa_decimal_to_decimal_oracle import MAX_INPUT_LENGTH as MAX_HEXA_DECIMAL_INPUT_LENGTH
from hexa_decimal_to_decimal_oracle import MAX_PARSEABLE_INPUT_LENGTH as MAX_HEXA_DECIMAL_PARSEABLE_INPUT_LENGTH
from hexa_decimal_to_decimal_oracle import expected_result as hexa_decimal_to_decimal_oracle
from longest_subarray_with_sum_at_most_oracle import MAX_ARRAY_LENGTH as MAX_LONGEST_SUBARRAY_VALUES
from longest_subarray_with_sum_at_most_oracle import MAX_DOMAIN_VALUE as MAX_LONGEST_SUBARRAY_DOMAIN_VALUE
from longest_subarray_with_sum_at_most_oracle import MAX_INPUT_LENGTH as MAX_LONGEST_SUBARRAY_INPUT_LENGTH
from longest_subarray_with_sum_at_most_oracle import expected_result as longest_subarray_with_sum_at_most_oracle
from pow_logarithmic_oracle import MAX_BASE as MAX_POW_LOGARITHMIC_BASE
from pow_logarithmic_oracle import MAX_EXPONENT as MAX_POW_LOGARITHMIC_EXPONENT
from pow_logarithmic_oracle import MAX_PARSEABLE_INPUT_LENGTH as MAX_POW_LOGARITHMIC_PARSEABLE_INPUT_LENGTH
from pow_logarithmic_oracle import MIN_BASE as MIN_POW_LOGARITHMIC_BASE
from pow_logarithmic_oracle import MIN_EXPONENT as MIN_POW_LOGARITHMIC_EXPONENT
from pow_logarithmic_oracle import expected_result as pow_logarithmic_oracle
from length_of_last_word_oracle import MAX_BYTES as MAX_LENGTH_OF_LAST_WORD_BYTES
from length_of_last_word_oracle import MAX_INPUT_LENGTH as MAX_LENGTH_OF_LAST_WORD_INPUT_LENGTH
from length_of_last_word_oracle import expected_result as length_of_last_word_oracle
from find_min_iterator_oracle import MAX_COUNT as MAX_FIND_MIN_ITERATOR_COUNT
from find_min_iterator_oracle import MAX_INPUT_LENGTH as MAX_FIND_MIN_ITERATOR_INPUT_LENGTH
from find_min_iterator_oracle import MAX_VALUE as MAX_FIND_MIN_ITERATOR_VALUE
from find_min_iterator_oracle import expected_result as find_min_iterator_oracle
from digit_dp_oracle import I32_MAX as DIGIT_DP_I32_MAX
from digit_dp_oracle import I32_MIN as DIGIT_DP_I32_MIN
from digit_dp_oracle import MAX_BOUND as MAX_DIGIT_DP_BOUND
from digit_dp_oracle import MAX_DIGIT_SUM as MAX_DIGIT_DP_SUM
from digit_dp_oracle import MAX_INPUT_LENGTH as MAX_DIGIT_DP_INPUT_LENGTH
from digit_dp_oracle import expected_result as digit_dp_oracle
from modular_exponentiation_oracle import I32_MAX as MODULAR_EXPONENTIATION_I32_MAX
from modular_exponentiation_oracle import I32_MIN as MODULAR_EXPONENTIATION_I32_MIN
from modular_exponentiation_oracle import MAX_PARSEABLE_INPUT_LENGTH as MAX_MODULAR_EXPONENTIATION_INPUT_LENGTH
from modular_exponentiation_oracle import expected_result as modular_exponentiation_oracle
from modpow_oracle import MAX_COMPONENT as MAX_MODPOW_COMPONENT
from modpow_oracle import MAX_EXPONENT as MAX_MODPOW_EXPONENT
from modpow_oracle import MAX_PARSEABLE_INPUT_LENGTH as MAX_MODPOW_INPUT_LENGTH
from modpow_oracle import expected_result as modpow_oracle
from divisors_oracle import MAX_INPUT_LENGTH as MAX_DIVISORS_INPUT_LENGTH
from divisors_oracle import MAX_N as MAX_DIVISORS_N
from divisors_oracle import expected_result as divisors_oracle
from xor_search_missing_number_oracle import MAX_N as MAX_XOR_SEARCH_MISSING_NUMBER_N
from xor_search_missing_number_oracle import MAX_INPUT_LENGTH as MAX_XOR_SEARCH_MISSING_NUMBER_INPUT_LENGTH
from xor_search_missing_number_oracle import expected_result as xor_search_missing_number_oracle
from maximum_sum_bst_oracle import MAX_SLOTS as MAX_MAXIMUM_SUM_BST_SLOTS
from maximum_sum_bst_oracle import MAX_VALUE as MAX_MAXIMUM_SUM_BST_VALUE
from maximum_sum_bst_oracle import MAX_INPUT_LENGTH as MAX_MAXIMUM_SUM_BST_INPUT_LENGTH
from maximum_sum_bst_oracle import expected_result as maximum_sum_bst_oracle
from how_many_times_rotated_oracle import I32_MAX as HOW_MANY_TIMES_ROTATED_I32_MAX
from how_many_times_rotated_oracle import I32_MIN as HOW_MANY_TIMES_ROTATED_I32_MIN
from how_many_times_rotated_oracle import MAX_ARRAY_LENGTH as MAX_HOW_MANY_TIMES_ROTATED_ARRAY_LENGTH
from how_many_times_rotated_oracle import MAX_INPUT_LENGTH as MAX_HOW_MANY_TIMES_ROTATED_INPUT_LENGTH
from how_many_times_rotated_oracle import expected_result as how_many_times_rotated_oracle
from is_valid_email_address_oracle import expected_result as is_valid_email_address_oracle
from n_in_a_row_board_status_oracle import MAX_BOARD_SIZE as MAX_N_IN_A_ROW_BOARD_SIZE
from n_in_a_row_board_status_oracle import expected_result as n_in_a_row_board_status_oracle
from run_i64_array_scalar import encode_case
from string_prefix_suffix_oracle import expected_result as string_prefix_suffix_oracle
from one_bit_difference_oracle import expected_result as one_bit_difference_oracle
from one_bit_difference_oracle import MAX_INPUT_LENGTH as MAX_ONE_BIT_DIFFERENCE_INPUT_LENGTH
from edmonds_blossom_algorithm_oracle import MAX_EDGES as MAX_EDMONDS_BLOSSOM_EDGES
from edmonds_blossom_algorithm_oracle import MAX_INPUT_LENGTH as MAX_EDMONDS_BLOSSOM_INPUT_LENGTH
from edmonds_blossom_algorithm_oracle import MAX_VERTICES as MAX_EDMONDS_BLOSSOM_VERTICES
from edmonds_blossom_algorithm_oracle import expected_result as edmonds_blossom_oracle

ALGORITHMS = ("lcm_of_n_numbers", "problem18", "problem22", "problem54", "problem59", "problem67", "problem71", "problem81", "problem82", "problem99", "problem102", "problem107", "problem345", "alternate_harmonic_series", "alternating_harmonic_series", "mode", "number_of_positive_divisors", "divisors", "n_bonacci", "egg_dropping", "subarray_sum_equals_k", "optimal_string_alignment_distance", "validate_credit_card", "endianness", "hamming_distance_bytes", "hamming_distance_strings", "hexa_decimal_to_decimal", "djb2", "hash_djb2", "hash_xor8", "hex_to_oct", "grid_get", "number_of_subarrays_with_odd_sum", "maximum_circular_subarray", "maximum_product_subarray", "maximum_subarray_int32", "maximum_subarray_allow_empty", "median_search", "largest_rectangle_histogram", "hamiltonian_path_exists", "fast_searcher", "minimum_sum_partition", "upper_bound", "longest_subarray_with_sum_at_most", "length_of_last_word", "find_min_iterator", "how_many_times_rotated", "digit_dp", "xor_search_missing_number", "maximum_sum_bst", "in_static_equilibrium", "string_prefix_suffix", "brightness", "bron_kerbosch", "edmonds_blossom_algorithm", "is_valid_email_address", "bidirectional_dijkstra", "bst_from_sorted_array", "burstballoons", "checkequal", "coinchange", "celebrity_finder", "burkes_dithering", "car_pool", "ceil_in_binary_search_tree", "inorder_successor_of_bst", "linear_recurrence_matrix", "recursive_linear_search", "chaining", "set_kth_bit", "max_area_of_island", "directed_dfs_forest_count", "count_homogenous", "check_cycle", "n_in_a_row_board_status", "non_repeating_element", "count_singly_linked_list_recursion", "dice_throw", "depth_first_search_iterative", "depth_first_search_recursive", "elf_hash", "is_isomorphic", "is_graph_bipartite", "karatsuba", "good_pairs", "good_pairs_hash", "find_kth_number", "parse_integer", "pow_logarithmic", "modular_exponentiation", "modpow", "saddleback_search", "index_2d_array_in_1d", "gas_station", "find_second_largest_element", "second_min_max", "constrained_shortest_path", "jump_game", "pairs_with_given_sum", "comparison", "count_less_equal_in_sorted_array", "lipogram", "one_bit_difference", "wildcard_matching", "primitive_root", "dijkstras_two_stack_algorithm", "undirected_cycle_check")
I64_MIN = -(2**63)
I64_MAX = 2**63 - 1


def lcm_oracle(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) > 100000
            or any(type(value) is not int or not 0 <= value <= I64_MAX for value in values)):
        raise ValueError("inputs must be an array of nonnegative signed 64-bit integers")
    exact = math.lcm(*values)
    return exact if exact <= I64_MAX else -1


def set_kth_bit_oracle(values: list[int]) -> int:
    """Set one bounded bit in a nonnegative 31-bit integer."""
    if (not isinstance(values, list) or len(values) != 2
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1
    number, bit_position = values
    if not 0 <= number <= 2_147_483_647 or not 0 <= bit_position <= 30:
        return -1
    return number | (1 << bit_position)


def bidirectional_dijkstra_oracle(values: list[int]) -> int:
    """Use Bellman-Ford relaxations, independent of the ports' two-frontier search."""
    if (not isinstance(values, list) or len(values) < 4 or len(values) > 772
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1
    vertex_count, edge_count, source, target = values[:4]
    if (not 1 <= vertex_count <= 64 or not 0 <= edge_count <= 256
            or len(values) != 4 + 3 * edge_count
            or not 0 <= source < vertex_count or not 0 <= target < vertex_count):
        return -1
    edges = []
    for offset in range(4, len(values), 3):
        origin, destination, weight = values[offset:offset + 3]
        if (not 0 <= origin < vertex_count or not 0 <= destination < vertex_count
                or not 0 <= weight <= 1_000_000):
            return -1
        edges.append((origin, destination, weight))
    distances: list[int | None] = [None] * vertex_count
    distances[source] = 0
    for _ in range(vertex_count - 1):
        changed = False
        for origin, destination, weight in edges:
            prefix = distances[origin]
            if prefix is None:
                continue
            candidate = prefix + weight
            if distances[destination] is None or candidate < distances[destination]:
                distances[destination] = candidate
                changed = True
        if not changed:
            break
    return -1 if distances[target] is None else distances[target]


def number_of_positive_divisors_oracle(values: list[int]) -> int:
    """Count divisor pairs, independent of the ports' prime-factorization method."""
    if (len(values) != 1
            or type(values[0]) is not int
            or not I64_MIN <= values[0] <= I64_MAX
            or not -1_000_000_000 <= values[0] <= 1_000_000_000):
        return -1
    number = abs(values[0])
    if number == 0:
        return 1
    divisor_count = 0
    divisor = 1
    while divisor <= number // divisor:
        if number % divisor == 0:
            divisor_count += 1 if divisor * divisor == number else 2
        divisor += 1
    return divisor_count


def egg_dropping_oracle(values: list[int]) -> int:
    """Compute the answer by the moves/coverage recurrence, not floor DP."""
    if (len(values) != 2
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return I64_MIN
    eggs, floors = values
    if not 1 <= eggs <= 12 or not 1 <= floors <= 128:
        return I64_MIN
    coverage = [0] * (eggs + 1)
    drops = 0
    while coverage[eggs] < floors:
        drops += 1
        for egg in range(eggs, 0, -1):
            coverage[egg] += coverage[egg - 1] + 1
    return drops


def subarray_sum_equals_k_oracle(values: list[int]) -> int:
    """Enumerate every contiguous range, independent of prefix frequencies."""
    if (len(values) < 2
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return I64_MIN
    count, target = values[:2]
    items = values[2:]
    if (not 0 <= count <= 512 or len(items) != count
            or not -(2**31) <= target <= 2**31 - 1
            or any(not -(2**31) <= value <= 2**31 - 1 for value in items)):
        return I64_MIN
    matches = 0
    for start in range(count):
        running_sum = 0
        for end in range(start, count):
            running_sum += items[end]
            matches += running_sum == target
    return matches


def alternate_harmonic_series_oracle(values: list[int]) -> int:
    """Evaluate the finite rational sequence with an independent Fraction oracle."""
    if (not 1 <= len(values) <= 2001
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1
    count = values[0]
    if not 1 <= count <= 1000 or len(values) != 1 + 2 * count:
        return -1
    terms = []
    for offset in range(1, len(values), 2):
        numerator, denominator = values[offset:offset + 2]
        if not -1000 <= numerator <= 1000 or numerator == 0 or not 1 <= denominator <= 1000:
            return -1
        terms.append((numerator, denominator))
    if count < 3:
        return 1
    reciprocal_magnitudes = [Fraction(denominator, abs(numerator))
                             for numerator, denominator in terms]
    common_difference = reciprocal_magnitudes[1] - reciprocal_magnitudes[0]
    for index in range(2, count):
        if ((terms[index - 1][0] < 0) == (terms[index][0] < 0)
                or reciprocal_magnitudes[index] - reciprocal_magnitudes[index - 1]
                != common_difference):
            return 0
    return 1


def alternating_harmonic_series_oracle(values: list[int]) -> int:
    """Compare rational terms with the canonical prefix at exact tolerance."""
    if (not 1 <= len(values) <= 2001
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1
    count = values[0]
    if not 0 <= count <= 1000 or len(values) != 1 + 2 * count:
        return -1
    for index in range(count):
        numerator, denominator = values[1 + 2 * index:3 + 2 * index]
        if not -1000 <= numerator <= 1000 or not 1 <= denominator <= 1000:
            return -1
        sign = 1 if index % 2 == 0 else -1
        if abs(numerator * (index + 1) - sign * denominator) * 1_000_000_000 > denominator * (index + 1):
            return 0
    return int(count != 0)


def problem22_oracle(values: list[int]) -> int:
    if not values or len(values) > 100_001 or any(type(value) is not int for value in values):
        return -1
    count = values[0]
    if not 0 <= count <= 6000:
        return -1
    offset = 1
    names = []
    for _ in range(count):
        if offset >= len(values):
            return -1
        length = values[offset]
        offset += 1
        if not 1 <= length <= 19 or offset + length > len(values):
            return -1
        name = tuple(values[offset:offset + length])
        if any(not 1 <= letter <= 26 for letter in name):
            return -1
        names.append(name)
        offset += length
    if offset != len(values):
        return -1
    return sum(position * sum(name) for position, name in enumerate(sorted(names), 1))


def problem54_oracle(values: list[int]) -> int:
    if (len(values) != 10_000
            or any(type(card) is not int or not 0 <= card < 52 for card in values)):
        return -1

    def evaluate(cards: list[int]) -> tuple[int, ...]:
        by_rank: dict[int, list[int]] = {}
        suits = []
        for card in cards:
            by_rank.setdefault(card // 4 + 2, []).append(card)
            suits.append(card % 4)
        ordered_ranks = sorted(by_rank, reverse=True)
        ordered_groups = sorted(((len(group), rank) for rank, group in by_rank.items()), reverse=True)
        flush = all(suit == suits[0] for suit in suits[1:])
        straight = 0
        if len(ordered_ranks) == 5:
            if ordered_ranks[0] - ordered_ranks[-1] == 4:
                straight = ordered_ranks[0]
            elif ordered_ranks == [14, 5, 4, 3, 2]:
                straight = 5
        if flush and straight:
            return (9 if straight == 14 else 8, straight)
        if ordered_groups[0][0] == 4:
            return (7, ordered_groups[0][1], ordered_groups[1][1])
        if ordered_groups[0][0] == 3 and ordered_groups[1][0] == 2:
            return (6, ordered_groups[0][1], ordered_groups[1][1])
        if flush:
            return (5, *ordered_ranks)
        if straight:
            return (4, straight)
        if ordered_groups[0][0] == 3:
            return (3, ordered_groups[0][1], *sorted(
                (rank for rank, group in by_rank.items() if len(group) == 1), reverse=True))
        pairs = sorted((rank for rank, group in by_rank.items() if len(group) == 2), reverse=True)
        kickers = sorted((rank for rank, group in by_rank.items() if len(group) == 1), reverse=True)
        if len(pairs) == 2:
            return (2, pairs[0], pairs[1], kickers[0])
        if pairs:
            return (1, pairs[0], *kickers)
        return (0, *ordered_ranks)

    wins = 0
    for offset in range(0, len(values), 10):
        deal = values[offset:offset + 10]
        if len(set(deal)) != 10:
            return -1
        wins += evaluate(deal[:5]) > evaluate(deal[5:])
    return wins


def problem59_oracle(values: list[int]) -> int:
    """Decode the bundled ciphertext by exhaustively checking all lowercase keys."""
    if (not 1 <= len(values) <= 4096
            or any(type(byte) is not int or not 0 <= byte <= 255 for byte in values)):
        return -1
    ciphertext = bytes(values)
    valid = []
    for key in product(range(ord("a"), ord("z") + 1), repeat=3):
        plaintext = bytes(byte ^ key[index % 3] for index, byte in enumerate(ciphertext))
        if all(9 <= byte <= 13 or 32 <= byte <= 126 for byte in plaintext):
            valid.append(plaintext)
    for word in (b"the", b"be", b"to", b"of", b"and", b"in", b"that", b"have"):
        valid = [plaintext for plaintext in valid if word in plaintext]
        if len(valid) == 1:
            break
    return sum(valid[0]) if valid else -1


def problem67_oracle(values: list[int]) -> int:
    """Use a forward row DP to independently score a packed triangle."""
    if (not 2 <= len(values) <= 5051
            or any(type(value) is not int for value in values)):
        return -1
    rows = values[0]
    if (not 1 <= rows <= 100 or len(values) != 1 + rows * (rows + 1) // 2
            or any(not 0 <= value <= 1_000_000 for value in values[1:])):
        return -1
    best = [values[1]]
    offset = 2
    for row in range(1, rows):
        next_best = []
        for column in range(row + 1):
            value = values[offset]
            offset += 1
            parents = []
            if column:
                parents.append(best[column - 1])
            if column < len(best):
                parents.append(best[column])
            next_best.append(value + max(parents))
        best = next_best
    return max(best)


def problem71_oracle(values: list[int]) -> int:
    if (len(values) != 3 or any(type(value) is not int for value in values)):
        return -1
    numerator_target, denominator_target, limit = values
    if (not 0 < numerator_target < denominator_target <= 1_000_000
            or math.gcd(numerator_target, denominator_target) != 1
            or not 1 <= limit <= 1_000_000):
        return -1
    best_num, best_den = 0, 1
    for denominator in range(1, limit + 1):
        # This exact strict-bound formula handles equality without source-style divisibility branching.
        numerator = (numerator_target * denominator - 1) // denominator_target
        if numerator * best_den > best_num * denominator:
            best_num, best_den = numerator, denominator
    return best_num


def problem81_oracle(values: list[int]) -> int:
    if (not 2 <= len(values) <= 6401 or any(type(value) is not int for value in values)):
        return -1
    dimension = values[0]
    if (not 1 <= dimension <= 80 or len(values) != 1 + dimension * dimension
            or any(not 0 <= value <= 9999 for value in values[1:])):
        return -1
    # Keep a full table here, independent of the runner/ports' one-row storage.
    best = [[0] * dimension for _ in range(dimension)]
    offset = 1
    for row in range(dimension):
        for column in range(dimension):
            value = values[offset]
            offset += 1
            if row == 0 and column == 0:
                best[row][column] = value
            elif row == 0:
                best[row][column] = best[row][column - 1] + value
            elif column == 0:
                best[row][column] = best[row - 1][column] + value
            else:
                best[row][column] = min(best[row - 1][column], best[row][column - 1]) + value
    return best[-1][-1]


def problem82_oracle(values: list[int]) -> int:
    """Use multi-source Dijkstra on the up/down/right matrix graph."""
    if (not 3 <= len(values) <= 6402 or any(type(value) is not int for value in values)):
        return -1
    rows, columns = values[:2]
    if (not 1 <= rows <= 80 or not 1 <= columns <= 80
            or len(values) != 2 + rows * columns
            or any(not 0 <= value <= 9999 for value in values[2:])):
        return -1
    costs = values[2:]
    distances = [10**18] * (rows * columns)
    queue = []
    for row in range(rows):
        index = row * columns
        distances[index] = costs[index]
        heapq.heappush(queue, (costs[index], index))
    while queue:
        distance, index = heapq.heappop(queue)
        if distance != distances[index]:
            continue
        row, column = divmod(index, columns)
        neighbors = []
        if row > 0:
            neighbors.append(index - columns)
        if row + 1 < rows:
            neighbors.append(index + columns)
        if column + 1 < columns:
            neighbors.append(index + 1)
        for neighbor in neighbors:
            candidate = distance + costs[neighbor]
            if candidate < distances[neighbor]:
                distances[neighbor] = candidate
                heapq.heappush(queue, (candidate, neighbor))
    return min(distances[row * columns + columns - 1] for row in range(rows))


def problem99_oracle(values: list[int]) -> int:
    if (not 1 <= len(values) <= 2001 or any(type(value) is not int for value in values)):
        return -1
    pair_count = values[0]
    if (not 0 <= pair_count <= 1000 or len(values) != 1 + 2 * pair_count
            or any(not 1 <= values[index] <= 1_000_000 or
                   not 0 <= values[index + 1] <= 1_200_000
                   for index in range(1, len(values), 2))):
        return -1

    best_score, result = 0.0, 0
    for line in range(pair_count):
        base, exponent = values[1 + 2 * line:3 + 2 * line]
        score = exponent * math.log10(base)
        if score > best_score:
            best_score, result = score, line + 1
    return result


def problem102_oracle(values: list[int]) -> int:
    if (not 6 <= len(values) <= 6000 or len(values) % 6 != 0
            or any(type(value) is not int or not -1000 <= value <= 1000 for value in values)):
        return -1
    count = 0
    for offset in range(0, len(values), 6):
        ax, ay, bx, by, cx, cy = values[offset:offset + 6]
        area_twice = (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)
        if area_twice == 0:
            return -1
        edge_signs = (ax * by - ay * bx,
                      bx * cy - by * cx,
                      cx * ay - cy * ax)
        count += all(sign > 0 for sign in edge_signs) or all(sign < 0 for sign in edge_signs)
    return count


def problem107_oracle(values: list[int]) -> int:
    if (not 1 <= len(values) <= 781 or any(type(value) is not int for value in values)):
        return -1
    vertex_count = values[0]
    if (not 1 <= vertex_count <= 40
            or len(values) != 1 + vertex_count * (vertex_count - 1) // 2
            or any(not -1 <= value <= 999 for value in values[1:])):
        return -1
    edges = []
    total_weight = 0
    offset = 1
    for row in range(1, vertex_count):
        for column in range(row):
            weight = values[offset]
            offset += 1
            if weight >= 0:
                edges.append((weight, row, column))
                total_weight += weight
    parent = list(range(vertex_count))
    size = [1] * vertex_count
    def find(vertex: int) -> int:
        while parent[vertex] != vertex:
            parent[vertex] = parent[parent[vertex]]
            vertex = parent[vertex]
        return vertex
    tree_weight = 0
    selected = 0
    for weight, left, right in sorted(edges):
        left_root, right_root = find(left), find(right)
        if left_root == right_root:
            continue
        if size[left_root] < size[right_root]:
            left_root, right_root = right_root, left_root
        parent[right_root] = left_root
        size[left_root] += size[right_root]
        tree_weight += weight
        selected += 1
        if selected == vertex_count - 1:
            break
    if selected != vertex_count - 1:
        return -1
    return total_weight - tree_weight


def oracle(algorithm: str, values: list[int]) -> int:
    if algorithm == "edmonds_blossom_algorithm":
        return edmonds_blossom_oracle(values)
    if algorithm == "primitive_root":
        return primitive_root_oracle(values)
    if algorithm == "dijkstras_two_stack_algorithm":
        return dijkstras_two_stack_oracle(values)
    if algorithm == "wildcard_matching":
        return wildcard_matching_oracle(values)
    if algorithm == "linear_recurrence_matrix":
        return linear_recurrence_matrix_oracle(values)
    if algorithm == "recursive_linear_search":
        return recursive_linear_search_oracle(values)
    if algorithm == "dice_throw":
        return dice_throw_oracle(values)
    if algorithm == "depth_first_search_iterative":
        return depth_first_search_iterative_oracle(values)
    if algorithm == "depth_first_search_recursive":
        return depth_first_search_recursive_oracle(values)
    if algorithm == "elf_hash":
        return elf_hash_oracle(values)
    if algorithm == "is_isomorphic":
        return is_isomorphic_oracle(values)
    if algorithm == "is_graph_bipartite":
        return is_graph_bipartite_oracle(values)
    if algorithm == "karatsuba":
        return karatsuba_oracle(values)
    if algorithm == "good_pairs":
        return good_pairs_oracle(values)
    if algorithm == "good_pairs_hash":
        return good_pairs_hash_oracle(values)
    if algorithm == "find_kth_number":
        return find_kth_number_oracle(values)
    if algorithm == "non_repeating_element":
        return non_repeating_element_oracle(values)
    if algorithm == "in_static_equilibrium":
        return in_static_equilibrium_oracle(values)
    if algorithm == "index_2d_array_in_1d":
        return index_2d_array_in_1d_oracle(values)
    if algorithm == "gas_station":
        return gas_station_oracle(values)
    if algorithm == "find_second_largest_element":
        return find_second_largest_element_oracle(values)
    if algorithm == "second_min_max":
        return second_min_max_oracle(values)
    if algorithm == "constrained_shortest_path":
        return constrained_shortest_path_oracle(values)
    if algorithm == "jump_game":
        return jump_game_oracle(values)
    if algorithm == "pairs_with_given_sum":
        return pairs_with_given_sum_oracle(values)
    if algorithm == "comparison":
        return comparison_oracle(values)
    if algorithm == "count_less_equal_in_sorted_array":
        return count_less_equal_in_sorted_array_oracle(values)
    if algorithm == "lipogram":
        return lipogram_oracle(values)
    if algorithm == "one_bit_difference":
        return one_bit_difference_oracle(values)
    if algorithm == "parse_integer":
        return parse_integer_oracle(values)
    if algorithm == "saddleback_search":
        return saddleback_search_oracle(values)
    if algorithm == "count_singly_linked_list_recursion":
        return count_singly_linked_list_oracle(values)
    if algorithm == "n_in_a_row_board_status":
        return n_in_a_row_board_status_oracle(values)
    if algorithm == "check_cycle":
        return check_cycle_oracle(values)
    if algorithm == "undirected_cycle_check":
        return undirected_cycle_check_oracle(values)
    if algorithm == "count_homogenous":
        return count_homogenous_oracle(values)
    if algorithm == "max_area_of_island":
        return max_area_of_island_oracle(values)
    if algorithm == "directed_dfs_forest_count":
        return directed_dfs_forest_count_oracle(values)
    if algorithm == "set_kth_bit":
        return set_kth_bit_oracle(values)
    if algorithm == "chaining":
        return chaining_oracle(values)
    if algorithm == "ceil_in_binary_search_tree":
        return ceil_in_bst_oracle(values)
    if algorithm == "inorder_successor_of_bst":
        return inorder_successor_of_bst_oracle(values)
    if algorithm == "car_pool":
        return car_pool_oracle(values)
    if algorithm == "burkes_dithering":
        if (not isinstance(values, list) or len(values) < 3
                or len(values) > MAX_BURKES_DITHERING_INPUT_LENGTH
                or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
            return -1
        side, threshold = values[:2]
        if (not 1 <= side <= MAX_BURKES_DITHERING_SIDE or not 1 <= threshold <= 254
                or len(values) != 2 + 3 * side * side
                or any(not 0 <= channel <= 255 for channel in values[2:])):
            return -1
        stride = side + 4
        error_rows = [[0] * stride for _ in range(side + 1)]
        output = 0

        def truncate_division(value: int, divisor: int) -> int:
            quotient = abs(value) // divisor
            return -quotient if value < 0 else quotient

        source_offset = 2
        for y in range(side):
            for x in range(side):
                blue, green, red = values[source_offset:source_offset + 3]
                source_offset += 3
                gray = (114 * blue + 587 * green + 299 * red) // 1000
                adjusted = gray + error_rows[y][x]
                if adjusted < threshold:
                    quantization_error = adjusted
                else:
                    output |= 1 << (y * side + x)
                    quantization_error = adjusted - 255
                error_rows[y][x + 1] += truncate_division(quantization_error, 4)
                error_rows[y][x + 2] += truncate_division(quantization_error, 8)
                error_rows[y + 1][x] += truncate_division(quantization_error, 4)
                error_rows[y + 1][x + 1] += truncate_division(quantization_error, 8)
                error_rows[y + 1][x + 2] += truncate_division(quantization_error, 16)
                if x >= 1:
                    error_rows[y + 1][x - 1] += truncate_division(quantization_error, 8)
                if x >= 2:
                    error_rows[y + 1][x - 2] += truncate_division(quantization_error, 16)
        return output
    if algorithm == "burstballoons":
        return burstballoons_oracle(values)
    if algorithm == "checkequal":
        return checkequal_oracle(values)
    if algorithm == "coinchange":
        return coinchange_oracle(values)
    if algorithm == "celebrity_finder":
        return celebrity_finder_oracle(values)
    if algorithm == "bst_from_sorted_array":
        if (not isinstance(values, list) or len(values) > MAX_BST_FROM_SORTED_ARRAY_VALUES + 1
                or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
                or len(values) > MAX_BST_FROM_SORTED_ARRAY_VALUES
                or any(not BST_FROM_SORTED_ARRAY_I32_MIN <= value <= BST_FROM_SORTED_ARRAY_I32_MAX
                       for value in values)
                or any(values[index - 1] >= values[index] for index in range(1, len(values)))):
            return -1
        shape = 0
        pending = [(0, len(values), 0)]
        while pending:
            start, end, heap_index = pending.pop()
            if start >= end:
                continue
            middle = start + (end - start - 1) // 2
            shape |= 1 << heap_index
            pending.append((middle + 1, end, 2 * heap_index + 2))
            pending.append((start, middle, 2 * heap_index + 1))
        return shape
    if algorithm == "bidirectional_dijkstra":
        return bidirectional_dijkstra_oracle(values)
    if algorithm == "is_valid_email_address":
        return is_valid_email_address_oracle(values)
    if algorithm == "bron_kerbosch":
        if (not isinstance(values, list) or not 1 <= len(values) <= MAX_BRON_KERBOSCH_VERTICES + 2
                or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
            return -1
        vertex_count = values[0]
        if (not 0 <= vertex_count <= MAX_BRON_KERBOSCH_VERTICES
                or len(values) != vertex_count + 1):
            return -1
        vertex_mask = (1 << vertex_count) - 1
        if any(row < 0 or row & ~vertex_mask for row in values[1:]):
            return -1
        adjacency = [values[vertex + 1] & ~(1 << vertex) for vertex in range(vertex_count)]
        for left in range(vertex_count):
            for right in range(left + 1, vertex_count):
                if bool(adjacency[left] & (1 << right)) != bool(adjacency[right] & (1 << left)):
                    return -1
        result = 0
        for clique in range(1 << vertex_count):
            is_clique = True
            for vertex in range(vertex_count):
                bit = 1 << vertex
                if clique & bit and (adjacency[vertex] & clique) != (clique & ~bit):
                    is_clique = False
                    break
            if not is_clique:
                continue
            maximal = True
            for vertex in range(vertex_count):
                bit = 1 << vertex
                if not clique & bit and (adjacency[vertex] & clique) == clique:
                    maximal = False
                    break
            if maximal:
                result |= 1 << clique
        return result
    if algorithm == "brightness":
        return brightness_oracle(values)
    if algorithm == "string_prefix_suffix":
        return string_prefix_suffix_oracle(values)
    if algorithm == "hamming_distance_bytes":
        return hamming_distance_bytes_oracle(values)
    if algorithm == "hamming_distance_strings":
        return hamming_distance_strings_oracle(values)
    if algorithm == "hexa_decimal_to_decimal":
        return hexa_decimal_to_decimal_oracle(values)
    if algorithm == "djb2":
        return djb2_oracle(values)
    if algorithm == "hash_djb2":
        return hash_djb2_oracle(values)
    if algorithm == "hash_xor8":
        return hash_xor8_oracle(values)
    if algorithm == "hex_to_oct":
        return hex_to_oct_oracle(values)
    if algorithm == "grid_get":
        return grid_get_oracle(values)
    if algorithm == "number_of_subarrays_with_odd_sum":
        return odd_sum_subarray_oracle(values)
    if algorithm == "maximum_circular_subarray":
        return maximum_circular_subarray_oracle(values)
    if algorithm == "maximum_product_subarray":
        return maximum_product_subarray_oracle(values)
    if algorithm == "maximum_subarray_int32":
        return maximum_subarray_int32_oracle(values)
    if algorithm == "maximum_subarray_allow_empty":
        return maximum_subarray_allow_empty_oracle(values)
    if algorithm == "median_search":
        return median_search_oracle(values)
    if algorithm == "largest_rectangle_histogram":
        return largest_rectangle_histogram_oracle(values)
    if algorithm == "hamiltonian_path_exists":
        return hamiltonian_path_exists_oracle(values)
    if algorithm == "fast_searcher":
        return fast_searcher_oracle(values)
    if algorithm == "minimum_sum_partition":
        return minimum_sum_partition_oracle(values)
    if algorithm == "upper_bound":
        return upper_bound_oracle(values)
    if algorithm == "pow_logarithmic":
        return pow_logarithmic_oracle(values)
    if algorithm == "longest_subarray_with_sum_at_most":
        return longest_subarray_with_sum_at_most_oracle(values)
    if algorithm == "length_of_last_word":
        return length_of_last_word_oracle(values)
    if algorithm == "find_min_iterator":
        return find_min_iterator_oracle(values)
    if algorithm == "digit_dp":
        return digit_dp_oracle(values)
    if algorithm == "xor_search_missing_number":
        return xor_search_missing_number_oracle(values)
    if algorithm == "maximum_sum_bst":
        return maximum_sum_bst_oracle(values)
    if algorithm == "how_many_times_rotated":
        return how_many_times_rotated_oracle(values)
    if algorithm == "endianness":
        if (not isinstance(values, list) or len(values) > 10
                or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
                or not values):
            return -1
        operation = values[0]
        if operation in (0, 1, 2):
            if len(values) != 2:
                return -1
            value = values[1]
            if operation == 0:
                if not 0 <= value <= 0xffff:
                    return -1
                return int.from_bytes(value.to_bytes(2, "little"), "big")
            if operation == 1:
                if not 0 <= value <= 0xffffffff:
                    return -1
                return int.from_bytes(value.to_bytes(4, "little"), "big")
            bits = value % (1 << 64)
            swapped = int.from_bytes(bits.to_bytes(8, "little"), "big")
            return swapped if swapped <= I64_MAX else swapped - (1 << 64)
        if operation in (3, 4):
            if len(values) < 3:
                return -1
            count, payload = values[1], values[2:]
            if not 1 <= count <= 8 or len(payload) != count or any(not 0 <= byte <= 255 for byte in payload):
                return -1
            result = int.from_bytes(bytes(payload), "little" if operation == 3 else "big")
            return result if result <= I64_MAX else result - (1 << 64)
        if operation in (5, 6):
            if len(values) != 3:
                return -1
            value, count = values[1:]
            if not 1 <= count <= 8 or (count < 8 and (value < 0 or value >= 1 << (8 * count))):
                return -1
            bits = value % (1 << 64)
            raw = bits.to_bytes(8, "little")[:count]
            if operation == 6:
                raw = raw[::-1]
            result = int.from_bytes(raw, "little")
            return result if result <= I64_MAX else result - (1 << 64)
        return -1
    if algorithm == "optimal_string_alignment_distance":
        if (not isinstance(values, list) or not 2 <= len(values) <= 66
                or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
            return -1
        left_length, right_length = values[:2]
        if (not 0 <= left_length <= 32 or not 0 <= right_length <= 32
                or len(values) != 2 + left_length + right_length):
            return -1
        left, right = values[2:2 + left_length], values[2 + left_length:]
        if any(not 0 <= value <= 127 for value in (*left, *right)):
            return -1
        distance = [[0] * (right_length + 1) for _ in range(left_length + 1)]
        for i in range(left_length + 1):
            distance[i][0] = i
        for j in range(right_length + 1):
            distance[0][j] = j
        for i in range(1, left_length + 1):
            for j in range(1, right_length + 1):
                substitution_cost = int(left[i - 1] != right[j - 1])
                distance[i][j] = min(
                    distance[i - 1][j] + 1,
                    distance[i][j - 1] + 1,
                    distance[i - 1][j - 1] + substitution_cost,
                )
                if (i > 1 and j > 1 and left[i - 1] == right[j - 2]
                        and left[i - 2] == right[j - 1]):
                    distance[i][j] = min(
                        distance[i][j], distance[i - 2][j - 2] + substitution_cost
                    )
        return distance[left_length][right_length]
    if algorithm == "egg_dropping":
        return egg_dropping_oracle(values)
    if algorithm == "subarray_sum_equals_k":
        return subarray_sum_equals_k_oracle(values)
    if algorithm == "validate_credit_card":
        if (not 1 <= len(values) <= 66
                or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                       for value in values)):
            return -1
        length = values[0]
        if not 0 <= length <= 64 or len(values) != length + 1:
            return -1
        codepoints = values[1:]
        if any(not 0 <= codepoint <= 127 for codepoint in codepoints):
            return -1
        if not 13 <= length <= 16 or any(not 48 <= codepoint <= 57 for codepoint in codepoints):
            return 0
        first, second = codepoints[0] - 48, codepoints[1] - 48
        if not (first in (4, 5, 6) or (first == 3 and second in (4, 5, 7))):
            return 0
        checksum = 0
        for index, codepoint in enumerate(codepoints):
            digit = codepoint - 48
            if index % 2 == 0:
                digit *= 2
                if digit > 9:
                    digit -= 9
            checksum += digit
        return int(checksum % 10 == 0)
    if algorithm == "number_of_positive_divisors":
        return number_of_positive_divisors_oracle(values)
    if algorithm == "divisors":
        return divisors_oracle(values)
    if algorithm == "modular_exponentiation":
        return modular_exponentiation_oracle(values)
    if algorithm == "modpow":
        return modpow_oracle(values)
    if algorithm == "mode":
        if (not 1 <= len(values) <= 4096
                or any(type(value) is not int or not 0 <= value <= 255 for value in values)):
            return -1
        counts = [0] * 256
        for value in values:
            counts[value] += 1
        maximum = max(counts)
        modes = [value for value, count in enumerate(counts) if count == maximum]
        return modes[0] if len(modes) == 1 else -1
    if algorithm == "n_bonacci":
        if (len(values) != 2 or any(type(value) is not int for value in values)
                or not 1 <= values[0] < values[1] <= 64):
            return -1
        order, count = values
        terms = [0] * count
        terms[order - 1] = 1
        for index in range(order, count):
            terms[index] = sum(terms[max(0, index - order):index])
        return terms[-1]
    if algorithm == "alternate_harmonic_series":
        return alternate_harmonic_series_oracle(values)
    if algorithm == "alternating_harmonic_series":
        return alternating_harmonic_series_oracle(values)
    if algorithm == "lcm_of_n_numbers":
        return lcm_oracle(values)
    if algorithm == "problem18":
        if not values or any(type(value) is not int for value in values):
            return -1
        rows = values[0]
        if (not 1 <= rows <= 15 or len(values) != 1 + rows * (rows + 1) // 2
                or any(not 0 <= value <= 1_000_000 for value in values[1:])):
            return -1
        # Forward path DP differs from the ports' bottom-up in-place fold.
        best = [values[1]]
        offset = 2
        for row in range(1, rows):
            next_best = []
            for column in range(row + 1):
                value = values[offset]
                offset += 1
                parents = []
                if column > 0:
                    parents.append(best[column - 1])
                if column < len(best):
                    parents.append(best[column])
                next_best.append(value + max(parents))
            best = next_best
        return max(best)
    if algorithm == "problem22":
        return problem22_oracle(values)
    if algorithm == "problem54":
        return problem54_oracle(values)
    if algorithm == "problem59":
        return problem59_oracle(values)
    if algorithm == "problem67":
        return problem67_oracle(values)
    if algorithm == "problem71":
        return problem71_oracle(values)
    if algorithm == "problem81":
        return problem81_oracle(values)
    if algorithm == "problem82":
        return problem82_oracle(values)
    if algorithm == "problem99":
        return problem99_oracle(values)
    if algorithm == "problem102":
        return problem102_oracle(values)
    if algorithm == "problem107":
        return problem107_oracle(values)
    if algorithm == "problem345":
        if (not values or any(type(value) is not int for value in values)):
            return -1
        size = values[0]
        if (not 1 <= size <= 15 or len(values) != size * size + 1
                or any(not 0 <= value <= 1000 for value in values[1:])):
            return -1
        matrix = [values[1 + row * size:1 + (row + 1) * size] for row in range(size)]
        best = [-1] * (1 << size)
        best[0] = 0
        for mask in range(1 << size):
            if best[mask] < 0:
                continue
            row = mask.bit_count()
            if row == size:
                continue
            for column in range(size):
                bit = 1 << column
                if not mask & bit:
                    following = mask | bit
                    best[following] = max(best[following], best[mask] + matrix[row][column])
        return best[-1]
    raise ValueError(f"no array-scalar oracle for {algorithm}")


def corpus(algorithm: str, workload: dict) -> tuple[str, int]:
    cases = {tuple(encode_case(case, algorithm)): case["expected_result"]
             for case in workload["cases"]}
    special_records: list[str] = []
    for values, expected in zip((case["input_values"] for case in workload["cases"]),
                                (case["expected_result"] for case in workload["cases"])):
        if oracle(algorithm, values) != expected:
            raise ValueError(f"published workload disagrees with {algorithm} oracle")
    rng = random.Random(20261014)
    if algorithm == "edmonds_blossom_algorithm":
        from itertools import combinations

        for vertex_count in range(6):
            all_edges = list(combinations(range(vertex_count), 2))
            for edge_mask in range(1 << len(all_edges)):
                chosen = [edge for index, edge in enumerate(all_edges) if edge_mask & (1 << index)]
                values = (vertex_count, len(chosen), *(endpoint for edge in chosen for endpoint in edge))
                cases[values] = oracle(algorithm, list(values))
        for _ in range(256):
            vertex_count = rng.randint(0, MAX_EDMONDS_BLOSSOM_VERTICES)
            all_edges = list(combinations(range(vertex_count), 2))
            chosen = [edge for edge in all_edges if rng.randrange(2)]
            values = (vertex_count, len(chosen), *(endpoint for edge in chosen for endpoint in edge))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (0,), (-1, 0), (MAX_EDMONDS_BLOSSOM_VERTICES + 1, 0),
            (1, 1, 0, 0), (2, 1, 0, 2), (2, 1, 0, 1, 1),
            (2, 1, -1, 1), (2, -1), (MAX_EDMONDS_BLOSSOM_VERTICES, MAX_EDMONDS_BLOSSOM_EDGES + 1),
            (2, 1, 0),
        )
        for values in malformed:
            if len(values) <= MAX_EDMONDS_BLOSSOM_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
        special_records.append("NULL 1 -1\n")
    elif algorithm == "dijkstras_two_stack_algorithm":
        for left in range(10):
            for right in range(10):
                for operator in "+-*/":
                    values = tuple(map(ord, f"({left}{operator}{right})"))
                    expected = oracle(algorithm, list(values))
                    if expected != -1_000_000_001:
                        cases[values] = expected

        def random_expression(depth: int) -> str:
            if depth == 0 or rng.randrange(4) == 0:
                return str(rng.randrange(10))
            operator = rng.choice("+-*/")
            return f"({random_expression(depth - 1)}{operator}{random_expression(depth - 1)})"

        for _ in range(512):
            values = tuple(map(ord, random_expression(5)))
            if len(values) <= MAX_DIJKSTRAS_TWO_STACK_INPUT_LENGTH:
                expected = oracle(algorithm, list(values))
                if expected != -1_000_000_001:
                    cases[values] = expected
    elif algorithm == "primitive_root":
        for modulus in range(2, MAX_PRIMITIVE_ROOT_MODULUS + 1):
            values = (modulus,)
            cases[values] = oracle(algorithm, list(values))
        malformed = ((), (0,), (1,), (MAX_PRIMITIVE_ROOT_MODULUS + 1,), (-1,), (2, 3,),
                     (I64_MIN,), (I64_MAX,))
        for values in malformed:
            if len(values) <= MAX_PRIMITIVE_ROOT_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
        special_records.append("NULL 1 -1\n")
    elif algorithm == "wildcard_matching":
        alphabet = (97, 98)
        pattern_alphabet = (97, 98, 42, 63)
        for text_length in range(4):
            for text in product(alphabet, repeat=text_length):
                for pattern_length in range(4):
                    for pattern in product(pattern_alphabet, repeat=pattern_length):
                        values = (text_length, pattern_length, *text, *pattern)
                        cases[values] = oracle(algorithm, list(values))
        for _ in range(256):
            text_length = rng.randint(0, MAX_WILDCARD_MATCHING_TEXT_LENGTH)
            pattern_length = rng.randint(0, MAX_WILDCARD_MATCHING_PATTERN_LENGTH)
            text = tuple(rng.randint(97, 122) for _ in range(text_length))
            pattern = tuple(rng.choice((42, 63, rng.randint(97, 122)))
                            for _ in range(pattern_length))
            values = (text_length, pattern_length, *text, *pattern)
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (0,), (0, 0, 97), (13, 0), (0, 21), (1, 0, 65),
            (0, 1, 46), (0, 1, 42, 97), (1, 1, 97, 46),
            (I64_MIN, 0), (0, I64_MAX),
            (MAX_WILDCARD_MATCHING_TEXT_LENGTH, MAX_WILDCARD_MATCHING_PATTERN_LENGTH,
             *([97] * (MAX_WILDCARD_MATCHING_TEXT_LENGTH - 1)), *([42] * MAX_WILDCARD_MATCHING_PATTERN_LENGTH)),
        )
        for values in malformed:
            if len(values) <= MAX_WILDCARD_MATCHING_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
        special_records.append("NULL 1 -1\n")
    elif algorithm == "inorder_successor_of_bst":
        for node_count in range(MAX_INORDER_SUCCESSOR_OF_BST_NODES + 1):
            keys = tuple(2 * index + 1 for index in range(node_count))
            insertion_orders = (
                keys,
                tuple(reversed(keys)),
                (*keys[::2], *keys[1::2]),
            )
            targets = {1, INORDER_SUCCESSOR_OF_BST_INT32_MAX}
            if keys:
                targets.update((keys[node_count // 2], keys[-1], keys[-1] + 1))
            for insertion_order in insertion_orders:
                for target in targets:
                    values = (node_count, target, *insertion_order)
                    cases[values] = oracle(algorithm, list(values))

        for _ in range(256):
            node_count = rng.randint(0, MAX_INORDER_SUCCESSOR_OF_BST_NODES)
            keys = rng.sample(range(1, 10001), node_count)
            target = (rng.choice(keys) if keys and rng.randrange(2)
                      else rng.randint(1, INORDER_SUCCESSOR_OF_BST_INT32_MAX))
            values = (node_count, target, *keys)
            cases[values] = oracle(algorithm, list(values))

        malformed = (
            (), (1,), (0,), (2, 10, 5), (1, 5, 5, 6),
            (-1, 1), (MAX_INORDER_SUCCESSOR_OF_BST_NODES + 1, 1,
                      *range(1, MAX_INORDER_SUCCESSOR_OF_BST_NODES + 2)),
            (1, 0, 5), (1, -1, 5), (1, INORDER_SUCCESSOR_OF_BST_INT32_MAX + 1, 5),
            (2, 1, 5, 5), (1, 1, 0), (1, 1, -1),
            (1, 1, INORDER_SUCCESSOR_OF_BST_INT32_MAX + 1),
        )
        for values in malformed:
            if len(values) <= MAX_INORDER_SUCCESSOR_OF_BST_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
        special_records.append("NULL 0 -1\n")
    elif algorithm == "linear_recurrence_matrix":
        rng = random.Random(20261016)
        for dimension in range(1, 5):
            for include_constant_or_sum in (0, 1):
                minimum_index = dimension - 1 if include_constant_or_sum else 0
                indices = {minimum_index, dimension, min(1_000_000, dimension + 1), 1_000_000}
                for nth_term in sorted(indices):
                    if nth_term >= minimum_index:
                        matrix = [rng.randrange(0, 1_000_000_007)
                                  for _ in range(dimension * dimension)]
                        base_row = [rng.randrange(0, 1_000_000_007) for _ in range(dimension)]
                        values = (dimension, nth_term, include_constant_or_sum, *matrix, *base_row)
                        cases[values] = oracle(algorithm, list(values))
                for _ in range(64):
                    nth_term = rng.randint(minimum_index, 1_000_000)
                    matrix = [rng.choice((0, 1, 2, 1_000_000_006, rng.randrange(1_000_000_007)))
                              for _ in range(dimension * dimension)]
                    base_row = [rng.choice((0, 1, 2, 1_000_000_006, rng.randrange(1_000_000_007)))
                                for _ in range(dimension)]
                    values = (dimension, nth_term, include_constant_or_sum, *matrix, *base_row)
                    cases[values] = oracle(algorithm, list(values))

        malformed = (
            (), (1,), (1, 0), (1, 0, 0), (1, 0, 0, 1, 2, 3),
            (0, 0, 0), (5, 0, 0), (1, -1, 0, 1, 2), (1, 1_000_001, 0, 1, 2),
            (1, 0, -1, 1, 2), (1, 0, 2, 1, 2),
            (3, 1, 1, 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 1, 1),
            (1, 1, 0, -1, 2), (1, 1, 0, 1_000_000_007, 2),
            (1, 0, 0, 1, -1), (1, 0, 0, 1, 1_000_000_007),
            tuple([4, 0, 0] + [0] * 17),
        )
        for values in malformed:
            if len(values) <= MAX_LINEAR_RECURRENCE_MATRIX_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
        special_records.append("NULL 1 -1\n")
    elif algorithm == "recursive_linear_search":
        for count in (1, 2, 8, MAX_RECURSIVE_LINEAR_SEARCH_COUNT):
            items = tuple(range(count))
            targets = {items[0], items[count // 2], items[-1], MAX_RECURSIVE_LINEAR_SEARCH_VALUE}
            for target in targets:
                values = (count, target, *items)
                cases[values] = oracle(algorithm, list(values))

        for _ in range(128):
            count = rng.randint(1, MAX_RECURSIVE_LINEAR_SEARCH_COUNT)
            items = tuple(rng.sample(
                range(MIN_RECURSIVE_LINEAR_SEARCH_VALUE, MAX_RECURSIVE_LINEAR_SEARCH_VALUE + 1),
                count,
            ))
            target = (rng.choice(items) if rng.randrange(2)
                      else MAX_RECURSIVE_LINEAR_SEARCH_VALUE
                      if MAX_RECURSIVE_LINEAR_SEARCH_VALUE not in items
                      else MIN_RECURSIVE_LINEAR_SEARCH_VALUE)
            values = (count, target, *items)
            cases[values] = oracle(algorithm, list(values))

        malformed = (
            (), (1,), (0, 0), (-1, 0),
            (MAX_RECURSIVE_LINEAR_SEARCH_COUNT + 1, 0,
             *range(MAX_RECURSIVE_LINEAR_SEARCH_COUNT + 1)),
            (MAX_RECURSIVE_LINEAR_SEARCH_COUNT, 0,
             *range(MAX_RECURSIVE_LINEAR_SEARCH_COUNT - 1)),
            (MAX_RECURSIVE_LINEAR_SEARCH_COUNT, 0,
             *range(MAX_RECURSIVE_LINEAR_SEARCH_COUNT + 1)),
            (I64_MIN, 0), (I64_MAX, 0),
        )
        for values in malformed:
            if len(values) <= MAX_RECURSIVE_LINEAR_SEARCH_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
        special_records.append("NULL 1 -1\n")
    elif algorithm == "dice_throw":
        for faces in range(1, MAX_DICE_THROW_FACES + 1):
            for dice in range(1, MAX_DICE_THROW_DICE + 1):
                for target in range(MAX_DICE_THROW_TARGET + 1):
                    values = (faces, dice, target)
                    cases[values] = oracle(algorithm, list(values))
        invalid_cases = (
            (), (6,), (6, 2), (6, 2, 7, 0),
            (0, 1, 1), (MAX_DICE_THROW_FACES + 1, 1, 1),
            (6, 0, 1), (6, MAX_DICE_THROW_DICE + 1, 1),
            (6, 2, -1), (6, 2, MAX_DICE_THROW_TARGET + 1),
            (I64_MIN, 1, 1), (6, I64_MAX, 1), (6, 2, I64_MAX),
        )
        for values in invalid_cases:
            cases[values] = oracle(algorithm, list(values))
    elif algorithm == "depth_first_search_iterative":
        # Exhaust all simple undirected graphs through four vertices and all
        # present/absent target choices; the oracle uses BFS, ports use DFS.
        for vertex_count in range(1, 5):
            possible_edges = [(left, right) for left in range(vertex_count)
                              for right in range(left + 1, vertex_count)]
            for mask in range(1 << len(possible_edges)):
                edges = [edge for index, edge in enumerate(possible_edges) if mask & (1 << index)]
                edge_values = tuple(endpoint for edge in edges for endpoint in edge)
                for source in range(vertex_count):
                    for target in range(-1, vertex_count + 1):
                        values = (vertex_count, len(edges), source, target, *edge_values)
                        cases[values] = oracle(algorithm, list(values))
        for target in (I64_MIN, I64_MAX, 2_147_483_648, 2**53):
            values = (2, 0, 0, target)
            cases[values] = oracle(algorithm, list(values))
        for _ in range(256):
            vertex_count = rng.randrange(1, MAX_DFS_ITERATIVE_VERTICES + 1)
            edge_count = rng.randrange(MAX_DFS_ITERATIVE_EDGES + 1)
            edges = [(rng.randrange(vertex_count), rng.randrange(vertex_count))
                     for _ in range(edge_count)]
            source = rng.randrange(vertex_count)
            target = rng.choice((rng.randrange(vertex_count), -1, vertex_count,
                                 DFS_ITERATIVE_JS_SAFE_INT_MIN, DFS_ITERATIVE_JS_SAFE_INT_MAX))
            values = (vertex_count, edge_count, source, target,
                      *(endpoint for edge in edges for endpoint in edge))
            cases[values] = oracle(algorithm, list(values))
        invalid_cases = (
            (), (2, 0, 0), (0, 0, 0, 0),
            (MAX_DFS_ITERATIVE_VERTICES + 1, 0, 0, 0),
            (1, 0, -1, 0), (1, 0, 1, 0),
            (2, 1, 0, 1, 0, 2), (2, 1, 0, 1, 0),
            (1, 0, 0, 0, 0, 0),
            (MAX_DFS_ITERATIVE_VERTICES, MAX_DFS_ITERATIVE_EDGES + 1, 0, 1,
             *([0, 0] * (MAX_DFS_ITERATIVE_EDGES + 1))),
            tuple([MAX_DFS_ITERATIVE_VERTICES, MAX_DFS_ITERATIVE_EDGES,
                   0, 1, *([0, 1] * MAX_DFS_ITERATIVE_EDGES)] + [0, 0]),
        )
        for values in invalid_cases:
            if len(values) <= MAX_DFS_ITERATIVE_VALID_INPUT_LENGTH + 2:
                cases[values] = oracle(algorithm, list(values))
    elif algorithm == "depth_first_search_recursive":
        for vertex_count in range(1, 6):
            possible_edges = [(left, right) for left in range(vertex_count)
                              for right in range(left + 1, vertex_count)]
            for mask in range(1 << len(possible_edges)):
                edges = [edge for index, edge in enumerate(possible_edges) if mask & (1 << index)]
                edge_values = tuple(endpoint for edge in edges for endpoint in edge)
                for source in range(vertex_count):
                    for target in range(-1, vertex_count + 1):
                        values = (vertex_count, len(edges), source, target, *edge_values)
                        cases[values] = oracle(algorithm, list(values))
        for _ in range(256):
            vertex_count = rng.randint(1, MAX_DFS_RECURSIVE_VERTICES)
            edge_count = rng.randint(0, MAX_DFS_RECURSIVE_EDGES)
            edges = [(rng.randrange(vertex_count), rng.randrange(vertex_count))
                     for _ in range(edge_count)]
            source = rng.randrange(vertex_count)
            target = rng.choice((rng.randrange(vertex_count), -1, vertex_count, I64_MIN, I64_MAX))
            values = (vertex_count, edge_count, source, target,
                      *(endpoint for edge in edges for endpoint in edge))
            cases[values] = oracle(algorithm, list(values))
        malformed = ((), (1,), (0, 0, 0, 0), (MAX_DFS_RECURSIVE_VERTICES + 1, 0, 0, 0),
                     (1, 0, -1, 0), (1, 0, 1, 0), (2, 1, 0, 1, 0, 2),
                     (2, 1, 0, 1, 0),
                     (MAX_DFS_RECURSIVE_VERTICES, MAX_DFS_RECURSIVE_EDGES + 1, 0, 1,
                      *([0, 1] * (MAX_DFS_RECURSIVE_EDGES + 1))),
                     tuple([MAX_DFS_RECURSIVE_VERTICES, MAX_DFS_RECURSIVE_EDGES,
                            0, 1, *([0, 1] * MAX_DFS_RECURSIVE_EDGES)] + [0, 0]))
        for values in malformed:
            if len(values) <= MAX_DFS_RECURSIVE_INPUT_LENGTH:
                cases[values] = DFS_RECURSIVE_INVALID_RESULT
        special_records.append("NULL 1 -1\n")
    elif algorithm == "elf_hash":
        for length in range(3):
            for codepoints in product(range(128), repeat=length):
                values = tuple(codepoints)
                cases[values] = oracle(algorithm, list(values))
        for codepoints in product((0, 1, 15, 16, 63, 64, 126, 127), repeat=3):
            values = tuple(codepoints)
            cases[values] = oracle(algorithm, list(values))
        for length in range(1, MAX_ELF_HASH_VALID_INPUT_LENGTH + 1):
            for values in ((127,) * length, (15,) * length):
                cases[values] = oracle(algorithm, list(values))
        cases[(15,) * 7 + (16,)] = oracle(algorithm, [15] * 7 + [16])
        for _ in range(256):
            length = rng.randint(0, MAX_ELF_HASH_VALID_INPUT_LENGTH)
            values = tuple(rng.randint(0, 127) for _ in range(length))
            cases[values] = oracle(algorithm, list(values))
        for _ in range(64):
            length = rng.randint(1, MAX_ELF_HASH_INPUT_LENGTH)
            alphabet = (-1, 0, 1, 15, 16, 63, 64, 127, 128, 255, I64_MIN, I64_MAX)
            values = tuple(rng.choice(alphabet) for _ in range(length))
            cases[values] = oracle(algorithm, list(values))
        invalid_cases = (
            (), (128,), (-1,), (I64_MIN,), (I64_MAX,),
            (127,) * MAX_ELF_HASH_INPUT_LENGTH,
            (0, 128), (127, -1),
        )
        for values in invalid_cases:
            cases[values] = oracle(algorithm, list(values))
    elif algorithm == "is_isomorphic":
        small_strings = [sequence for length in range(5)
                         for sequence in product((0, 1, 2), repeat=length)]
        for source in small_strings:
            for target in small_strings:
                values = (len(source), len(target), *source, *target)
                cases[values] = oracle(algorithm, list(values))
        for source, target in (
                ((), ()), ((0,), (127,)), ((0, 0), (1, 1)),
                ((0, 1), (1, 0)), ((0, 1), (1, 1)),
                ((0, 1, 0, 2), (4, 5, 4, 6)),
                ((0, 1, 0, 2), (4, 5, 5, 6)),
                ((0, 127, 0, 127), (127, 0, 127, 0)),
        ):
            values = (len(source), len(target), *source, *target)
            cases[values] = oracle(algorithm, list(values))
        for _ in range(256):
            source_length = rng.randint(0, MAX_ISOMORPHIC_CODEPOINTS)
            target_length = rng.randint(0, MAX_ISOMORPHIC_CODEPOINTS)
            source = tuple(rng.randint(0, 127) for _ in range(source_length))
            target = tuple(rng.randint(0, 127) for _ in range(target_length))
            values = (source_length, target_length, *source, *target)
            cases[values] = oracle(algorithm, list(values))
        invalid_cases = (
            (), (0,), (-1, 0), (1, -1),
            (1, 1, 65), (1, 1, 65, 66, 67),
            (1, 1, -1, 65), (1, 1, 128, 65),
            (I64_MIN, 0), (I64_MAX, 0),
            (MAX_ISOMORPHIC_CODEPOINTS + 1, MAX_ISOMORPHIC_CODEPOINTS + 1,
             *([65] * (2 * (MAX_ISOMORPHIC_CODEPOINTS + 1)))),
            (0, 0, 65),
        )
        for values in invalid_cases:
            if len(values) <= MAX_ISOMORPHIC_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
    elif algorithm == "is_graph_bipartite":
        for vertex_count in range(5):
            possible_edges = [(left, right) for left in range(vertex_count)
                              for right in range(left, vertex_count)]
            for mask in range(1 << len(possible_edges)):
                edges = [edge for index, edge in enumerate(possible_edges) if mask & (1 << index)]
                values = (vertex_count, len(edges),
                          *(endpoint + 1 for edge in edges for endpoint in edge))
                cases[values] = oracle(algorithm, list(values))
        for _ in range(256):
            vertex_count = rng.randint(0, MAX_BIPARTITE_VERTICES)
            edge_count = rng.randint(0, MAX_BIPARTITE_EDGES)
            if vertex_count == 0 and edge_count:
                edge_count = 0
            edges = [(rng.randint(1, vertex_count), rng.randint(1, vertex_count))
                     for _ in range(edge_count)]
            values = (vertex_count, edge_count,
                      *(endpoint for edge in edges for endpoint in edge))
            cases[values] = oracle(algorithm, list(values))
        invalid_cases = (
            (), (1,), (-1, 0), (MAX_BIPARTITE_VERTICES + 1, 0),
            (2, -1), (2, MAX_BIPARTITE_EDGES + 1, *([1, 2] * (MAX_BIPARTITE_EDGES + 1))),
            (4, 2, 1, 2), (2, 1, 0, 2), (2, 1, 1, 3),
            (2, 1, I64_MIN, 1), (2, 1, 1, I64_MAX),
            (0, 1, 1, 1), (2, 0, 1),
        )
        for values in invalid_cases:
            if len(values) <= MAX_BIPARTITE_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
    elif algorithm == "karatsuba":
        for left in range(32):
            for right in range(32):
                values = (left, right)
                cases[values] = oracle(algorithm, list(values))
        boundaries = (0, 1, 9, 10, 11, 99, 100, 101, 999, 1000, 1001,
                      9999, 10000, 100000, 999999, MAX_KARATSUBA_OPERAND)
        for left in boundaries:
            for right in boundaries:
                values = (left, right)
                cases[values] = oracle(algorithm, list(values))
        for _ in range(256):
            values = (rng.randint(0, MAX_KARATSUBA_OPERAND),
                      rng.randint(0, MAX_KARATSUBA_OPERAND))
            cases[values] = oracle(algorithm, list(values))
        invalid_cases = (
            (), (0,), (0, 0, 0),
            (-1, 0), (0, -1), (I64_MIN, 1), (1, I64_MIN),
            (MAX_KARATSUBA_OPERAND + 1, 0), (0, MAX_KARATSUBA_OPERAND + 1),
            (I64_MAX, 1), (1, I64_MAX),
        )
        for values in invalid_cases:
            if len(values) <= MAX_KARATSUBA_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
    elif algorithm == "good_pairs":
        for length in range(6):
            for data in product((-1, 0, 1), repeat=length):
                values = (length, *data)
                cases[values] = oracle(algorithm, list(values))

        cases[(MAX_GOOD_PAIRS_N, *([MIN_GOOD_PAIRS_VALUE] * MAX_GOOD_PAIRS_N))] = oracle(
            algorithm, [MAX_GOOD_PAIRS_N, *([MIN_GOOD_PAIRS_VALUE] * MAX_GOOD_PAIRS_N)])
        distinct = tuple(range(MAX_GOOD_PAIRS_N))
        cases[(MAX_GOOD_PAIRS_N, *distinct)] = oracle(
            algorithm, [MAX_GOOD_PAIRS_N, *distinct])
        for _ in range(256):
            length = rng.randrange(MAX_GOOD_PAIRS_N + 1)
            if rng.randrange(2):
                data = tuple(rng.randint(-8, 8) for _ in range(length))
            else:
                data = tuple(rng.randint(MIN_GOOD_PAIRS_VALUE, MAX_GOOD_PAIRS_VALUE)
                             for _ in range(length))
            values = (length, *data)
            cases[values] = oracle(algorithm, list(values))

        invalid_cases = (
            (), (-1,), (MAX_GOOD_PAIRS_N + 1,),
            (3, 1, 1), (1, 0, 0),
            (1, MIN_GOOD_PAIRS_VALUE - 1),
            (1, MAX_GOOD_PAIRS_VALUE + 1),
            (1, I64_MIN), (1, I64_MAX),
            (I64_MIN,), (I64_MAX,),
        )
        for values in invalid_cases:
            if len(values) <= MAX_GOOD_PAIRS_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
    elif algorithm == "good_pairs_hash":
        for length in range(6):
            for data in product((-1, 0, 1), repeat=length):
                values = (length, *data)
                cases[values] = oracle(algorithm, list(values))

        cases[(3, 3, 3, 3)] = oracle(algorithm, [3, 3, 3, 3])
        cases[(MAX_GOOD_PAIRS_HASH_N, *([-MAX_GOOD_PAIRS_HASH_VALUE] * MAX_GOOD_PAIRS_HASH_N))] = oracle(
            algorithm, [MAX_GOOD_PAIRS_HASH_N, *([-MAX_GOOD_PAIRS_HASH_VALUE] * MAX_GOOD_PAIRS_HASH_N)])
        distinct = tuple(range(MAX_GOOD_PAIRS_HASH_N))
        cases[(MAX_GOOD_PAIRS_HASH_N, *distinct)] = oracle(
            algorithm, [MAX_GOOD_PAIRS_HASH_N, *distinct])
        for _ in range(256):
            length = rng.randrange(MAX_GOOD_PAIRS_HASH_N + 1)
            if rng.randrange(2):
                data = tuple(rng.randint(-8, 8) for _ in range(length))
            else:
                data = tuple(rng.randint(-MAX_GOOD_PAIRS_HASH_VALUE, MAX_GOOD_PAIRS_HASH_VALUE)
                             for _ in range(length))
            values = (length, *data)
            cases[values] = oracle(algorithm, list(values))

        invalid_cases = (
            (), (-1,), (MAX_GOOD_PAIRS_HASH_N + 1,),
            (3, 1, 1), (1, 0, 0), (0, 0),
            (1, -MAX_GOOD_PAIRS_HASH_VALUE - 1),
            (1, MAX_GOOD_PAIRS_HASH_VALUE + 1),
            (I64_MIN,), (I64_MAX,),
            (MAX_GOOD_PAIRS_HASH_N + 1, *([0] * (MAX_GOOD_PAIRS_HASH_N + 1))),
        )
        for values in invalid_cases:
            if len(values) <= MAX_GOOD_PAIRS_HASH_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
    elif algorithm == "find_kth_number":
        for length in range(1, 6):
            for data in product((-1, 0, 1), repeat=length):
                for rank in range(1, length + 1):
                    values = (rank, *data)
                    cases[values] = oracle(algorithm, list(values))

        boundary_values = (MIN_FIND_KTH_NUMBER_VALUE, MAX_FIND_KTH_NUMBER_VALUE, 0, -1)
        boundary_data = tuple(boundary_values[index % len(boundary_values)]
                              for index in range(MAX_FIND_KTH_NUMBER_VALUES))
        for rank in (1, MAX_FIND_KTH_NUMBER_VALUES // 2, MAX_FIND_KTH_NUMBER_VALUES):
            values = (rank, *boundary_data)
            cases[values] = oracle(algorithm, list(values))
        all_equal = (MAX_FIND_KTH_NUMBER_VALUES, *([MIN_FIND_KTH_NUMBER_VALUE]
                                                   * MAX_FIND_KTH_NUMBER_VALUES))
        cases[all_equal] = oracle(algorithm, list(all_equal))
        distinct_data = tuple(range(-MAX_FIND_KTH_NUMBER_VALUES // 2,
                                    MAX_FIND_KTH_NUMBER_VALUES // 2))
        for rank in (1, MAX_FIND_KTH_NUMBER_VALUES // 2, MAX_FIND_KTH_NUMBER_VALUES):
            values = (rank, *distinct_data)
            cases[values] = oracle(algorithm, list(values))

        for _ in range(256):
            length = rng.randint(1, MAX_FIND_KTH_NUMBER_VALUES)
            data = tuple(rng.randint(MIN_FIND_KTH_NUMBER_VALUE,
                                     MAX_FIND_KTH_NUMBER_VALUE) for _ in range(length))
            rank = rng.randint(1, length)
            values = (rank, *data)
            cases[values] = oracle(algorithm, list(values))

        invalid_cases = (
            (), (1,), (0, 4, 3), (2, 4), (1, I64_MIN), (1, I64_MAX),
            (1, MIN_FIND_KTH_NUMBER_VALUE - 1),
            (1, MAX_FIND_KTH_NUMBER_VALUE + 1),
            (MAX_FIND_KTH_NUMBER_VALUES + 1, *([0] * MAX_FIND_KTH_NUMBER_VALUES)),
        )
        for values in invalid_cases:
            if len(values) <= MAX_FIND_KTH_NUMBER_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
    elif algorithm == "in_static_equilibrium":
        for count in range(1, 3):
            for components in product((-1, 0, 1), repeat=4 * count):
                values = (count, *components)
                cases[values] = oracle(algorithm, list(values))

        zero_maximum = (MAX_STATIC_EQUILIBRIUM_N,
                        *([0] * (4 * MAX_STATIC_EQUILIBRIUM_N)))
        cases[zero_maximum] = oracle(algorithm, list(zero_maximum))
        for _ in range(128):
            count = rng.randint(1, MAX_STATIC_EQUILIBRIUM_N)
            components = tuple(rng.randint(-MAX_STATIC_EQUILIBRIUM_COMPONENT,
                                           MAX_STATIC_EQUILIBRIUM_COMPONENT)
                               for _ in range(4 * count))
            values = (count, *components)
            cases[values] = oracle(algorithm, list(values))

        invalid_cases = (
            (), (0,), (MAX_STATIC_EQUILIBRIUM_N + 1,),
            (1, 0, 1, 0), (1, MAX_STATIC_EQUILIBRIUM_COMPONENT + 1, 0, 0, 0),
            (1, 0, 0, 0, -MAX_STATIC_EQUILIBRIUM_COMPONENT - 1),
            (I64_MIN,), (I64_MAX,),
        )
        for values in invalid_cases:
            if len(values) <= MAX_STATIC_EQUILIBRIUM_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
    elif algorithm == "gas_station":
        for count in range(MAX_GAS_STATION_STATIONS + 1):
            values = (count, *([0] * (2 * count)))
            cases[values] = oracle(algorithm, list(values))
        rng = random.Random(20261016)
        for _ in range(256):
            count = rng.randint(0, MAX_GAS_STATION_STATIONS)
            values = (count,
                      *(rng.randint(0, 1_000_000) for _ in range(count)),
                      *(rng.randint(0, 1_000_000) for _ in range(count)))
            cases[values] = oracle(algorithm, list(values))
        invalid_cases = ((), (-1,), (129,), (2, 1, 1), (1, -1, 0), (1, 0, 1_000_001),
                         (1, 0, 0, 0), (I64_MIN,), (I64_MAX,))
        for values in invalid_cases:
            if len(values) <= MAX_GAS_STATION_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
    elif algorithm == "find_second_largest_element":
        rng = random.Random(20261016)
        for count in (2, 3, 10, 100, MAX_FIND_SECOND_LARGEST_ELEMENT_VALUES):
            values = (count, *range(FIND_SECOND_LARGEST_ELEMENT_INT32_MIN,
                                    FIND_SECOND_LARGEST_ELEMENT_INT32_MIN + count))
            cases[values] = oracle(algorithm, list(values))
        for _ in range(256):
            count = rng.randint(2, 512)
            items = [rng.randint(FIND_SECOND_LARGEST_ELEMENT_INT32_MIN,
                                 FIND_SECOND_LARGEST_ELEMENT_INT32_MAX)
                     for _ in range(count)]
            items[0] = FIND_SECOND_LARGEST_ELEMENT_INT32_MIN
            items[1] = FIND_SECOND_LARGEST_ELEMENT_INT32_MAX
            values = (count, *items)
            cases[values] = oracle(algorithm, list(values))
        for values in (
            (), (1, 5), (0,), (2, FIND_SECOND_LARGEST_ELEMENT_INT32_MIN,
                               FIND_SECOND_LARGEST_ELEMENT_INT32_MAX + 1),
            (3, 8, 8, 8), (2, 1), (MAX_FIND_SECOND_LARGEST_ELEMENT_VALUES + 1, 0),
            tuple([0] * (MAX_FIND_SECOND_LARGEST_ELEMENT_INPUT_LENGTH + 1)),
        ):
            if len(values) <= MAX_FIND_SECOND_LARGEST_ELEMENT_INPUT_LENGTH:
                cases[values] = FIND_SECOND_LARGEST_ELEMENT_INVALID_RESULT
    elif algorithm == "constrained_shortest_path":
        rng = random.Random(20261016)
        for _ in range(256):
            node_count = rng.randint(1, 16)
            edge_count = rng.randint(0, min(MAX_CONSTRAINED_SHORTEST_PATH_EDGES, 4 * node_count))
            start, target = rng.randrange(node_count), rng.randrange(node_count)
            limit = rng.randint(0, 32)
            edges = []
            for _edge in range(edge_count):
                edges.extend((rng.randrange(node_count), rng.randrange(node_count),
                              rng.randint(0, 1000), rng.randint(1, 32)))
            values = (node_count, edge_count, start, target, limit, *edges)
            cases[values] = oracle(algorithm, list(values))
        for malformed in ((), (1,), (0, 0, 0, 0, 0), (1, 0, 0, 1, 0),
                          (2, 1, 0, 1, 2, 0, 2, 1, 1),
                          (2, 1, 0, 1, 2, 0, 1, 1, 0),
                          tuple([1, 64, 0, 0, 0] + [0] * (4 * 64)),
                          tuple([1] * (MAX_CONSTRAINED_SHORTEST_PATH_INPUT_LENGTH + 1))):
            if len(malformed) <= MAX_CONSTRAINED_SHORTEST_PATH_INPUT_LENGTH:
                cases[malformed] = CONSTRAINED_SHORTEST_PATH_INVALID_RESULT
    elif algorithm == "jump_game":
        for count in (1, 2, 3, 16, 128, MAX_JUMP_GAME_VALUES):
            cases[(count, *([0] * count))] = 0 if count > 1 else 1
            cases[(count, *([MAX_JUMP_GAME_JUMP] * count))] = 1
            cases[(count, *((count - 1,) + (0,) * (count - 1)))] = 1
        rng = random.Random(20261016)
        for _ in range(256):
            count = rng.randint(1, MAX_JUMP_GAME_VALUES)
            values = (count, *(rng.randint(0, min(MAX_JUMP_GAME_JUMP, count))
                               for _ in range(count)))
            cases[values] = oracle(algorithm, list(values))
        for malformed in ((), (0,), (1, -1), (1, MAX_JUMP_GAME_JUMP + 1),
                          (2, 1), (2, 1, 0, 7),
                          (MAX_JUMP_GAME_VALUES + 1, 0),
                          tuple([1] + [0] * MAX_JUMP_GAME_INPUT_LENGTH)):
            if len(malformed) <= MAX_JUMP_GAME_INPUT_LENGTH:
                cases[malformed] = JUMP_GAME_INVALID_RESULT
    elif algorithm == "pairs_with_given_sum":
        rng = random.Random(20261016)
        for count in (0, 1, 2, 3, 16, MAX_PAIRS_WITH_GIVEN_SUM_VALUES):
            values = (rng.randint(-1000, 1000),
                      *(rng.randint(-1000, 1000) for _ in range(count)))
            cases[values] = oracle(algorithm, list(values))
        for _ in range(256):
            count = rng.randint(0, MAX_PAIRS_WITH_GIVEN_SUM_VALUES)
            values = (rng.randint(-2**31, 2**31 - 1),
                      *(rng.randint(-2**31, 2**31 - 1) for _ in range(count)))
            cases[values] = oracle(algorithm, list(values))
        for malformed in ((), (2**31,), (0, 2**31), (0, -2**31 - 1),
                          tuple([0] * (MAX_PAIRS_WITH_GIVEN_SUM_INPUT_LENGTH + 1)),
                          (0, *(0 for _ in range(MAX_PAIRS_WITH_GIVEN_SUM_VALUES + 1)))):
            if len(malformed) <= MAX_PAIRS_WITH_GIVEN_SUM_INPUT_LENGTH + 1:
                cases[malformed] = PAIRS_WITH_GIVEN_SUM_INVALID_RESULT
    elif algorithm == "comparison":
        for _ in range(256):
            left = tuple(rng.randint(1, 127) for _ in range(rng.randint(0, 64)))
            right = tuple(rng.randint(1, 127) for _ in range(rng.randint(0, 64)))
            values = (rng.randrange(2), len(left), *left, len(right), *right)
            cases[values] = oracle(algorithm, list(values))
        over_limit = (0, 64, *([1] * 64), 64, *([1] * 64), 0)
        malformed = ((), (0,), (2, 0, 0), (0, -1, 0), (0, 65), (0, 1, 97),
                     (0, 0, 65), (0, 1, 0, 0), (0, 1, 128, 0), (0, 1, -1, 0),
                     (0, 0, 0, 42), over_limit)
        for values in malformed:
            if len(values) <= MAX_COMPARISON_INPUT_LENGTH + 1:
                cases[values] = oracle(algorithm, list(values))
    elif algorithm == "second_min_max":
        deterministic_arrays = (
            (SECOND_MIN_MAX_INT32_MIN, SECOND_MIN_MAX_INT32_MIN + 1, 0, SECOND_MIN_MAX_INT32_MAX),
            (SECOND_MIN_MAX_INT32_MIN, 0, SECOND_MIN_MAX_INT32_MAX - 1, SECOND_MIN_MAX_INT32_MAX),
            (1, 1, 3, 2, 2),
            (9, 9, 7, 7, 3),
            tuple(range(MAX_SECOND_MIN_MAX_VALUES)),
        )
        for operation in (0, 1):
            for values_array in deterministic_arrays:
                values = (operation, len(values_array), *values_array)
                cases[values] = oracle(algorithm, list(values))
        for _ in range(256):
            operation = rng.randrange(2)
            count = rng.randint(2, MAX_SECOND_MIN_MAX_VALUES)
            values_array = tuple(rng.randint(SECOND_MIN_MAX_INT32_MIN,
                                             SECOND_MIN_MAX_INT32_MAX)
                                 for _ in range(count))
            values = (operation, count, *values_array)
            cases[values] = oracle(algorithm, list(values))
        over_limit = (0, MAX_SECOND_MIN_MAX_VALUES + 1,
                      *([7] * (MAX_SECOND_MIN_MAX_VALUES + 1)))
        malformed = ((), (0,), (2, 2, 0, 1), (0, 1, 7), (0, 3, 1, 2),
                     (1, 2, 1, 2, 3), (0, 2, SECOND_MIN_MAX_INT32_MIN - 1, 0),
                     (1, 2, 0, SECOND_MIN_MAX_INT32_MAX + 1),
                     (0, 4, 7, 7, 7, 7),
                     (0, 2, 0, SECOND_MIN_MAX_INT32_MAX),
                     (1, 2, SECOND_MIN_MAX_INT32_MIN, 0), over_limit)
        for values in malformed:
            if len(values) <= MAX_SECOND_MIN_MAX_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
    elif algorithm == "count_less_equal_in_sorted_array":
        for count in (0, 1, 2, 16, 128, MAX_COUNT_LESS_EQUAL_VALUES):
            values_array = sorted(rng.randint(COUNT_LESS_EQUAL_INT32_MIN,
                                              COUNT_LESS_EQUAL_INT32_MAX)
                                  for _ in range(count))
            key = rng.choice((COUNT_LESS_EQUAL_INT32_MIN, COUNT_LESS_EQUAL_INT32_MAX,
                              0, rng.randint(COUNT_LESS_EQUAL_INT32_MIN,
                                             COUNT_LESS_EQUAL_INT32_MAX)))
            values = (key, *values_array)
            cases[values] = oracle(algorithm, list(values))
        for _ in range(256):
            count = rng.randint(0, MAX_COUNT_LESS_EQUAL_VALUES)
            values_array = sorted(rng.randint(COUNT_LESS_EQUAL_INT32_MIN,
                                              COUNT_LESS_EQUAL_INT32_MAX)
                                  for _ in range(count))
            values = (rng.randint(COUNT_LESS_EQUAL_INT32_MIN,
                                  COUNT_LESS_EQUAL_INT32_MAX), *values_array)
            cases[values] = oracle(algorithm, list(values))
        malformed = ((), (0, COUNT_LESS_EQUAL_INT32_MIN - 1),
                     (COUNT_LESS_EQUAL_INT32_MAX + 1,), (0, 2, 1),
                     (0, *(0 for _ in range(MAX_COUNT_LESS_EQUAL_VALUES + 1))))
        for values in malformed:
            if len(values) <= MAX_COUNT_LESS_EQUAL_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
        special_records.append("NULL 1 -1\n")
    elif algorithm == "one_bit_difference":
        rng = random.Random(20261016)
        bounds = (-(2**31), 2**31 - 1, 0, -1, 1)
        for left in bounds:
            for right in bounds:
                values = (left, right)
                cases[values] = oracle(algorithm, list(values))
        for _ in range(256):
            values = (rng.randint(-(2**31), 2**31 - 1),
                      rng.randint(-(2**31), 2**31 - 1))
            cases[values] = oracle(algorithm, list(values))
        for values in ((), (0,), (0, 1, 2), (2**31, 0), (0, -(2**31) - 1)):
            if len(values) <= MAX_ONE_BIT_DIFFERENCE_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
    elif algorithm == "lipogram":
        for text_length in (0, 1, 2, 26, 128, MAX_LIPOGRAM_TEXT_BYTES):
            text = tuple(rng.choice((*range(65, 91), *range(97, 123),
                                     *sorted(LIPOGRAM_ASCII_WHITESPACE)))
                         for _ in range(text_length))
            seen = 0
            for byte in text:
                if 65 <= byte <= 90:
                    seen |= 1 << (byte - 65)
                elif 97 <= byte <= 122:
                    seen |= 1 << (byte - 97)
            missing = MAX_LIPOGRAM_MISSING_MASK ^ seen
            for mask in (missing, rng.randint(0, MAX_LIPOGRAM_MISSING_MASK)):
                values = (text_length, *text, mask)
                cases[values] = oracle(algorithm, list(values))
        malformed = ((), (0,), (-1, 0), (2, 97, 0), (1, 33, 0), (1, 128, 0),
                     (0, MAX_LIPOGRAM_MISSING_MASK + 1))
        for values in malformed:
            cases[values] = oracle(algorithm, list(values))
        special_records.append("NULL 2 -1\n")
    elif algorithm == "index_2d_array_in_1d":
        for rows in range(1, 5):
            for columns in range(1, 5):
                matrix = tuple(range(rows * columns))
                for index in range(rows * columns):
                    values = (rows, columns, index, *matrix)
                    cases[values] = oracle(algorithm, list(values))

        rng = random.Random(20261016)
        for _ in range(128):
            rows = rng.randint(1, MAX_INDEX_2D_ROWS)
            columns = rng.randint(1, MAX_INDEX_2D_COLUMNS)
            matrix = tuple(rng.randint(0, MAX_INDEX_2D_VALUE) for _ in range(rows * columns))
            index = rng.randrange(rows * columns)
            values = (rows, columns, index, *matrix)
            cases[values] = oracle(algorithm, list(values))

        invalid_cases = ((), (0, 1, 0), (1, 0, 0), (33, 1, 0), (1, 33, 0),
                         (1, 1, -1, 0), (1, 1, 1, 0), (1, 2, 0, 7),
                         (1, 1, 0, -1), (1, 1, 0, MAX_INDEX_2D_VALUE + 1),
                         (1, 1, 0, I64_MIN), (1, 1, 0, I64_MAX))
        for values in invalid_cases:
            if len(values) <= MAX_INDEX_2D_ARRAY_IN_1D_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
    elif algorithm == "non_repeating_element":
        for first, second in product(range(16), repeat=2):
            if first != second:
                values = (first, second)
                cases[values] = oracle(algorithm, list(values))
        for first, second in product(range(8), repeat=2):
            if first == second:
                continue
            for repeated in range(8):
                if repeated in (first, second):
                    continue
                values = (first, second, repeated, repeated)
                cases[values] = oracle(algorithm, list(values))

        maximum_data = [MAX_NON_REPEATING_ELEMENT_VALUE,
                        MAX_NON_REPEATING_ELEMENT_VALUE - 1]
        for value in range(31):
            maximum_data.extend((value, value))
        maximum_input = tuple(maximum_data)
        cases[maximum_input] = oracle(algorithm, list(maximum_input))
        rng = random.Random(20261016)
        for _ in range(256):
            pair_count = rng.randint(0, 31)
            distinct = rng.sample(range(1 << 16), pair_count + 2)
            data = [distinct[0], distinct[1]]
            for value in distinct[2:]:
                data.extend((value, value))
            rng.shuffle(data)
            values = tuple(data)
            cases[values] = oracle(algorithm, list(values))

        invalid_cases = (
            (), (0,), (1, 2, 3), (1, 1), (1, 1, 2, 2),
            (1, 2, 3, 4), (1, 1, 1, 2), (1, 1, 2, 3, 3, 4),
            (-1, 0), (MAX_NON_REPEATING_ELEMENT_VALUE + 1, 0),
            (I64_MIN, 0), (I64_MAX, 0),
        )
        for values in invalid_cases:
            if len(values) <= MAX_NON_REPEATING_ELEMENT_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
    elif algorithm == "parse_integer":
        def packed(text: str) -> tuple[int, ...]:
            return tuple(text.encode("ascii"))

        for text in ("", "0", "1", "9", "+", "-", "+0", "-0", "+42", "-42",
                     "2147483647", "2147483648", "2147483649", "-2147483648",
                     "-2147483649", "4294967295", "4294967296", "99999999999999999999",
                     "9" * MAX_PARSE_INTEGER_INPUT_LENGTH,
                     "-" + "9" * (MAX_PARSE_INTEGER_INPUT_LENGTH - 1)):
            values = packed(text)
            cases[values] = oracle(algorithm, list(values))
        for length in range(4):
            for data in product((32, 43, 45, 48, 49, 57, 97), repeat=length):
                values = tuple(data)
                cases[values] = oracle(algorithm, list(values))
        alphabet = (32, 43, 45, 48, 49, 57, 97, 127, 128, 195)
        for _ in range(256):
            length = rng.randint(1, MAX_PARSE_INTEGER_INPUT_LENGTH)
            values = tuple(rng.choice(alphabet) for _ in range(length))
            cases[values] = oracle(algorithm, list(values))
    elif algorithm == "saddleback_search":
        def packed_matrix(rows: int, columns: int, base: int,
                          row_step: int = 100, column_step: int = 2) -> tuple[int, ...]:
            matrix = tuple(base + row * row_step + column * column_step
                           for row in range(rows) for column in range(columns))
            return (rows, columns, *matrix)

        def add_matrix(rows: int, columns: int, base: int, targets: tuple[int, ...]) -> None:
            matrix_values = packed_matrix(rows, columns, base)
            matrix = matrix_values[2:]
            for target in (*matrix, *targets):
                values = (rows, columns, target, *matrix)
                cases[values] = oracle(algorithm, list(values))

        for rows in range(1, 5):
            for columns in range(1, 5):
                matrix = packed_matrix(rows, columns, -2000)
                cells = matrix[2:]
                add_matrix(rows, columns, -2000, (min(cells) - 1, max(cells) + 1))

        full_matrix = packed_matrix(MAX_SADDLEBACK_SEARCH_ROWS,
                                    MAX_SADDLEBACK_SEARCH_COLUMNS, -10000)
        full_cells = full_matrix[2:]
        for target in (full_cells[0], full_cells[-1], full_cells[16 * 32 + 15],
                       min(full_cells) - 1, max(full_cells) + 1):
            values = (MAX_SADDLEBACK_SEARCH_ROWS, MAX_SADDLEBACK_SEARCH_COLUMNS,
                      target, *full_cells)
            cases[values] = oracle(algorithm, list(values))

        edge_matrix = packed_matrix(4, 5, MIN_SADDLEBACK_SEARCH_VALUE + 100)
        edge_cells = edge_matrix[2:]
        for target in (edge_cells[0], edge_cells[-1], MIN_SADDLEBACK_SEARCH_VALUE,
                       MAX_SADDLEBACK_SEARCH_VALUE):
            values = (4, 5, target, *edge_cells)
            cases[values] = oracle(algorithm, list(values))

        for _ in range(128):
            rows = rng.randint(1, MAX_SADDLEBACK_SEARCH_ROWS)
            columns = rng.randint(1, MAX_SADDLEBACK_SEARCH_COLUMNS)
            base = rng.randint(-1_000_000, 1_000_000)
            matrix_values = packed_matrix(rows, columns, base)
            matrix = matrix_values[2:]
            target = rng.choice(matrix) if rng.randrange(2) else rng.randint(-1_000_000, 1_000_000)
            values = (rows, columns, target, *matrix)
            cases[values] = oracle(algorithm, list(values))

        invalid_cases = (
            (), (1,), (0, 1, 0), (1, 0, 0),
            (MAX_SADDLEBACK_SEARCH_ROWS + 1, 1, 0),
            (1, MAX_SADDLEBACK_SEARCH_COLUMNS + 1, 0),
            (1, 1, MAX_SADDLEBACK_SEARCH_VALUE + 1, 0),
            (1, 1, 0, MIN_SADDLEBACK_SEARCH_VALUE - 1),
            (1, 1, 0), (1, 1, 0, 0),
        )
        for values in invalid_cases:
            if len(values) <= MAX_SADDLEBACK_SEARCH_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
    if algorithm == "ceil_in_binary_search_tree":
        rng = random.Random(20261016)

        def packed_tree(insertion_order: list[int], key: int) -> list[int]:
            nodes: list[list[int]] = []
            root = -1
            for value in insertion_order:
                if root == -1:
                    root = 0
                    nodes.append([value, -1, -1])
                    continue
                current = root
                while True:
                    child_slot = 1 if value < nodes[current][0] else 2
                    child = nodes[current][child_slot]
                    if child == -1:
                        nodes[current][child_slot] = len(nodes)
                        nodes.append([value, -1, -1])
                        break
                    current = child
            return [len(nodes), root, key, *(field for node in nodes for field in node)]

        cases[tuple(packed_tree([], 0))] = oracle(algorithm, packed_tree([], 0))
        for size in range(1, 18):
            values = [value * 3 - size for value in range(size)]
            orders = (values, list(reversed(values)), values[::2] + values[1::2])
            shuffled = values[:]
            rng.shuffle(shuffled)
            orders += (shuffled,)
            queries = sorted(set((values[0] - 1, values[-1] + 1, *values,
                                  -100, -1, 0, 1, 100)))
            for order in orders:
                for key in queries:
                    packed = packed_tree(order, key)
                    cases[tuple(packed)] = oracle(algorithm, packed)

        import itertools
        small_sets = [combination for size in range(1, 5)
                      for combination in itertools.combinations(range(-3, 4), size)]
        for values in small_sets:
            for order in (list(values), list(reversed(values))):
                for key in range(-4, 5):
                    packed = packed_tree(order, key)
                    cases[tuple(packed)] = oracle(algorithm, packed)
        minimum_value = -(MAX_CEIL_IN_BST_NODES // 2)
        maximum_values = list(range(minimum_value, minimum_value + MAX_CEIL_IN_BST_NODES))
        for order in (maximum_values, list(reversed(maximum_values)),
                      maximum_values[::2] + maximum_values[1::2]):
            for key in (-64, -1, 0, 1, 64):
                packed = packed_tree(order, key)
                cases[tuple(packed)] = oracle(algorithm, packed)
        invalid_cases = (
            [], [0, -1], [0, 0, 0], [1, -1, 0, 5, -1, -1],
            [1, 0, 1], [1, 0, 1, 5, 1, -1],
            [1, 0, 1, 1_000_001, -1, -1], [1, 0, 1, 5, 0, -1],
            [128, 0, 0], [-1, 0, 0], [1, 0, -1_000_001, 5, -1, -1],
        )
        for values in invalid_cases:
            cases[tuple(values)] = oracle(algorithm, list(values))

    if algorithm == "car_pool":
        intervals = [(passengers, origin, destination)
                     for passengers in (1, 2)
                     for origin in range(3)
                     for destination in range(origin + 1, 4)]
        for left_index, left in enumerate(intervals):
            for right in intervals[left_index:]:
                for capacity in range(5):
                    values = [capacity, 2, *left, *right]
                    cases[tuple(values)] = oracle(algorithm, values)
        for _ in range(512):
            trip_count = rng.randrange(MAX_CAR_POOL_TRIPS + 1)
            values = [rng.randrange(1001), trip_count]
            for _ in range(trip_count):
                origin = rng.randrange(1000)
                destination = rng.randrange(origin + 1, 1001)
                values.extend((rng.randrange(1, 1001), origin, destination))
            cases[tuple(values)] = oracle(algorithm, values)
        maximum = [1000, MAX_CAR_POOL_TRIPS]
        for trip in range(MAX_CAR_POOL_TRIPS):
            maximum.extend((1, trip, trip + 1))
        cases[tuple(maximum)] = oracle(algorithm, maximum)
        for values in (
            [], [10], [10, -1], [10, 1], [10, 0, 1],
            [10, 1, 0, 4, 4], [10, 1, -1, 0, 1],
            [10, 1, 1, -1, 1], [10, 1, 1, 0, 1001],
            [1001, 0], [0, 65], [0, 0, 1],
        ):
            cases[tuple(values)] = oracle(algorithm, list(values))
    elif algorithm == "burkes_dithering":
        import itertools
        palette = (0, 80, 127, 128, 255)
        for grayscale_values in itertools.product(palette, repeat=4):
            values = [2, 128]
            for gray in grayscale_values:
                values.extend((gray, gray, gray))
            cases[tuple(values)] = oracle(algorithm, values)
        for _ in range(160):
            side = rng.randrange(1, MAX_BURKES_DITHERING_SIDE + 1)
            values = [side, rng.randrange(1, 255)]
            values.extend(rng.randrange(256) for _ in range(3 * side * side))
            cases[tuple(values)] = oracle(algorithm, values)
        invalid_cases = (
            [0, 128], [8, 128, *([0] * (3 * 8 * 8))],
            [1, 0, 0, 0, 0], [1, 255, 0, 0, 0],
            [1, 128, 0, 0], [1, 128, -1, 0, 0], [1, 128, 256, 0, 0],
        )
        for values in invalid_cases:
            cases[tuple(values)] = oracle(algorithm, values)
    elif algorithm == "bst_from_sorted_array":
        for length in range(MAX_BST_FROM_SORTED_ARRAY_VALUES + 1):
            for start in (-100, -7, 0, 100):
                values = [start + 2 * index for index in range(length)]
                cases[tuple(values)] = oracle(algorithm, values)
        for _ in range(256):
            length = rng.randrange(MAX_BST_FROM_SORTED_ARRAY_VALUES + 1)
            values = sorted(rng.sample(range(-10_000, 10_001), length))
            cases[tuple(values)] = oracle(algorithm, values)
        invalid_cases = (
            list(range(MAX_BST_FROM_SORTED_ARRAY_VALUES + 1)),
            [0, 0], [2, 1], [BST_FROM_SORTED_ARRAY_I32_MIN - 1],
            [BST_FROM_SORTED_ARRAY_I32_MAX + 1],
            [BST_FROM_SORTED_ARRAY_I32_MIN, BST_FROM_SORTED_ARRAY_I32_MAX,
             BST_FROM_SORTED_ARRAY_I32_MAX + 1],
        )
        for values in invalid_cases:
            cases[tuple(values)] = oracle(algorithm, values)
    elif algorithm == "bidirectional_dijkstra":
        # Exhaust all directed simple graphs on up to two vertices with weights 0/1.
        for vertex_count in (1, 2):
            possible_edges = [(origin, destination)
                              for origin in range(vertex_count)
                              for destination in range(vertex_count)]
            for edge_states in product((-1, 0, 1), repeat=len(possible_edges)):
                edges = [(origin, destination, weight)
                         for (origin, destination), weight in zip(possible_edges, edge_states)
                         if weight >= 0]
                for source in range(vertex_count):
                    for target in range(vertex_count):
                        values = [vertex_count, len(edges), source, target]
                        for edge in edges:
                            values.extend(edge)
                        cases[tuple(values)] = oracle(algorithm, values)
        for _ in range(256):
            vertex_count = rng.randrange(1, 17)
            edge_count = rng.randrange(0, 49)
            values = [vertex_count, edge_count, rng.randrange(vertex_count), rng.randrange(vertex_count)]
            for _ in range(edge_count):
                values.extend((rng.randrange(vertex_count), rng.randrange(vertex_count),
                               rng.randrange(1_000_001)))
            cases[tuple(values)] = oracle(algorithm, values)
        for values in ([], [1], [1, 0, 0, 0], [0, 0, 0, 0],
                       [1, -1, 0, 0], [1, 1, 0, 0], [1, 0, 1, 0],
                       [1, 1, 0, 0, 0, 1, 1], [1, 1, 0, 0, 0, 0, -1],
                       [1, 1, 0, 0, 0, 0, 1_000_001],
                       [65, 0, 0, 0], [1, 257, 0, 0]):
            cases[tuple(values)] = oracle(algorithm, list(values))
    elif algorithm == "burstballoons":
        # Exhaust small arrays over a compact alphabet, then vary order and scale.
        for length in range(6):
            for values in product((0, 1, 3), repeat=length):
                cases[values] = oracle(algorithm, list(values))
        for _ in range(192):
            length = rng.randrange(0, 33)
            values = tuple(rng.randrange(0, 1001) for _ in range(length))
            cases[values] = oracle(algorithm, list(values))
        cases[tuple([0] * 128)] = oracle(algorithm, [0] * 128)
        for values in ((), (0,), (1000,), (-1,), (1001,), (0, -1, 1),
                       tuple([1] * 129)):
            cases[values] = oracle(algorithm, list(values))
    elif algorithm == "checkequal":
        matrices = []
        for rows, columns in product(range(3), repeat=2):
            for entries in product((0, 1), repeat=rows * columns):
                matrices.append((rows, columns, entries))
        for rows_a, columns_a, entries_a in matrices:
            for rows_b, columns_b, entries_b in matrices:
                values = (rows_a, columns_a, rows_b, columns_b, *entries_a, *entries_b)
                cases[values] = oracle(algorithm, list(values))

        for _ in range(128):
            rows_a, columns_a = rng.randrange(9), rng.randrange(9)
            rows_b, columns_b = rng.randrange(9), rng.randrange(9)
            entries_a = tuple(rng.choice((I64_MIN, -1, 0, 1, I64_MAX))
                              for _ in range(rows_a * columns_a))
            entries_b = tuple(rng.choice((I64_MIN, -1, 0, 1, I64_MAX))
                              for _ in range(rows_b * columns_b))
            values = (rows_a, columns_a, rows_b, columns_b, *entries_a, *entries_b)
            cases[values] = oracle(algorithm, list(values))
    elif algorithm == "coinchange":
        for amount in range(1, 9):
            for coin_count in range(4):
                for coins in product(range(1, 5), repeat=coin_count):
                    values = (amount, coin_count, *coins)
                    cases[values] = oracle(algorithm, list(values))
        for _ in range(256):
            amount = rng.randrange(1, 31)
            coin_count = rng.randrange(0, 9)
            coins = tuple(rng.randrange(1, 31) for _ in range(coin_count))
            values = (amount, coin_count, *coins)
            cases[values] = oracle(algorithm, list(values))
        for values in ((), (1,), (0, 0), (31, 0), (3, -1), (3, 9),
                       (3, 2, 1), (3, 0, 2), (3, 1, 0), (3, 1, -1),
                       (3, 1, 31)):
            cases[values] = oracle(algorithm, list(values))
    elif algorithm == "set_kth_bit":
        for number in range(128):
            for bit_position in range(8):
                values = (number, bit_position)
                cases[values] = oracle(algorithm, list(values))
        for number in (0, 1, 2**30 - 1, 2**30, 2_147_483_647):
            for bit_position in (0, 1, 15, 29, 30):
                values = (number, bit_position)
                cases[values] = oracle(algorithm, list(values))
        for _ in range(256):
            values = (rng.randrange(2_147_483_648), rng.randrange(31))
            cases[values] = oracle(algorithm, list(values))
        invalid_cases = (
            (), (5,), (5, 2, 1), (-1, 2), (2_147_483_648, 2),
            (5, -1), (5, 31), (I64_MIN, 0), (I64_MAX, 0),
        )
        for values in invalid_cases:
            cases[values] = oracle(algorithm, list(values))
    elif algorithm == "directed_dfs_forest_count":
        rng = random.Random(20261016)
        source_demos = (
            (9, 0, 1, 0, 2, 1, 2, 1, 3, 3, 4, 4, 0, 5, 6, 5, 7, 8, 8),
            (7, 0, 1, 1, 2, 1, 3, 2, 4, 5, 6, 6, 7, 7, 6),
        )
        edge_order_cases = (
            (2, 0, 1, 2, 0),
            (2, 2, 0, 0, 1),
            (2, 0, 2, 1, 2),
            (3, 0, 0, 1, 1, 0, 1),
            (3, 4, 4, 4, 4, 4, 4),
            (3, 0, 1, 0, 1, 1, 2),
            (0,),
        )
        for values in (*source_demos, *edge_order_cases):
            cases[values] = oracle(algorithm, list(values))
        for _ in range(256):
            edge_count = rng.randint(0, MAX_DIRECTED_DFS_FOREST_COUNT_EDGES)
            edges = tuple(rng.randint(0, MAX_DIRECTED_DFS_FOREST_COUNT_VERTEX_ID)
                          for _ in range(2 * edge_count))
            values = (edge_count, *edges)
            cases[values] = oracle(algorithm, list(values))
        maximum_edges = (MAX_DIRECTED_DFS_FOREST_COUNT_EDGES,
                         *(index % (MAX_DIRECTED_DFS_FOREST_COUNT_VERTEX_ID + 1)
                           for index in range(2 * MAX_DIRECTED_DFS_FOREST_COUNT_EDGES)))
        cases[maximum_edges] = oracle(algorithm, list(maximum_edges))
        maximum_self_loop_identities = (
            MAX_DIRECTED_DFS_FOREST_COUNT_EDGES,
            *(endpoint for vertex in range(MAX_DIRECTED_DFS_FOREST_COUNT_VERTEX_ID + 1)
              for endpoint in (vertex, vertex)),
        )
        cases[maximum_self_loop_identities] = oracle(algorithm, list(maximum_self_loop_identities))
        invalid_cases = (
            (), (0, 0), (1,), (1, 0), (1, 0, 1, 0), (-1,),
            (MAX_DIRECTED_DFS_FOREST_COUNT_EDGES + 1,),
            (1, -1, 0), (1, 0, MAX_DIRECTED_DFS_FOREST_COUNT_VERTEX_ID + 1),
            (2, 0, 1), (I64_MIN,), (I64_MAX,),
            tuple([0] * (MAX_DIRECTED_DFS_FOREST_COUNT_INPUT_LENGTH + 1)),
        )
        for values in invalid_cases:
            if len(values) <= MAX_DIRECTED_DFS_FOREST_COUNT_INPUT_LENGTH + 1:
                cases[values] = DIRECTED_DFS_FOREST_COUNT_INVALID_RESULT
    elif algorithm == "max_area_of_island":
        for rows in range(3):
            for columns in range(3):
                for cells in product((0, 1), repeat=rows * columns):
                    values = (rows, columns, *cells)
                    cases[values] = oracle(algorithm, list(values))
        for _ in range(256):
            rows = rng.randrange(MAX_MAX_AREA_OF_ISLAND_ROWS + 1)
            columns = rng.randrange(MAX_MAX_AREA_OF_ISLAND_COLUMNS + 1)
            cells = tuple(rng.randrange(2) for _ in range(rows * columns))
            values = (rows, columns, *cells)
            cases[values] = oracle(algorithm, list(values))
        all_land = (MAX_MAX_AREA_OF_ISLAND_ROWS, MAX_MAX_AREA_OF_ISLAND_COLUMNS,
                    *([1] * (MAX_MAX_AREA_OF_ISLAND_ROWS * MAX_MAX_AREA_OF_ISLAND_COLUMNS)))
        checkerboard = (MAX_MAX_AREA_OF_ISLAND_ROWS, MAX_MAX_AREA_OF_ISLAND_COLUMNS,
                        *(int((row + column) % 2 == 0)
                          for row in range(MAX_MAX_AREA_OF_ISLAND_ROWS)
                          for column in range(MAX_MAX_AREA_OF_ISLAND_COLUMNS)))
        cases[all_land] = oracle(algorithm, list(all_land))
        cases[checkerboard] = oracle(algorithm, list(checkerboard))
        invalid_cases = (
            (), (1,), (-1, 1), (MAX_MAX_AREA_OF_ISLAND_ROWS + 1, 1),
            (1, -1), (1, MAX_MAX_AREA_OF_ISLAND_COLUMNS + 1),
            (2, 2, 1, 1, 1), (1, 1, 0, 0), (1, 1, 2), (1, 1, -1),
            (I64_MIN, 0), (0, I64_MAX),
        )
        for values in invalid_cases:
            cases[values] = oracle(algorithm, list(values))
    elif algorithm == "count_homogenous":
        for length in range(5):
            for payload in product((0, 65, 97, 127), repeat=length):
                values = (length, *payload)
                cases[values] = oracle(algorithm, list(values))
        for length in (1, 2, 17, MAX_COUNT_HOMOGENOUS_BYTES - 1, MAX_COUNT_HOMOGENOUS_BYTES):
            repeated = (length, *([97] * length))
            alternating = (length, *(65 if index % 2 == 0 else 97 for index in range(length)))
            cases[repeated] = oracle(algorithm, list(repeated))
            cases[alternating] = oracle(algorithm, list(alternating))
        for _ in range(512):
            length = rng.randrange(MAX_COUNT_HOMOGENOUS_BYTES + 1)
            values = (length, *(rng.randrange(128) for _ in range(length)))
            cases[values] = oracle(algorithm, list(values))
        invalid_cases = (
            (), (0, 0), (-1,), (MAX_COUNT_HOMOGENOUS_BYTES + 1,), (1,),
            (0, 65), (1, 65, 66), (1, -1), (1, 128), (2, 65),
            (MAX_COUNT_HOMOGENOUS_BYTES, 65),
            (MAX_COUNT_HOMOGENOUS_INPUT_LENGTH,
             *([97] * (MAX_COUNT_HOMOGENOUS_INPUT_LENGTH - 1))),
        )
        for values in invalid_cases:
            cases[values] = oracle(algorithm, list(values))
    elif algorithm == "check_cycle":
        for vertex_count in range(4):
            possible_edges = [(origin, destination)
                              for origin in range(vertex_count)
                              for destination in range(vertex_count)]
            for edge_mask in range(1 << len(possible_edges)):
                edges = tuple(edge for index, edge in enumerate(possible_edges)
                              if edge_mask & (1 << index))
                values = (vertex_count, len(edges), *(endpoint for edge in edges for endpoint in edge))
                cases[values] = oracle(algorithm, list(values))
        for _ in range(512):
            vertex_count = rng.randrange(MAX_CHECK_CYCLE_VERTICES + 1)
            edge_count = rng.randrange(MAX_CHECK_CYCLE_EDGES + 1) if vertex_count else 0
            edges = tuple((rng.randrange(vertex_count), rng.randrange(vertex_count))
                          for _ in range(edge_count))
            values = (vertex_count, edge_count, *(endpoint for edge in edges for endpoint in edge))
            cases[values] = oracle(algorithm, list(values))
        chain_edges = tuple((vertex, vertex + 1) for vertex in range(MAX_CHECK_CYCLE_VERTICES - 1))
        chain = (MAX_CHECK_CYCLE_VERTICES, len(chain_edges),
                 *(endpoint for edge in chain_edges for endpoint in edge))
        cases[chain] = oracle(algorithm, list(chain))
        disconnected_cycle_edges = ((0, 1), (1, 2), (5, 6), (6, 5))
        disconnected_cycle = (8, len(disconnected_cycle_edges),
                              *(endpoint for edge in disconnected_cycle_edges for endpoint in edge))
        cases[disconnected_cycle] = oracle(algorithm, list(disconnected_cycle))
        maximum_edges = tuple((origin, destination) for origin in range(16) for destination in range(16))
        dense_cycle = (16, len(maximum_edges),
                       *(endpoint for edge in maximum_edges for endpoint in edge))
        cases[dense_cycle] = oracle(algorithm, list(dense_cycle))
        invalid_cases = (
            (), (0,), (-1, 0), (MAX_CHECK_CYCLE_VERTICES + 1, 0),
            (0, 1, 0, 0), (1, -1), (1, MAX_CHECK_CYCLE_EDGES + 1),
            (1, 1), (1, 1, 0), (1, 1, 0, 1), (1, 1, -1, 0),
            (1, MAX_CHECK_CYCLE_EDGES + 1,
             *([0, 0] * (MAX_CHECK_CYCLE_EDGES + 1))),
        )
        for values in invalid_cases:
            cases[values] = oracle(algorithm, list(values))
    elif algorithm == "undirected_cycle_check":
        for vertex_count in range(6):
            possible_edges = [(left, right)
                              for left in range(vertex_count)
                              for right in range(left, vertex_count)]
            for edge_mask in range(1 << len(possible_edges)):
                edges = tuple(edge for index, edge in enumerate(possible_edges)
                              if edge_mask & (1 << index))
                values = (vertex_count, len(edges), *(endpoint for edge in edges for endpoint in edge))
                cases[values] = oracle(algorithm, list(values))
        rng = random.Random(0xC1C1E)
        for _ in range(512):
            vertex_count = rng.randrange(MAX_UNDIRECTED_CYCLE_CHECK_VERTICES + 1)
            possible_edges = [(left, right)
                              for left in range(vertex_count)
                              for right in range(left, vertex_count)]
            rng.shuffle(possible_edges)
            edge_count = rng.randrange(min(MAX_UNDIRECTED_CYCLE_CHECK_EDGES, len(possible_edges)) + 1)
            edges = tuple(possible_edges[:edge_count])
            values = (vertex_count, len(edges), *(endpoint for edge in edges for endpoint in edge))
            cases[values] = oracle(algorithm, list(values))
        maximum_tree_edges = tuple((vertex, vertex + 1)
                                   for vertex in range(MAX_UNDIRECTED_CYCLE_CHECK_VERTICES - 1))
        maximum_tree = (MAX_UNDIRECTED_CYCLE_CHECK_VERTICES, len(maximum_tree_edges),
                        *(endpoint for edge in maximum_tree_edges for endpoint in edge))
        cases[maximum_tree] = oracle(algorithm, list(maximum_tree))
        dense_edges = tuple((left, right)
                            for left in range(MAX_UNDIRECTED_CYCLE_CHECK_VERTICES)
                            for right in range(left, MAX_UNDIRECTED_CYCLE_CHECK_VERTICES))[:MAX_UNDIRECTED_CYCLE_CHECK_EDGES]
        dense_graph = (MAX_UNDIRECTED_CYCLE_CHECK_VERTICES, len(dense_edges),
                       *(endpoint for edge in dense_edges for endpoint in edge))
        cases[dense_graph] = oracle(algorithm, list(dense_graph))
        invalid_cases = (
            (), (0,), (-1, 0), (MAX_UNDIRECTED_CYCLE_CHECK_VERTICES + 1, 0),
            (0, 1, 0, 0), (1, -1), (1, MAX_UNDIRECTED_CYCLE_CHECK_EDGES + 1),
            (1, 1), (1, 1, 0), (1, 1, 0, 1), (1, 1, -1, 0),
            (2, 2, 0, 1, 1, 0),
            (0, 0, *([0] * (MAX_UNDIRECTED_CYCLE_CHECK_INPUT_LENGTH - 1))),
            (1, MAX_UNDIRECTED_CYCLE_CHECK_EDGES + 1,
             *([0, 0] * (MAX_UNDIRECTED_CYCLE_CHECK_EDGES + 1))),
        )
        for values in invalid_cases:
            cases[values] = oracle(algorithm, list(values))
    elif algorithm == "count_singly_linked_list_recursion":
        for node_count in range(MAX_COUNT_SINGLY_LINKED_LIST_NODES + 1):
            for payload in (0, COUNT_SINGLY_LINKED_LIST_I32_MIN, COUNT_SINGLY_LINKED_LIST_I32_MAX):
                values = (node_count, *([payload] * node_count))
                cases[values] = oracle(algorithm, list(values))
        for _ in range(512):
            node_count = rng.randrange(MAX_COUNT_SINGLY_LINKED_LIST_NODES + 1)
            values = (node_count,
                      *(rng.randint(COUNT_SINGLY_LINKED_LIST_I32_MIN,
                                    COUNT_SINGLY_LINKED_LIST_I32_MAX)
                        for _ in range(node_count)))
            cases[values] = oracle(algorithm, list(values))
        invalid_cases = (
            (), (-1,), (I64_MIN,), (I64_MAX,), (1,), (0, 0),
            (MAX_COUNT_SINGLY_LINKED_LIST_NODES + 1,
             *([0] * (MAX_COUNT_SINGLY_LINKED_LIST_NODES + 1))),
            (1, COUNT_SINGLY_LINKED_LIST_I32_MIN - 1),
            (1, COUNT_SINGLY_LINKED_LIST_I32_MAX + 1),
            (MAX_COUNT_SINGLY_LINKED_LIST_NODES,
             *([0] * (MAX_COUNT_SINGLY_LINKED_LIST_NODES - 1))),
            (MAX_COUNT_SINGLY_LINKED_LIST_NODES,
             *([0] * (MAX_COUNT_SINGLY_LINKED_LIST_NODES + 1))),
        )
        for values in invalid_cases:
            cases[values] = oracle(algorithm, list(values))
    elif algorithm == "n_in_a_row_board_status":
        for player in (1, 2):
            for cells in product((0, 1, 2), repeat=4):
                values = (2, player, *cells)
                cases[values] = oracle(algorithm, list(values))
        for _ in range(512):
            size = rng.randrange(2, MAX_N_IN_A_ROW_BOARD_SIZE + 1)
            player = rng.randrange(1, 3)
            values = (size, player, *(rng.randrange(3) for _ in range(size * size)))
            cases[values] = oracle(algorithm, list(values))
        for player in (1, 2):
            row_cells = [0] * (MAX_N_IN_A_ROW_BOARD_SIZE ** 2)
            row_cells[:MAX_N_IN_A_ROW_BOARD_SIZE] = [player] * MAX_N_IN_A_ROW_BOARD_SIZE
            row_win = (MAX_N_IN_A_ROW_BOARD_SIZE, player, *row_cells)
            cases[row_win] = oracle(algorithm, list(row_win))
            column_cells = [0] * (MAX_N_IN_A_ROW_BOARD_SIZE ** 2)
            for row in range(MAX_N_IN_A_ROW_BOARD_SIZE):
                column_cells[row * MAX_N_IN_A_ROW_BOARD_SIZE + MAX_N_IN_A_ROW_BOARD_SIZE // 2] = player
            column_win = (MAX_N_IN_A_ROW_BOARD_SIZE, player, *column_cells)
            cases[column_win] = oracle(algorithm, list(column_win))
            main_diagonal_cells = [0] * (MAX_N_IN_A_ROW_BOARD_SIZE ** 2)
            anti_diagonal_cells = [0] * (MAX_N_IN_A_ROW_BOARD_SIZE ** 2)
            for index in range(MAX_N_IN_A_ROW_BOARD_SIZE):
                main_diagonal_cells[index * MAX_N_IN_A_ROW_BOARD_SIZE + index] = player
                anti_diagonal_cells[index * MAX_N_IN_A_ROW_BOARD_SIZE
                                    + MAX_N_IN_A_ROW_BOARD_SIZE - 1 - index] = player
            main_diagonal_win = (MAX_N_IN_A_ROW_BOARD_SIZE, player, *main_diagonal_cells)
            anti_diagonal_win = (MAX_N_IN_A_ROW_BOARD_SIZE, player, *anti_diagonal_cells)
            cases[main_diagonal_win] = oracle(algorithm, list(main_diagonal_win))
            cases[anti_diagonal_win] = oracle(algorithm, list(anti_diagonal_win))
        draw_cells = [1 if (row + column) % 2 == 0 else 2
                      for row in range(MAX_N_IN_A_ROW_BOARD_SIZE)
                      for column in range(MAX_N_IN_A_ROW_BOARD_SIZE)]
        draw_cells[0] = 2
        draw_cells[MAX_N_IN_A_ROW_BOARD_SIZE - 1] = 1
        for player in (1, 2):
            draw = (MAX_N_IN_A_ROW_BOARD_SIZE, player, *draw_cells)
            cases[draw] = oracle(algorithm, list(draw))
        invalid_cases = (
            (), (2, 1), (1, 1, 1), (MAX_N_IN_A_ROW_BOARD_SIZE + 1, 1),
            (2, 3, 0, 0, 0, 0), (2, 1, 0, 0, 0), (2, 1, 0, 0, 0, 3),
            (MAX_N_IN_A_ROW_BOARD_SIZE, 1,
             *([0] * (MAX_N_IN_A_ROW_BOARD_SIZE ** 2)), 0),
        )
        for values in invalid_cases:
            cases[values] = oracle(algorithm, list(values))
    elif algorithm == "bron_kerbosch":
        for vertex_count in range(MAX_BRON_KERBOSCH_VERTICES + 1):
            pairs = [(left, right) for left in range(vertex_count)
                     for right in range(left + 1, vertex_count)]
            for edge_mask in range(1 << len(pairs)):
                rows = [0] * vertex_count
                for edge_index, (left, right) in enumerate(pairs):
                    if edge_mask & (1 << edge_index):
                        rows[left] |= 1 << right
                        rows[right] |= 1 << left
                values = [vertex_count, *rows]
                cases[tuple(values)] = oracle(algorithm, values)
        for values in ([], [0, 0], [1], [1, 0, 0], [1, 2], [-1], [6],
                       [2, 2, 0], [1, -1], [5, 32, 0, 0, 0, 0],
                       [5, 0, 0, 0, 0, 0, 0]):
            cases[tuple(values)] = oracle(algorithm, list(values))
    elif algorithm == "brightness":
        for level in range(256):
            values = [level, level, level]
            cases[tuple(values)] = oracle(algorithm, values)
        for red in (0, 1, 2, 14, 20, 37, 71, 119, 139, 168, 186, 252, 254, 255):
            for green in (0, 1, 13, 28, 33, 44, 65, 80, 99, 169, 227, 254, 255):
                for blue in (0, 1, 10, 20, 24, 58, 65, 80, 90, 126, 229, 254, 255):
                    values = [red, green, blue]
                    cases[tuple(values)] = oracle(algorithm, values)
        for _ in range(512):
            values = [rng.randrange(256) for _ in range(3)]
            cases[tuple(values)] = oracle(algorithm, values)
        for values in ([], [0], [0, 0], [0, 0, 0, 0], [-1, 0, 0],
                       [256, 0, 0], [0, 256, 0], [0, 0, 256]):
            cases[tuple(values)] = oracle(algorithm, values)
    elif algorithm == "celebrity_finder":
        # Exhaust every row-major directed graph through three people, including
        # diagonal variants because the source deliberately ignores diagonals.
        for person_count in range(1, 4):
            for matrix_mask in range(1 << (person_count * person_count)):
                matrix = [(matrix_mask >> index) & 1
                          for index in range(person_count * person_count)]
                values = [person_count, *matrix]
                cases[tuple(values)] = oracle(algorithm, values)

        # Plant a celebrity at several positions in larger random graphs. All
        # unrelated edges remain random so candidate elimination sees varied
        # paths before the final direct definition check.
        for person_count in (1, 2, 3, 4, 8, 16, 32, 64):
            candidates = {0, (person_count - 1) // 2, person_count - 1}
            for candidate in candidates:
                matrix = [rng.randrange(2) for _ in range(person_count * person_count)]
                for person in range(person_count):
                    if person != candidate:
                        matrix[candidate * person_count + person] = 0
                        matrix[person * person_count + candidate] = 1
                values = [person_count, *matrix]
                cases[tuple(values)] = oracle(algorithm, values)

        # Deterministic graphs with no celebrity plus seeded arbitrary matrices.
        for person_count in (2, 3, 8, 64):
            for fill in (0, 1):
                values = [person_count, *([fill] * (person_count * person_count))]
                cases[tuple(values)] = oracle(algorithm, values)
        for _ in range(96):
            person_count = rng.randrange(1, 65)
            matrix = [rng.randrange(2) for _ in range(person_count * person_count)]
            values = [person_count, *matrix]
            cases[tuple(values)] = oracle(algorithm, values)

        invalid = (
            (), (0,), (65,), (1,), (1, 0, 0), (1, 2),
            (2, 0, 1, 0), (2, 0, 1, 0, 0, 1),
            (2, 0, 1, 0, 2), (-1,), (I64_MIN,), (1, I64_MAX),
            (64, *([0] * MAX_CELEBRITY_FINDER_INPUT_LENGTH)),
        )
        for values in invalid:
            packed = list(values)
            cases[tuple(values)] = oracle(algorithm, packed)
    elif algorithm == "optimal_string_alignment_distance":
        alphabet = (ord("a"), ord("b"))
        strings = [tuple()]
        for length in range(1, 6):
            strings.extend(product(alphabet, repeat=length))
        for left in strings:
            for right in strings:
                values = (len(left), len(right), *left, *right)
                cases[values] = oracle(algorithm, list(values))
        maximum_pair = (32, 32, *([ord("a")] * 32), *([ord("b")] * 32))
        cases[maximum_pair] = oracle(algorithm, list(maximum_pair))
        rng = random.Random(20261015)
        alphabet = (ord("a"), ord("b"), ord("c"), ord("x"))
        for _ in range(256):
            left = tuple(rng.choice(alphabet) for _ in range(rng.randrange(0, 33)))
            right = tuple(rng.choice(alphabet) for _ in range(rng.randrange(0, 33)))
            values = (len(left), len(right), *left, *right)
            cases[values] = oracle(algorithm, list(values))
        for values in ((), (0,), (-1, 0), (33, 0), (0, 33), (1, 1),
                       (1, 1, 128, 97), (1, 1, 97), (0, 0, 0),
                       (1, 0, I64_MIN), (I64_MAX, 0)):
            cases[values] = oracle(algorithm, list(values))
    elif algorithm == "string_prefix_suffix":
        code_units = (0, 0x41, 0xD800, 0xDC00, 0xFFFF)
        strings = [tuple()]
        for length in range(1, 3):
            strings.extend(product(code_units, repeat=length))
        for text in strings:
            for pattern in strings:
                for operation in (0, 1):
                    values = (operation, len(text), len(pattern), *text, *pattern)
                    cases[values] = oracle(algorithm, list(values))
        for _ in range(256):
            text = tuple(rng.choice(code_units) for _ in range(rng.randrange(0, 33)))
            pattern = tuple(rng.choice(code_units) for _ in range(rng.randrange(0, 17)))
            operation = rng.randrange(2)
            values = (operation, len(text), len(pattern), *text, *pattern)
            cases[values] = oracle(algorithm, list(values))
        maximum = (0, 1024, 1024, *([0xD800] * 1024), *([0xD800] * 1024))
        cases[maximum] = oracle(algorithm, list(maximum))
        for values in ((), (0,), (2, 0, 0), (0, -1, 0), (0, 0, -1),
                       (0, 0, 0, 0), (0, 1, 0, 0, 1), (1, 1, 0, 65536),
                       (0, 1025, 0), (0, 0, 1025), (0, 1, 1, 65536, 65),
                       (0, 0, 0, *([0] * 2049))):
            cases[values] = oracle(algorithm, list(values))
    elif algorithm == "is_valid_email_address":
        def encode_email(text: str) -> tuple[int, ...]:
            return tuple(map(ord, text))

        local_parts = ("", "a", "AB12", "a.b", "a..b", ".a", "a.", "a_b", "x+tag")
        domains = ("", "x", "mailserver1", "example.com", "x-", "-x", ".x", "x.", "a..b", "b_c")
        for local_part in local_parts:
            for domain in domains:
                values = encode_email(local_part + "@" + domain)
                cases[values] = oracle(algorithm, list(values))
        for length in (63, 64, 65):
            values = encode_email("a" * length + "@x")
            cases[values] = oracle(algorithm, list(values))
        for length in (254, 255, 256):
            values = encode_email("a@" + "b" * length)
            cases[values] = oracle(algorithm, list(values))
        local_alphabet = "aAZ09.!#$%&'*+-/=?^_`{|}~()_,@"
        domain_alphabet = "aAZ09.-_@"
        for _ in range(256):
            local_part = "".join(rng.choice(local_alphabet) for _ in range(rng.randrange(0, 66)))
            domain = "".join(rng.choice(domain_alphabet) for _ in range(rng.randrange(0, 257)))
            text = local_part + "@" + domain
            values = encode_email(text)
            cases[values] = oracle(algorithm, list(values))
        for values in ((), (-1,), (0x110000,), (I64_MIN,),
                       (0x110000,) * 321, tuple([ord("a")] * 64 + [64] + [ord("b")] * 256)):
            cases[values] = oracle(algorithm, list(values))
    elif algorithm == "hamming_distance_bytes":
        for count in range(0, 65):
            left = tuple(rng.randrange(256) for _ in range(count))
            right = tuple(rng.randrange(256) for _ in range(count))
            values = (count, *left, *right)
            cases[values] = oracle(algorithm, list(values))
        maximum = (1024, *([0] * 1024), *([255] * 1024))
        cases[maximum] = oracle(algorithm, list(maximum))
        for values in ((), (0, 1), (1, 65), (1, 65, 66, 67),
                       (-1,), (1025,), (1, -1, 255), (1, 256, 0),
                       (1024, *([0] * 2048), 0)):
            cases[values] = oracle(algorithm, list(values))
    elif algorithm == "hamming_distance_strings":
        rng = random.Random(20261016)
        fixed_pairs = (
            ((), ()),
            ((65, 66, 67), (65, 66, 67)),
            ((65, 66, 67), (65, 88, 67)),
            ((0, 65, 255), (0, 66, 254)),
            ((0, 1, 2, 3), (3, 2, 1, 0)),
            (tuple(range(256))[:MAX_HAMMING_DISTANCE_STRINGS_LENGTH],
             tuple(range(256))[:MAX_HAMMING_DISTANCE_STRINGS_LENGTH]),
            (tuple([0] * MAX_HAMMING_DISTANCE_STRINGS_LENGTH),
             tuple([255] * MAX_HAMMING_DISTANCE_STRINGS_LENGTH)),
            ((1, 2), (1,)),
            ((), (0,)),
        )
        for left, right in fixed_pairs:
            values = (len(left), len(right), *left, *right)
            cases[values] = oracle(algorithm, list(values))
        for _ in range(256):
            left_length = rng.randint(0, MAX_HAMMING_DISTANCE_STRINGS_LENGTH)
            right_length = rng.randint(0, MAX_HAMMING_DISTANCE_STRINGS_LENGTH)
            left = tuple(rng.randrange(256) for _ in range(left_length))
            right = tuple(rng.randrange(256) for _ in range(right_length))
            values = (left_length, right_length, *left, *right)
            cases[values] = oracle(algorithm, list(values))
        over_bound_left = (MAX_HAMMING_DISTANCE_STRINGS_LENGTH + 1,
                           MAX_HAMMING_DISTANCE_STRINGS_LENGTH,
                           *([0] * (2 * MAX_HAMMING_DISTANCE_STRINGS_LENGTH + 1)))
        both_over_bound = (MAX_HAMMING_DISTANCE_STRINGS_LENGTH + 1,
                           MAX_HAMMING_DISTANCE_STRINGS_LENGTH + 1,
                           *([0] * (2 * (MAX_HAMMING_DISTANCE_STRINGS_LENGTH + 1))))
        malformed = ((), (0,), (-1, 0), (0, -1),
                     (MAX_HAMMING_DISTANCE_STRINGS_LENGTH + 1, 0),
                     (0, 0, 1), (1, 1), (1, 1, 256, 0),
                     (1, 1, -1, 0), over_bound_left, both_over_bound)
        for values in malformed:
            if len(values) <= MAX_HAMMING_DISTANCE_STRINGS_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
    elif algorithm == "hexa_decimal_to_decimal":
        rng = random.Random(20261016)
        hex_codes = (*range(48, 58), *range(65, 71), *range(97, 103))
        for _ in range(256):
            length = rng.randint(0, MAX_HEXA_DECIMAL_INPUT_LENGTH)
            values = tuple(rng.choice(hex_codes) for _ in range(length))
            cases[values] = oracle(algorithm, list(values))
        too_long = (48,) * MAX_HEXA_DECIMAL_PARSEABLE_INPUT_LENGTH
        malformed = (
            (71,), (58,), (32,), (-1,), (HEXA_DECIMAL_MAX_ASCII_VALUE + 1,),
            (I64_MIN,), (I64_MAX,), too_long,
        )
        for values in malformed:
            if len(values) <= MAX_HEXA_DECIMAL_PARSEABLE_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
    elif algorithm == "djb2":
        fixed_cases = (
            (), (0,), (255,), (0, 255), (65, 0, 66),
            (255,) * MAX_DJB2_STRING_LENGTH,
        )
        for values in fixed_cases:
            cases[values] = oracle(algorithm, list(values))
        rng = random.Random(20261016)
        for _ in range(256):
            length = rng.randint(0, MAX_DJB2_STRING_LENGTH)
            values = tuple(rng.randrange(256) for _ in range(length))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (-1,), (256,), (I64_MIN,), (I64_MAX,),
            (0,) * (MAX_DJB2_STRING_LENGTH + 1),
        )
        for values in malformed:
            if len(values) <= MAX_DJB2_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
    elif algorithm == "hash_djb2":
        fixed_cases = (
            (0,), (1, 1), (1, 127), (3, 97, 98, 99),
            (3, 127, 127, 127),
        )
        for values in fixed_cases:
            cases[values] = oracle(algorithm, list(values))
        rng = random.Random(20261016)
        for _ in range(512):
            byte_count = rng.randint(0, HASH_DJB2_MAX_BYTES)
            values = (byte_count, *(rng.randint(1, 127) for _ in range(byte_count)))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (-1,), (HASH_DJB2_MAX_BYTES + 1,), (0, 97),
            (1,), (1, 0), (1, 128), (2, 1), (2, 1, 2, 3),
            (I64_MIN,), (I64_MAX,), (2, I64_MIN, 1),
        )
        for values in malformed:
            if len(values) <= MAX_HASH_DJB2_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
    elif algorithm == "hash_xor8":
        fixed_cases = (
            (), (0,), (65,), (127,), (65, 0, 66), (65, 0, 128),
            (0, I64_MIN), (65, 128, 0),
            (127,) * MAX_HASH_XOR8_INPUT_LENGTH,
        )
        for values in fixed_cases:
            cases[values] = oracle(algorithm, list(values))
        rng = random.Random(20261016)
        for _ in range(512):
            length = rng.randint(0, 128)
            values = tuple(rng.randint(0, 127) for _ in range(length))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (-1,), (128,), (65, 128), (I64_MIN,), (I64_MAX,),
            (127,) * (MAX_HASH_XOR8_INPUT_LENGTH + 1),
        )
        for values in malformed:
            if len(values) <= MAX_HASH_XOR8_INPUT_LENGTH + 1:
                cases[values] = HASH_XOR8_INVALID_RESULT
    elif algorithm == "hex_to_oct":
        fixed_cases = (
            (), (48,), (65,), (97,), (70,), (52, 56), (65, 68), (70, 70),
            (70, 70, 70), (49, 97, 67), (48, 48, 48, 70),
            tuple(map(ord, "7FFFFFFF")), tuple(map(ord, "80000000")),
            tuple(map(ord, "FFFFFFFF")), tuple(map(ord, "4FFFFFFF")),
        )
        for values in fixed_cases:
            cases[values] = oracle(algorithm, list(values))
        rng = random.Random(20261016)
        hex_codes = (*range(48, 58), *range(65, 71), *range(97, 103))
        for _ in range(512):
            length = rng.randint(0, MAX_HEX_TO_OCT_INPUT_LENGTH)
            values = tuple(rng.choice(hex_codes) for _ in range(length))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (71,), (58,), (32,), (-1,), (233,), (I64_MIN,), (I64_MAX,),
            (48,) * (MAX_HEX_TO_OCT_INPUT_LENGTH + 1),
        )
        for values in malformed:
            if len(values) <= MAX_HEX_TO_OCT_PARSEABLE_INPUT_LENGTH:
                cases[values] = HEX_TO_OCT_INVALID_RESULT
    elif algorithm == "grid_get":
        for columns in range(1, 33):
            for index in range(min(MAX_GRID_GET_INDEX + 1, 2 * columns + 1)):
                for operation in (0, 1):
                    values = (operation, columns, index)
                    cases[values] = oracle(algorithm, list(values))
        fixed_cases = (
            (0, 1, MAX_GRID_GET_INDEX), (1, 1, MAX_GRID_GET_INDEX),
            (0, MAX_GRID_GET_COLUMNS, MAX_GRID_GET_INDEX),
            (1, MAX_GRID_GET_COLUMNS, MAX_GRID_GET_INDEX),
        )
        for values in fixed_cases:
            cases[values] = oracle(algorithm, list(values))
        rng = random.Random(20261016)
        for _ in range(512):
            values = (rng.randrange(2), rng.randint(1, MAX_GRID_GET_COLUMNS),
                      rng.randint(0, MAX_GRID_GET_INDEX))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (0,), (0, 10), (0, 10, 1, 99),
            (-1, 10, 0), (2, 10, 0), (0, 0, 0),
            (1, MAX_GRID_GET_COLUMNS + 1, 0), (0, 10, -1),
            (1, 10, MAX_GRID_GET_INDEX + 1),
            (I64_MIN, 1, 0), (I64_MAX, 1, 0),
            (0, 1, I64_MIN), (1, 1, I64_MAX),
        )
        for values in malformed:
            if len(values) <= MAX_GRID_GET_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
    elif algorithm == "number_of_subarrays_with_odd_sum":
        for length in range(9):
            for values in product((-1, 0, 2), repeat=length):
                cases[values] = oracle(algorithm, list(values))
        cases[(1,) * MAX_ODD_SUM_SUBARRAY_INPUT_LENGTH] = oracle(
            algorithm, [1] * MAX_ODD_SUM_SUBARRAY_INPUT_LENGTH)
        signed_boundaries = (MIN_ODD_SUM_SUBARRAY_VALUE, 1, MAX_ODD_SUM_SUBARRAY_VALUE)
        cases[signed_boundaries] = oracle(algorithm, list(signed_boundaries))
        rng = random.Random(20261015)
        for _ in range(512):
            length = rng.randrange(65)
            values = tuple(rng.randint(MIN_ODD_SUM_SUBARRAY_VALUE,
                                       MAX_ODD_SUM_SUBARRAY_VALUE)
                           for _ in range(length))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (MIN_ODD_SUM_SUBARRAY_VALUE - 1,),
            (MAX_ODD_SUM_SUBARRAY_VALUE + 1,),
            (I64_MIN,), (I64_MAX,),
            (0,) * (MAX_ODD_SUM_SUBARRAY_INPUT_LENGTH + 1),
        )
        for values in malformed:
            if len(values) <= MAX_ODD_SUM_SUBARRAY_INPUT_LENGTH + 1:
                cases[values] = oracle(algorithm, list(values))
    elif algorithm == "maximum_circular_subarray":
        for length in range(1, 8):
            for values in product((-2, 0, 3), repeat=length):
                cases[values] = oracle(algorithm, list(values))
        fixed_cases = (
            (0,), (1,), (-1,), (1, 2, 3), (-4, -2, -7),
            (5, -3, 5), (1, -5, 3), (0,) * MAX_MAX_CIRCULAR_SUBARRAY_VALID_INPUT_LENGTH,
            (MAX_MAX_CIRCULAR_SUBARRAY_VALUE,) * MAX_MAX_CIRCULAR_SUBARRAY_VALID_INPUT_LENGTH,
            (MIN_MAX_CIRCULAR_SUBARRAY_VALUE,) * MAX_MAX_CIRCULAR_SUBARRAY_VALID_INPUT_LENGTH,
        )
        for values in fixed_cases:
            cases[values] = oracle(algorithm, list(values))
        rng = random.Random(20261016)
        for _ in range(512):
            length = rng.randint(1, MAX_MAX_CIRCULAR_SUBARRAY_VALID_INPUT_LENGTH)
            values = tuple(rng.randint(MIN_MAX_CIRCULAR_SUBARRAY_VALUE,
                                       MAX_MAX_CIRCULAR_SUBARRAY_VALUE)
                           for _ in range(length))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (MIN_MAX_CIRCULAR_SUBARRAY_VALUE - 1,),
            (MAX_MAX_CIRCULAR_SUBARRAY_VALUE + 1,),
            (I64_MIN,), (I64_MAX,),
            (0,) * (MAX_MAX_CIRCULAR_SUBARRAY_VALID_INPUT_LENGTH + 1),
        )
        for values in malformed:
            if len(values) <= MAX_MAX_CIRCULAR_SUBARRAY_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
    elif algorithm == "maximum_product_subarray":
        for length in range(1, 8):
            for values in product((-2, 0, 3), repeat=length):
                cases[values] = oracle(algorithm, list(values))
        fixed_cases = (
            (-1,), (0,), (1,), (2, 3, -2, 4), (-2, 0, -1),
            (-2, 3, -4), (0, -3, 0), (-3, -4),
            (-2, -3, -4, -5), (-2, -3, -4, -5, -6),
            (2, 3, 0, -4, -5), (-2, 3, -4, 5, -6),
            (MAX_MAX_PRODUCT_SUBARRAY_VALUE,) * MAX_MAX_PRODUCT_SUBARRAY_VALID_INPUT_LENGTH,
            (MIN_MAX_PRODUCT_SUBARRAY_VALUE,) * MAX_MAX_PRODUCT_SUBARRAY_VALID_INPUT_LENGTH,
        )
        for values in fixed_cases:
            cases[values] = oracle(algorithm, list(values))
        rng = random.Random(20261016)
        for _ in range(512):
            length = rng.randint(1, MAX_MAX_PRODUCT_SUBARRAY_VALID_INPUT_LENGTH)
            values = tuple(rng.randint(MIN_MAX_PRODUCT_SUBARRAY_VALUE,
                                       MAX_MAX_PRODUCT_SUBARRAY_VALUE)
                           for _ in range(length))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (MIN_MAX_PRODUCT_SUBARRAY_VALUE - 1,),
            (MAX_MAX_PRODUCT_SUBARRAY_VALUE + 1,),
            (I64_MIN,), (I64_MAX,),
            (0,) * (MAX_MAX_PRODUCT_SUBARRAY_VALID_INPUT_LENGTH + 1),
        )
        for values in malformed:
            if len(values) <= MAX_MAX_PRODUCT_SUBARRAY_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
    elif algorithm == "maximum_subarray_int32":
        for length in range(1, 8):
            for values in product((-2, 0, 3), repeat=length):
                cases[values] = oracle(algorithm, list(values))
        for values in (
            (-1,), (0,), (1,), (5, -3, 5), (1, -5, 3),
            (-MAX_MAXIMUM_SUBARRAY_INT32_ABS_VALUE,) * MAX_MAXIMUM_SUBARRAY_INT32_LENGTH,
            (MAX_MAXIMUM_SUBARRAY_INT32_ABS_VALUE,) * MAX_MAXIMUM_SUBARRAY_INT32_LENGTH,
            (MAX_MAXIMUM_SUBARRAY_INT32_ABS_VALUE, -MAX_MAXIMUM_SUBARRAY_INT32_ABS_VALUE,
             MAX_MAXIMUM_SUBARRAY_INT32_ABS_VALUE),
        ):
            cases[values] = oracle(algorithm, list(values))
        rng = random.Random(20261016)
        for _ in range(256):
            length = rng.randint(1, MAX_MAXIMUM_SUBARRAY_INT32_LENGTH)
            values = tuple(rng.randint(-MAX_MAXIMUM_SUBARRAY_INT32_ABS_VALUE,
                                       MAX_MAXIMUM_SUBARRAY_INT32_ABS_VALUE)
                           for _ in range(length))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (-MAX_MAXIMUM_SUBARRAY_INT32_ABS_VALUE - 1,),
            (MAX_MAXIMUM_SUBARRAY_INT32_ABS_VALUE + 1,), (I64_MIN,), (I64_MAX,),
            (0,) * MAX_MAXIMUM_SUBARRAY_INT32_INPUT_LENGTH,
        )
        for values in malformed:
            if len(values) <= MAX_MAXIMUM_SUBARRAY_INT32_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
        special_records.append("NULL 1 -1\n")
    elif algorithm == "maximum_subarray_allow_empty":
        for length in range(8):
            for values in product((-2, 0, 3), repeat=length):
                cases[values] = oracle(algorithm, list(values))
        for values in (
            (), (-1,), (0,), (1,), (-7, -3, -5), (1, -5, 3),
            (-(2**31), 2**31 - 1), (2**31 - 1, 2**31 - 1),
            (-(2**31),) * MAX_MAXIMUM_SUBARRAY_ALLOW_EMPTY_LENGTH,
            (2**31 - 1,) * MAX_MAXIMUM_SUBARRAY_ALLOW_EMPTY_LENGTH,
        ):
            cases[values] = oracle(algorithm, list(values))
        rng = random.Random(20261016)
        for _ in range(256):
            length = rng.randint(0, MAX_MAXIMUM_SUBARRAY_ALLOW_EMPTY_LENGTH)
            values = tuple(rng.randint(-(2**31), 2**31 - 1) for _ in range(length))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (-(2**31) - 1,), (2**31,), (I64_MIN,), (I64_MAX,),
            (0,) * MAX_MAXIMUM_SUBARRAY_ALLOW_EMPTY_INPUT_LENGTH,
        )
        for values in malformed:
            if len(values) <= MAX_MAXIMUM_SUBARRAY_ALLOW_EMPTY_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
        special_records.append("NULL 1 -1\n")
    elif algorithm == "median_search":
        for count in range(1, 7):
            ascending = tuple(range(count))
            descending = tuple(reversed(ascending))
            for rank in range(count):
                cases[(count, rank, *ascending)] = oracle(
                    algorithm, [count, rank, *ascending])
                cases[(count, rank, *descending)] = oracle(
                    algorithm, [count, rank, *descending])
        for count in (5, 6, 10, 11, MAX_MEDIAN_SEARCH_ELEMENT_COUNT):
            values_array = tuple(range(count))
            for rank in {0, (count - 1) // 2, count // 2, count - 1}:
                values = (count, rank, *values_array)
                cases[values] = oracle(algorithm, list(values))
        for values_array in ((0, MEDIAN_SEARCH_INT32_MAX),
                             (MEDIAN_SEARCH_INT32_MAX, 0)):
            for rank in range(2):
                values = (2, rank, *values_array)
                cases[values] = oracle(algorithm, list(values))
        rng = random.Random(20261016)
        for _ in range(256):
            count = rng.randint(1, MAX_MEDIAN_SEARCH_ELEMENT_COUNT)
            values_array = tuple(rng.sample(range(MEDIAN_SEARCH_INT32_MAX + 1), count))
            rank = rng.randrange(count)
            values = (count, rank, *values_array)
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (0, 0), (1, -1, 0), (1, 1, 0), (2, 0, 5),
            (2, 2, 3, 4), (2, 0, 3, 3), (2, 0, -1, 1),
            (2, 0, 0, MEDIAN_SEARCH_INT32_MAX + 1),
            (1, 0, 0, 1), (MAX_MEDIAN_SEARCH_ELEMENT_COUNT + 1, 0,
                           *range(MAX_MEDIAN_SEARCH_ELEMENT_COUNT + 1)),
            (MEDIAN_SEARCH_INT32_MAX + 1, 0, 1),
        )
        for values in malformed:
            if len(values) <= MAX_MEDIAN_SEARCH_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
        special_records.append("NULL 1 -1\n")
    elif algorithm == "largest_rectangle_histogram":
        for length in range(7):
            for values in product((0, 1, 3), repeat=length):
                cases[values] = oracle(algorithm, list(values))
        fixed_cases = (
            (), (0,), (7,), (2, 1, 5, 6, 2, 3), (2, 4),
            (6, 2, 5, 4, 5, 1, 6), (2, 2, 2, 2),
            (1, 2, 3, 4), (4, 3, 2, 1), (3, 0, 3), (2, 2, 0, 3, 3),
            (MAX_LARGEST_RECTANGLE_HISTOGRAM_HEIGHT,)
            * MAX_LARGEST_RECTANGLE_HISTOGRAM_VALID_INPUT_LENGTH,
            (0,) * MAX_LARGEST_RECTANGLE_HISTOGRAM_VALID_INPUT_LENGTH,
        )
        for values in fixed_cases:
            cases[values] = oracle(algorithm, list(values))
        rng = random.Random(20261016)
        for _ in range(512):
            length = rng.randint(0, MAX_LARGEST_RECTANGLE_HISTOGRAM_VALID_INPUT_LENGTH)
            values = tuple(rng.randint(MIN_LARGEST_RECTANGLE_HISTOGRAM_HEIGHT,
                                       MAX_LARGEST_RECTANGLE_HISTOGRAM_HEIGHT)
                           for _ in range(length))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (-1,), (MAX_LARGEST_RECTANGLE_HISTOGRAM_HEIGHT + 1,),
            (I64_MIN,), (I64_MAX,),
            (0,) * (MAX_LARGEST_RECTANGLE_HISTOGRAM_VALID_INPUT_LENGTH + 1),
        )
        for values in malformed:
            if len(values) <= MAX_LARGEST_RECTANGLE_HISTOGRAM_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
    elif algorithm == "hamiltonian_path_exists":
        for vertex_count in range(4):
            matrix_length = vertex_count * vertex_count
            for mask in range(1 << matrix_length):
                matrix = tuple((mask >> index) & 1 for index in range(matrix_length))
                values = (vertex_count, *matrix)
                cases[values] = oracle(algorithm, list(values))

        def packed_graph(vertex_count: int,
                         edge: Callable[[int, int], bool]) -> tuple[int, ...]:
            return (vertex_count, *(int(edge(row, column))
                                    for row in range(vertex_count)
                                    for column in range(vertex_count)))

        maximum_vertices = MAX_HAMILTONIAN_PATH_EXISTS_VERTICES
        for values in (
            packed_graph(maximum_vertices, lambda row, column: False),
            packed_graph(maximum_vertices, lambda row, column: row != column),
            packed_graph(maximum_vertices, lambda row, column: column == row + 1),
            packed_graph(maximum_vertices, lambda row, column: column == row - 1),
        ):
            cases[values] = oracle(algorithm, list(values))

        rng = random.Random(20261016)
        for _ in range(256):
            vertex_count = rng.randint(1, maximum_vertices)
            edge_density = rng.choice((0.15, 0.4, 0.75))
            values = packed_graph(vertex_count,
                                  lambda row, column: rng.random() < edge_density)
            cases[values] = oracle(algorithm, list(values))

        malformed = (
            (), (-1,), (2, 0), (2, 0, 0, 0, 0, 0),
            (1, 2), (2, 0, 0, 0, 2),
            (I64_MIN,), (I64_MAX,),
            (maximum_vertices + 1,
             *([0] * (maximum_vertices + 1) ** 2)),
            (MAX_HAMILTONIAN_PATH_EXISTS_INPUT_LENGTH + 1,),
        )
        for values in malformed:
            if len(values) <= MAX_HAMILTONIAN_PATH_EXISTS_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
        special_records.append("NULL 1 -1\n")
    elif algorithm == "fast_searcher":
        for count in range(5):
            for values_array in combinations(range(-2, 3), count):
                for target in range(-3, 4):
                    values = (count, *values_array, target)
                    cases[values] = oracle(algorithm, list(values))
        fixed_cases = (
            (0, 0), (1, -1000, -1000), (1, 1000, 1000),
            (3, -1000, 0, 1000, -1000),
            (3, -1000, 0, 1000, 0),
            (3, -1000, 0, 1000, 1000),
            (0, -1000), (0, 1000),
            (MAX_FAST_SEARCHER_ARRAY_LENGTH,
             *range(MIN_FAST_SEARCHER_VALUE,
                    MIN_FAST_SEARCHER_VALUE + MAX_FAST_SEARCHER_ARRAY_LENGTH),
             MAX_FAST_SEARCHER_VALUE),
        )
        for values in fixed_cases:
            cases[values] = oracle(algorithm, list(values))
        rng = random.Random(20261016)
        for _ in range(256):
            count = rng.randint(0, MAX_FAST_SEARCHER_ARRAY_LENGTH)
            array = tuple(sorted(rng.sample(range(MIN_FAST_SEARCHER_VALUE,
                                                  MAX_FAST_SEARCHER_VALUE + 1), count)))
            target = rng.randint(MIN_FAST_SEARCHER_VALUE, MAX_FAST_SEARCHER_VALUE)
            values = (count, *array, target)
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (0,), (2, 1, 3), (-1, 0),
            (MAX_FAST_SEARCHER_ARRAY_LENGTH + 1,
             *range(MAX_FAST_SEARCHER_ARRAY_LENGTH + 1), 0),
            (2, 1, 1, 1), (2, 2, 1, 2),
            (1, MAX_FAST_SEARCHER_VALUE + 1, 0),
            (1, 0, MAX_FAST_SEARCHER_VALUE + 1),
            (I64_MIN, 0), (0, I64_MAX),
        )
        for values in malformed:
            if len(values) <= MAX_FAST_SEARCHER_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
        special_records.append("NULL 1 -2\n")
    elif algorithm == "minimum_sum_partition":
        for length in range(8):
            for values in product((0, 1, 3), repeat=length):
                cases[values] = oracle(algorithm, list(values))
        rng = random.Random(20261016)
        for _ in range(512):
            length = rng.randint(0, MAX_MINIMUM_SUM_PARTITION_VALID_LENGTH)
            values = tuple(rng.randint(0, MAX_MINIMUM_SUM_PARTITION_TOTAL
                                       // MAX_MINIMUM_SUM_PARTITION_VALID_LENGTH)
                           for _ in range(length))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (-1,), (MAX_MINIMUM_SUM_PARTITION_TOTAL + 1,),
            (MAX_MINIMUM_SUM_PARTITION_TOTAL // 2,
             MAX_MINIMUM_SUM_PARTITION_TOTAL // 2 + 1),
            (I64_MIN,), (I64_MAX,),
            (0,) * MAX_MINIMUM_SUM_PARTITION_VALID_LENGTH + (0,),
        )
        for values in malformed:
            if len(values) <= MAX_MINIMUM_SUM_PARTITION_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
        special_records.append("NULL 1 -1\n")
    elif algorithm == "upper_bound":
        fixed_cases = (
            (10,),
            (0, 3), (3, 3), (4, 3),
            (UPPER_BOUND_INT32_MIN, 0, 1, 2),
            (2, 0, 2, 2, 4, 7),
            (UPPER_BOUND_INT32_MAX, -2, -1, 0),
            (5, 1, 1, 1, 1),
            (2, 1, 2, 2, 4),
            (0, *range(-256, 256)),
        )
        for values in fixed_cases:
            cases[values] = oracle(algorithm, list(values))
        rng = random.Random(20261016)
        for _ in range(512):
            count = rng.randint(0, MAX_UPPER_BOUND_ARRAY_LENGTH)
            array = tuple(sorted(rng.randint(UPPER_BOUND_INT32_MIN,
                                              UPPER_BOUND_INT32_MAX)
                                 for _ in range(count)))
            target = rng.randint(UPPER_BOUND_INT32_MIN, UPPER_BOUND_INT32_MAX)
            values = (target, *array)
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (),
            (UPPER_BOUND_INT32_MAX + 1,),
            (0, 2, 1),
            (0, UPPER_BOUND_INT32_MIN - 1),
            (0, UPPER_BOUND_INT32_MAX + 1),
            (I64_MIN,), (I64_MAX,),
            (0, *([0] * (MAX_UPPER_BOUND_ARRAY_LENGTH + 1))),
        )
        for values in malformed:
            if len(values) <= MAX_UPPER_BOUND_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
        special_records.append("NULL 1 -1\n")
    elif algorithm == "pow_logarithmic":
        fixed_cases = (
            (-10, 0), (-10, 15), (-10, 14), (10, 15), (10, 14),
            (-2, 15), (-2, 14), (0, 0), (0, 15), (-1, 15), (-1, 14),
        )
        for values in fixed_cases:
            cases[values] = oracle(algorithm, list(values))
        rng = random.Random(20261016)
        for _ in range(256):
            values = (
                rng.randint(MIN_POW_LOGARITHMIC_BASE, MAX_POW_LOGARITHMIC_BASE),
                rng.randint(MIN_POW_LOGARITHMIC_EXPONENT, MAX_POW_LOGARITHMIC_EXPONENT),
            )
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (2,), (2, 3, 4),
            (MAX_POW_LOGARITHMIC_BASE + 1, 2),
            (MIN_POW_LOGARITHMIC_BASE - 1, 2),
            (2, MIN_POW_LOGARITHMIC_EXPONENT - 1),
            (2, MAX_POW_LOGARITHMIC_EXPONENT + 1),
            (I64_MIN, 0), (0, I64_MAX),
        )
        for values in malformed:
            if len(values) <= MAX_POW_LOGARITHMIC_PARSEABLE_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
    elif algorithm == "longest_subarray_with_sum_at_most":
        fixed_arrays = (
            (0, ()),
            (6, (1, 2, 3, 0)),
            (5, (1, 2, 3)),
            (3, (4, 5, 1, 2, 1)),
            (0, (0, 0, 0, 0, 0)),
            (0, (0, 0, 1, 0)),
            (7, (7,)),
            (6, (7,)),
            (MAX_LONGEST_SUBARRAY_DOMAIN_VALUE,
             (MAX_LONGEST_SUBARRAY_DOMAIN_VALUE, MAX_LONGEST_SUBARRAY_DOMAIN_VALUE, 0)),
            (MAX_LONGEST_SUBARRAY_DOMAIN_VALUE, (0,) * MAX_LONGEST_SUBARRAY_VALUES),
            (MAX_LONGEST_SUBARRAY_DOMAIN_VALUE,
             (MAX_LONGEST_SUBARRAY_DOMAIN_VALUE,) * MAX_LONGEST_SUBARRAY_VALUES),
        )
        for target, items in fixed_arrays:
            values = (target, len(items), *items)
            cases[values] = oracle(algorithm, list(values))
        rng = random.Random(20261016)
        for _ in range(256):
            target = rng.randint(0, MAX_LONGEST_SUBARRAY_DOMAIN_VALUE)
            count = rng.randint(0, MAX_LONGEST_SUBARRAY_VALUES)
            items = tuple(rng.randint(0, MAX_LONGEST_SUBARRAY_DOMAIN_VALUE) for _ in range(count))
            values = (target, count, *items)
            cases[values] = oracle(algorithm, list(values))
        over_bound_count = (0, MAX_LONGEST_SUBARRAY_VALUES + 1,
                            *([0] * (MAX_LONGEST_SUBARRAY_VALUES + 1)))
        malformed = (
            (), (0,), (-1, 0), (MAX_LONGEST_SUBARRAY_DOMAIN_VALUE + 1, 0),
            (0, -1), (3, 2, 1), (3, 0, 1),
            (3, 1, -1), (3, 1, MAX_LONGEST_SUBARRAY_DOMAIN_VALUE + 1),
            over_bound_count,
        )
        for values in malformed:
            if len(values) <= MAX_LONGEST_SUBARRAY_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
    elif algorithm == "length_of_last_word":
        fixed_texts = (
            (),
            (32, 32, 32),
            (119, 111, 114, 100),
            (104, 101, 108, 108, 111, 32, 32),
            (97, 108, 112, 104, 97, 32, 32, 98, 101, 116, 97, 32),
            (32, 32, 103, 111),
            (65, 9, 66),
            (65, 0, 66, 32, 255, 128),
            (90,),
            tuple((index % 26) + 65 for index in range(MAX_LENGTH_OF_LAST_WORD_BYTES)),
        )
        for text in fixed_texts:
            values = (len(text), *text)
            cases[values] = oracle(algorithm, list(values))
        for _ in range(256):
            text_length = rng.randint(0, MAX_LENGTH_OF_LAST_WORD_BYTES)
            text = tuple(rng.randrange(256) for _ in range(text_length))
            values = (text_length, *text)
            cases[values] = oracle(algorithm, list(values))
        malformed = ((), (-1,), (MAX_LENGTH_OF_LAST_WORD_BYTES + 1,),
                     (2, 65), (1, 65, 66), (1, -1), (1, 256),
                     tuple([MAX_LENGTH_OF_LAST_WORD_BYTES] + [65] * (MAX_LENGTH_OF_LAST_WORD_BYTES - 1)
                           + [256]))
        for values in malformed:
            if len(values) <= MAX_LENGTH_OF_LAST_WORD_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
    elif algorithm == "find_min_iterator":
        fixed_arrays = (
            (0,),
            (2_147_483_647,),
            (1, 2, 3, 4, 5),
            (9, 7, 5, 3, 1),
            (8, 4, 0, 7, 3),
            (3, 1, 1, 7, 1),
            (42, 42, 42),
            (0, 2_147_483_647, 1, 2_147_483_646),
            tuple(range(MAX_FIND_MIN_ITERATOR_COUNT, 0, -1)),
        )
        for values_array in fixed_arrays:
            values = (len(values_array), *values_array)
            cases[values] = oracle(algorithm, list(values))
        for _ in range(256):
            count = rng.randint(0, MAX_FIND_MIN_ITERATOR_COUNT)
            values = (count, *(rng.randint(0, MAX_FIND_MIN_ITERATOR_VALUE)
                               for _ in range(count)))
            cases[values] = oracle(algorithm, list(values))
        malformed = ((), (-1,), (MAX_FIND_MIN_ITERATOR_COUNT + 1,),
                     (2, 1), (1, 8, 7), (1, -1),
                     (1, MAX_FIND_MIN_ITERATOR_VALUE + 1))
        for values in malformed:
            if len(values) <= MAX_FIND_MIN_ITERATOR_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
    elif algorithm == "digit_dp":
        targets = (DIGIT_DP_I32_MIN, -1, 0, 1, 5, 9, 18, MAX_DIGIT_DP_SUM,
                   MAX_DIGIT_DP_SUM + 1, DIGIT_DP_I32_MAX)
        fixed_cases = (
            (0, 0, 0), (1, 100, 5), (0, 99, 9), (50, 60, 5),
            (-1, 9, 1), (-1, 0, 0), (-1, -1, 0),
            (100, 99, 1), (0, MAX_DIGIT_DP_BOUND, 0),
            (0, MAX_DIGIT_DP_BOUND, 1),
            (MAX_DIGIT_DP_BOUND, MAX_DIGIT_DP_BOUND, 1),
            (MAX_DIGIT_DP_BOUND - 1, MAX_DIGIT_DP_BOUND, 1),
            (0, MAX_DIGIT_DP_BOUND, MAX_DIGIT_DP_SUM),
        )
        for values in fixed_cases:
            cases[values] = oracle(algorithm, list(values))
        rng = random.Random(20261016)
        for _ in range(256):
            lower = rng.randint(-1, MAX_DIGIT_DP_BOUND)
            upper = rng.randint(-1, MAX_DIGIT_DP_BOUND)
            if rng.randrange(4) != 0 and lower > upper:
                lower, upper = upper, lower
            values = (lower, upper, rng.choice(targets))
            cases[values] = oracle(algorithm, list(values))
        malformed = ((), (0,), (0, 1), (0, 1, 0, 0),
                     (-2, 0, 0), (0, MAX_DIGIT_DP_BOUND + 1, 0),
                     (0, 0, DIGIT_DP_I32_MAX + 1))
        for values in malformed:
            if len(values) <= MAX_DIGIT_DP_INPUT_LENGTH + 1:
                cases[values] = oracle(algorithm, list(values))
    elif algorithm == "xor_search_missing_number":
        fixed_cases = (
            (0,), (1, 1), (1, 0), (4, 0, 1, 2, 3),
            (4, 0, 1, 3), (5, 5, 4, 3, 2, 0),
            (4, 3, 0, 1),
            (MAX_XOR_SEARCH_MISSING_NUMBER_N,
             *range(MAX_XOR_SEARCH_MISSING_NUMBER_N // 2),
             *range(MAX_XOR_SEARCH_MISSING_NUMBER_N // 2 + 1,
                    MAX_XOR_SEARCH_MISSING_NUMBER_N + 1)),
        )
        for values in fixed_cases:
            cases[values] = oracle(algorithm, list(values))
        rng = random.Random(20261016)
        for _ in range(256):
            n = rng.randint(0, MAX_XOR_SEARCH_MISSING_NUMBER_N)
            missing = rng.randint(0, n)
            entries = [value for value in range(n + 1) if value != missing]
            rng.shuffle(entries)
            values = (n, *entries)
            cases[values] = oracle(algorithm, list(values))
        over_bound_payload = (MAX_XOR_SEARCH_MISSING_NUMBER_N + 1,
                              *range(MAX_XOR_SEARCH_MISSING_NUMBER_N + 1))
        malformed = (
            (), (-1,), (MAX_XOR_SEARCH_MISSING_NUMBER_N + 1,),
            (4, 0, 1, 2), (2, 0, 1, 2), (2, 0, 0),
            (2, -1, 1), (2, 0, 3), over_bound_payload,
        )
        for values in malformed:
            if len(values) <= MAX_XOR_SEARCH_MISSING_NUMBER_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
    elif algorithm == "maximum_sum_bst":
        fixed_cases = (
            (0,), (1, 7), (3, 2, 1, 3), (3, 2, 2, 3),
            (3, 0, 0, 0), (7, 10, 5, 15, 2, 7, 12, 20),
            (MAX_MAXIMUM_SUM_BST_SLOTS, *range(1, MAX_MAXIMUM_SUM_BST_SLOTS + 1)),
            (MAX_MAXIMUM_SUM_BST_SLOTS,
             *([MAX_MAXIMUM_SUM_BST_VALUE] * MAX_MAXIMUM_SUM_BST_SLOTS)),
        )
        for values in fixed_cases:
            cases[values] = oracle(algorithm, list(values))
        rng = random.Random(20261016)
        for _ in range(256):
            count = rng.randint(0, MAX_MAXIMUM_SUM_BST_SLOTS)
            slots = []
            for index in range(count):
                parent_present = index == 0 or slots[(index - 1) // 2] != -1
                present = parent_present and rng.randrange(4) != 0
                slots.append(rng.randint(0, MAX_MAXIMUM_SUM_BST_VALUE) if present else -1)
            values = (count, *slots)
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (-1,), (MAX_MAXIMUM_SUM_BST_SLOTS + 1,),
            (3, 1, 2), (1, 5, 6), (1, -2),
            (1, MAX_MAXIMUM_SUM_BST_VALUE + 1),
            (3, 5, -1, -1, 7),
            (MAX_MAXIMUM_SUM_BST_SLOTS, *([0] * MAX_MAXIMUM_SUM_BST_SLOTS), 0),
        )
        for values in malformed:
            if len(values) <= MAX_MAXIMUM_SUM_BST_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
    elif algorithm == "how_many_times_rotated":
        rng = random.Random(20261016)
        fixed_arrays = (
            (),
            (42,),
            (-8, -1, 0, 9),
            (2, 1),
            (2147483647, -2147483648),
            tuple(range(-128, 128)),
        )
        for values in fixed_arrays:
            cases[values] = oracle(algorithm, list(values))
        for length in range(1, 17):
            ordered = tuple(range(-length // 2, -length // 2 + length))
            for offset in range(length):
                values = ordered[offset:] + ordered[:offset]
                cases[values] = oracle(algorithm, list(values))
        for _ in range(256):
            length = rng.randint(1, MAX_HOW_MANY_TIMES_ROTATED_ARRAY_LENGTH)
            start = rng.randint(HOW_MANY_TIMES_ROTATED_I32_MIN,
                                HOW_MANY_TIMES_ROTATED_I32_MAX - length + 1)
            ordered = tuple(range(start, start + length))
            offset = rng.randrange(length)
            values = ordered[offset:] + ordered[:offset]
            cases[values] = oracle(algorithm, list(values))
        maximum_invalid_length = (0,) * (MAX_HOW_MANY_TIMES_ROTATED_INPUT_LENGTH + 1)
        malformed = (
            (HOW_MANY_TIMES_ROTATED_I32_MAX + 1,),
            (HOW_MANY_TIMES_ROTATED_I32_MIN - 1,),
            maximum_invalid_length,
        )
        for values in malformed:
            if len(values) <= MAX_HOW_MANY_TIMES_ROTATED_INPUT_LENGTH + 1:
                cases[values] = oracle(algorithm, list(values))
    elif algorithm == "endianness":
        for width, maximum in ((0, 0xffff), (1, 0xffffffff)):
            for value in (0, 1, 0x1234, maximum):
                if value <= maximum:
                    values = (width, value)
                    cases[values] = oracle(algorithm, list(values))
        for value in (I64_MIN, -1, 0, 1, I64_MAX):
            values = (2, value)
            cases[values] = oracle(algorithm, list(values))
        for operation in (3, 4):
            for count in range(1, 9):
                for payload in (bytes([0] * count), bytes(range(count)), bytes([255] * count)):
                    values = (operation, count, *payload)
                    cases[values] = oracle(algorithm, list(values))
        for operation in (5, 6):
            for count in range(1, 9):
                candidates = (0, 1, (1 << (8 * count)) - 1 if count < 8 else I64_MAX)
                for value in candidates:
                    values = (operation, value, count)
                    cases[values] = oracle(algorithm, list(values))
            values = (operation, I64_MIN, 8)
            cases[values] = oracle(algorithm, list(values))
        for values in ((), (0,), (0, -1), (0, 65536), (0, 1, 2),
                       (1, 1 << 32), (3, 0), (3, 2, 1), (3, 2, 1, 2),
                       (4, 1, 256), (5, -1, 1), (5, 256, 1), (5, 1, 0),
                       (6, 1, 9), (2, 1, 0)):
            cases[values] = oracle(algorithm, list(values))
        for _ in range(256):
            operation = rng.randrange(7)
            if operation in (0, 1):
                value = rng.randrange(1 << (16 if operation == 0 else 32))
                values = (operation, value)
            elif operation == 2:
                values = (2, rng.randrange(I64_MIN, I64_MAX + 1))
            elif operation in (3, 4):
                count = rng.randrange(1, 9)
                values = (operation, count, *(rng.randrange(256) for _ in range(count)))
            else:
                count = rng.randrange(1, 9)
                value = rng.randrange(1 << (8 * count)) if count < 8 else rng.randrange(I64_MIN, I64_MAX + 1)
                values = (operation, value, count)
            cases[values] = oracle(algorithm, list(values))
    elif algorithm == "lcm_of_n_numbers":
        for length in range(5):
            for values in product(range(6), repeat=length):
                cases[values] = oracle(algorithm, list(values))
        boundaries = [0, 1, 2, 3, 3037000499, 3037000500, I64_MAX - 1, I64_MAX]
        cases.update({(value,): oracle(algorithm, [value]) for value in boundaries})
        for left, right in product(boundaries, repeat=2):
            cases[(left, right)] = oracle(algorithm, [left, right])
        cases[(I64_MAX, 2, 0)] = 0
        cases[(I64_MAX, 2, 2)] = -1
        for _ in range(512):
            values = [rng.choice([0, 1, 2, 3, 5, I64_MAX, rng.getrandbits(63)])
                      for _ in range(rng.randrange(0, 18))]
            cases[tuple(values)] = oracle(algorithm, values)
    elif algorithm == "number_of_positive_divisors":
        for _ in range(128):
            values = [rng.randrange(-100_000, 100_001)]
            cases[tuple(values)] = oracle(algorithm, values)
        for values in ([], [I64_MIN], [I64_MAX], [-1_000_000_001],
                       [1_000_000_001], [12, 18], [0, 0]):
            cases[tuple(values)] = oracle(algorithm, list(values))
    elif algorithm == "divisors":
        for n in range(1, MAX_DIVISORS_N + 1):
            values = (n,)
            cases[values] = oracle(algorithm, list(values))
        for _ in range(128):
            values = (rng.randint(1, MAX_DIVISORS_N),)
            cases[values] = oracle(algorithm, list(values))
        malformed = ((), (0,), (-1,), (MAX_DIVISORS_N + 1,),
                     (I64_MIN,), (I64_MAX,), (1, 1), (MAX_DIVISORS_N, 1),
                     (1, 2, 3))
        for values in malformed:
            if len(values) <= MAX_DIVISORS_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
    elif algorithm == "modular_exponentiation":
        for base in range(-8, 9):
            for exponent in range(13):
                for modulus in range(1, 14):
                    values = (base, exponent, modulus)
                    cases[values] = oracle(algorithm, list(values))
        for _ in range(768):
            values = (rng.randint(MODULAR_EXPONENTIATION_I32_MIN,
                                  MODULAR_EXPONENTIATION_I32_MAX),
                      rng.randint(0, MODULAR_EXPONENTIATION_I32_MAX),
                      rng.randint(1, MODULAR_EXPONENTIATION_I32_MAX))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (2,), (2, 3), (2, 3, 5, 7),
            (MODULAR_EXPONENTIATION_I32_MIN - 1, 0, 7),
            (MODULAR_EXPONENTIATION_I32_MAX + 1, 0, 7),
            (2, -1, 7), (2, MODULAR_EXPONENTIATION_I32_MAX + 1, 7),
            (2, 3, 0), (2, 3, -1),
            (2, 3, MODULAR_EXPONENTIATION_I32_MAX + 1),
            (I64_MIN, 0, 7), (I64_MAX, 0, 7),
        )
        for values in malformed:
            if len(values) <= MAX_MODULAR_EXPONENTIATION_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
    elif algorithm == "modpow":
        for base in (0, 1, 2, MAX_MODPOW_COMPONENT // 2, MAX_MODPOW_COMPONENT):
            for exponent in range(MAX_MODPOW_EXPONENT + 1):
                for modulus in (1, 2, 7, MAX_MODPOW_COMPONENT - 1,
                                MAX_MODPOW_COMPONENT):
                    values = (base, exponent, modulus)
                    cases[values] = oracle(algorithm, list(values))
        for _ in range(512):
            values = (rng.randint(0, MAX_MODPOW_COMPONENT),
                      rng.randint(0, MAX_MODPOW_EXPONENT),
                      rng.randint(1, MAX_MODPOW_COMPONENT))
            cases[values] = oracle(algorithm, list(values))
        malformed = (
            (), (1,), (1, 2), (1, 2, 3, 4),
            (-1, 1, 7), (MAX_MODPOW_COMPONENT + 1, 1, 7),
            (1, -1, 7), (1, MAX_MODPOW_EXPONENT + 1, 7),
            (1, 1, 0), (1, 1, MAX_MODPOW_COMPONENT + 1),
            (0, 0, 1), (I64_MIN, 1, 7), (I64_MAX, 1, 7),
        )
        for values in malformed:
            if len(values) <= MAX_MODPOW_INPUT_LENGTH:
                cases[values] = oracle(algorithm, list(values))
    elif algorithm == "egg_dropping":
        for eggs in range(1, 13):
            for floors in range(1, 129, 7):
                values = [eggs, floors]
                cases[tuple(values)] = oracle(algorithm, values)
        for _ in range(128):
            values = [rng.randrange(1, 13), rng.randrange(1, 129)]
            cases[tuple(values)] = oracle(algorithm, values)
        for values in ([], [1], [1, 2, 3], [0, 1], [1, 0], [13, 1],
                       [1, 129], [-1, 10], [2, I64_MAX]):
            cases[tuple(values)] = oracle(algorithm, list(values))
    elif algorithm == "subarray_sum_equals_k":
        for _ in range(128):
            count = rng.randrange(0, 33)
            values = [count, rng.randrange(-20, 21),
                      *(rng.randrange(-10, 11) for _ in range(count))]
            cases[tuple(values)] = oracle(algorithm, values)
        maximum_zero_array = [512, 0, *([0] * 512)]
        cases[tuple(maximum_zero_array)] = oracle(algorithm, maximum_zero_array)
        for values in ([I64_MIN], [], [0], [-1, 0], [513, 0],
                       [1, 0], [1, 0, 0, 1], [0, I64_MIN],
                       [0, I64_MAX], [1, 0, I64_MIN], [1, 0, 2**31]):
            cases[tuple(values)] = oracle(algorithm, list(values))
    elif algorithm == "mode":
        for length in range(1, 8):
            for values in product(range(4), repeat=length):
                cases[values] = oracle(algorithm, list(values))
        for _ in range(512):
            values = [rng.randrange(256) for _ in range(rng.randrange(1, 257))]
            cases[tuple(values)] = oracle(algorithm, values)
        for values in ([], [0] * 4096, [0] * 4097, [-1, 1, 1], [256, 1, 1],
                       [1, 1, 2, 2], [0], [255] * 4096):
            cases[tuple(values)] = oracle(algorithm, list(values))
    elif algorithm == "n_bonacci":
        for order in range(1, 9):
            for count in range(order + 1, 25):
                values = [order, count]
                cases[tuple(values)] = oracle(algorithm, values)
        for _ in range(128):
            order = rng.randrange(1, 64)
            count = rng.randrange(order + 1, 65)
            values = [order, count]
            cases[tuple(values)] = oracle(algorithm, values)
        for values in ([], [1], [1, 2, 3], [0, 2], [-1, 2],
                       [3, 1], [3, 3], [1, 65], [64, 65]):
            cases[tuple(values)] = oracle(algorithm, list(values))
    elif algorithm == "problem18":
        for row_count in range(1, 9):
            width = row_count * (row_count + 1) // 2
            for _ in range(16):
                values = [row_count, *(rng.randrange(0, 1001) for _ in range(width))]
                cases[tuple(values)] = oracle(algorithm, values)
        for values in ([0], [1], [2, 1], [1, -1], [1, 1_000_001],
                       [1, 42, 99], [16]):
            cases[tuple(values)] = oracle(algorithm, list(values))
    elif algorithm == "alternate_harmonic_series":
        for count in range(1, 20):
            values = [count]
            values.extend(item for index in range(count)
                          for item in ((-1 if index % 2 else 1), index + 1))
            cases[tuple(values)] = oracle(algorithm, values)
        for _ in range(128):
            count = rng.randrange(1, 65)
            if rng.random() < 0.5:
                first_denominator = rng.randrange(1, 20)
                step = rng.randrange(1, 5)
                values = [count]
                values.extend(item for index in range(count)
                              for item in ((-1 if index % 2 else 1),
                                           first_denominator + step * index))
            else:
                values = [count]
                for index in range(count):
                    values.extend((rng.choice((-1, 1)) * rng.randrange(1, 1001),
                                   rng.randrange(1, 1001)))
            cases[tuple(values)] = oracle(algorithm, values)
        for values in ([0], [1001], [], [1, 0, 1], [1, 1, 0],
                       [1, 1001, 1], [1, 1, 1001], [2, 1, 1],
                       [2, 1, 1, -1, 1], [3, 1, 1, -1, 2, -1, 3]):
            cases[tuple(values)] = oracle(algorithm, list(values))
    elif algorithm == "alternating_harmonic_series":
        for count in range(0, 65):
            values = [count]
            values.extend(item for index in range(count)
                          for item in ((1 if index % 2 == 0 else -1), index + 1))
            cases[tuple(values)] = oracle(algorithm, values)
        for _ in range(128):
            count = rng.randrange(0, 65)
            values = [count]
            for _ in range(count):
                values.extend((rng.randrange(-1000, 1001), rng.randrange(1, 1001)))
            cases[tuple(values)] = oracle(algorithm, values)
        for values in ([], [1001], [0, 1], [1, 1], [1, 1, 0],
                       [1, 1001, 1], [1, 0, 1001], [2, 1, 1, 1],
                       [I64_MIN], [I64_MAX]):
            cases[tuple(values)] = oracle(algorithm, list(values))
    elif algorithm == "problem54":
        cards = list(range(52))
        for _ in range(4):
            values = []
            for _ in range(1000):
                values.extend(rng.sample(cards, 10))
            cases[tuple(values)] = oracle(algorithm, values)
        cases[tuple([*cases.keys()][0][:-1])] = -1
    elif algorithm == "problem67":
        pass
    elif algorithm == "problem22":
        for _ in range(128):
            names = [tuple(rng.randrange(1, 6) for _ in range(rng.randrange(1, 7)))
                     for _ in range(rng.randrange(0, 18))]
            values = [len(names)]
            for name in names:
                values.extend([len(name), *name])
            cases[tuple(values)] = oracle(algorithm, values)
    elif algorithm == "problem71":
        pairs = [(3, 7), (6, 7), (1, 2), (2, 5), (5, 12), (7, 9)]
        for numerator, denominator in pairs:
            for limit in (1, 2, 4, 8, 30, 60, 997, 5_000):
                values = [numerator, denominator, limit]
                cases[tuple(values)] = oracle(algorithm, values)
        for values in ([0, 1, 8], [1, 0, 8], [7, 7, 8], [6, 14, 60],
                       [3, 7, 0], [3, 7, 1_000_001], [], [3, 7, 8, 1]):
            cases[tuple(values)] = oracle(algorithm, list(values))
        for _ in range(32):
            denominator = rng.randrange(2, 2_001)
            numerator = rng.randrange(1, denominator)
            divisor = math.gcd(numerator, denominator)
            values = [numerator // divisor, denominator // divisor, rng.randrange(1, 5_001)]
            cases[tuple(values)] = oracle(algorithm, values)
    elif algorithm == "problem81":
        for dimension in range(1, 10):
            for _ in range(8):
                values = [dimension, *(rng.randrange(0, 10_000)
                                       for _ in range(dimension * dimension))]
                cases[tuple(values)] = oracle(algorithm, values)
        for values in ([0], [0, 1], [1], [1, 10000], [2, 1],
                       [1, -1], [1, 10000], [81], [2, *([1] * 3)],
                       [1, 42, 43], [I64_MIN, 1], [I64_MAX]):
            cases[tuple(values)] = oracle(algorithm, list(values))
    elif algorithm == "problem82":
        for rows in range(1, 7):
            for columns in range(1, 7):
                for _ in range(3):
                    values = [rows, columns, *(rng.randrange(0, 1000)
                                               for _ in range(rows * columns))]
                    cases[tuple(values)] = oracle(algorithm, values)
        for values in ([0, 1], [1, 0], [1, 1], [1, 1, 4], [2, 2, 1],
                       [1, 1, -1], [1, 1, 10000], [81, 1], [1, 81],
                       [1, 1, I64_MIN], [I64_MAX, 1]):
            cases[tuple(values)] = oracle(algorithm, list(values))
    elif algorithm == "problem99":
        pairs = [[], [1, 7, 3], [2, 2, 11, 3, 7],
                 [2, 519432, 525806, 632382, 518061],
                 [2, 2, 5, 2, 5], [2, 2, 10, 4, 5],
                 [2, 8, 3, 2, 9],
                 [2, 1, 1200000, 1000000, 0],
                 [1, 0, 2], [1, 2, -1], [1, 1000001, 2],
                 [1, 2, 1200001], [1001]]
        for values in pairs:
            cases[tuple(values)] = oracle(algorithm, values)
        for _ in range(64):
            count = rng.randrange(0, 12)
            values = [count]
            for _ in range(count):
                values.extend((rng.randrange(1, 1001), rng.randrange(0, 2001)))
            cases[tuple(values)] = oracle(algorithm, values)
    elif algorithm == "problem102":
        for _ in range(64):
            triangle_count = rng.randrange(1, 8)
            values = [rng.randrange(-1000, 1001) for _ in range(6 * triangle_count)]
            cases[tuple(values)] = oracle(algorithm, values)
        for values in ([], [0] * 5, [0] * 7, [1001, 0, 0, 1, 1, 0],
                       [0, 0, 1, 1, 2, 2]):
            cases[tuple(values)] = oracle(algorithm, list(values))
    elif algorithm == "problem107":
        for vertex_count in range(1, 9):
            for _ in range(8):
                values = [vertex_count]
                for row in range(1, vertex_count):
                    for _ in range(row):
                        values.append(rng.randrange(0, 100) if rng.random() < 0.75 else -1)
                cases[tuple(values)] = oracle(algorithm, values)
        for values in ([0], [2], [2, -1], [2, 1000], [3, 1, 1],
                       [1, 5], [41], [2, 0, 4]):
            cases[tuple(values)] = oracle(algorithm, list(values))
    elif algorithm == "problem345":
        for size in range(1, 9):
            for _ in range(8):
                values = [size, *(rng.randrange(0, 1001) for _ in range(size * size))]
                cases[tuple(values)] = oracle(algorithm, values)
        for values in ([0], [16], [2, 1, 2, 3], [2, -1, 0, 0, 0],
                       [1, 1001], [15, 1], [], [I64_MIN], [I64_MAX]):
            cases[tuple(values)] = oracle(algorithm, list(values))
    elif algorithm == "validate_credit_card":
        prefixes = ("4", "5", "6", "34", "35", "37", "2")
        for length in range(13, 17):
            for prefix in prefixes:
                for _ in range(24):
                    digits = prefix + "".join(str(rng.randrange(10)) for _ in range(length - len(prefix)))
                    values = [length, *(ord(character) for character in digits)]
                    cases[tuple(values)] = oracle(algorithm, values)
        for text in ("", "4111111111111", "4111111111111111", " 4111111111111",
                     "4111-1111-1111-1111", "411111111111111x", "41111111111111111"):
            values = [len(text), *(ord(character) for character in text)]
            cases[tuple(values)] = oracle(algorithm, values)
        for values in ([I64_MIN], [], [3, 49, 50], [1, -1], [1, 128],
                       [64, *([49] * 64)], [65, *([49] * 65)]):
            cases[tuple(values)] = oracle(algorithm, list(values))
    if algorithm == "chaining":
        operations = ((0, 0), (0, 1), (1, 0), (1, 1))
        for operation_count in range(6):
            for trace in product(operations, repeat=operation_count):
                for bucket_count in range(1, 4):
                    values = [bucket_count, operation_count,
                              *(item for operation in trace for item in operation)]
                    cases[tuple(values)] = oracle(algorithm, values)
        for _ in range(512):
            operation_count = rng.randrange(MAX_CHAINING_OPERATIONS + 1)
            bucket_count = rng.randrange(1, MAX_CHAINING_BUCKETS + 1)
            values = [bucket_count, operation_count]
            query_count = 0
            for _ in range(operation_count):
                operation = rng.randrange(2) if query_count < MAX_CHAINING_QUERIES else 0
                if operation == 1:
                    query_count += 1
                key = rng.choice((0, 1, bucket_count, 2 * bucket_count,
                                  rng.randrange(MAX_CHAINING_KEY + 1)))
                values.extend((operation, key))
            cases[tuple(values)] = oracle(algorithm, values)
        for values in (
            [], [1], [0, 0], [128, 0], [1, -1], [1, 1], [1, 1, 2, 0],
            [5, 1, 2, 0], [5, 1, 0], [5, 1, 0, -1],
            [5, 1, 0, MAX_CHAINING_KEY + 1], [5, 129, *([0, 1] * 129)],
            [5, 130, *([0, 1] * 130)], [5, 64, *([1, 1] * 64)],
        ):
            cases[tuple(values)] = oracle(algorithm, list(values))
    case_count = len(cases) + len(special_records)
    lines = [str(case_count) + "\n"]
    for values, expected in sorted(cases.items()):
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {expected}{suffix}\n")
    lines.extend(special_records)
    return "".join(lines), case_count


def verify(algorithm: str, language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(algorithm, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_scalar")
    checker = manifest["binaries"]["i64_array_scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"array scalar C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")
    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
                               "--build-manifest", str(directory / "build.json"),
                               "--samples", "1", "--warmups", "0", "--repetitions", "1",
                               "--output", str(output)], cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    for case, record in zip(workload["cases"], records):
        values = encode_case(case, algorithm)
        if (record["algorithm"] != algorithm
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": algorithm, "language": language, "status": "passed", "oracle_cases": case_count,
            "source_sha256": manifest["source_sha256"], "workload_records": len(records),
            "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--algorithms", nargs="+", choices=ALGORITHMS, default=list(ALGORITHMS))
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/i64_array_scalar")
    args = parser.parse_args()
    if (args.jobs < 1 or len(set(args.languages)) != len(args.languages)
            or len(set(args.algorithms)) != len(args.algorithms)):
        parser.error("jobs must be positive and algorithm/language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {}
        for algorithm in args.algorithms:
            workload_path = ROOT / "benchmarks" / algorithm[0] / algorithm / "workload.json"
            workload = json.loads(workload_path.read_text(encoding="utf-8"))
            data, case_count = corpus(algorithm, workload)
            (directory / f"{algorithm}-corpus.txt").write_text(data, encoding="utf-8")
            for language in args.languages:
                job = executor.submit(verify, algorithm, language,
                                      directory / algorithm / language,
                                      args.elisa_compiler, data, case_count, workload)
                jobs[job] = (algorithm, language)
        for job in as_completed(jobs):
            algorithm, language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                print(f"FAIL {algorithm}/{language}: {error}", file=sys.stderr)
                return 1
            results.append(result)
            print(f"PASS {algorithm}/{language}: {result['oracle_cases']} oracle arrays, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {"algorithms": args.algorithms, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(),
              "results": sorted(results, key=lambda item: (item["algorithm"], item["language"]))}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
