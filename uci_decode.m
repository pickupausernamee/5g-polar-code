function rx_payload = uci_decode(encoded_uci, K, N, E, I_seg, I_BIL, q_info_list, q_pc_list, crc_length, payload_size)

% de-concatenation
if I_seg == 1
    code_block_number = 2;
    rx_rate_match_bits = cell(1, code_block_number);
    
    rx_rate_match_bits{1} = encoded_uci(1:length(encoded_uci)/2);
    rx_rate_match_bits{2} = encoded_uci((1+length(encoded_uci)/2):end);
    
else
    code_block_number = 1;
    rx_rate_match_bits{1} = encoded_uci;
    
end

rate_matching_pattern = rate_match_for_polar_code(1:N, K, N, E, I_BIL);

de_rate_matched_bits = cell(1, code_block_number);
% de-rate-match
for code_block_index = 1:code_block_number
    current_de_rx_match_bits = ones(1, N);
    current_de_rx_match_bits(rate_matching_pattern) = rx_rate_match_bits{code_block_index};
    de_rate_matched_bits{code_block_index} = current_de_rx_match_bits;
end

% polar decoding
frozen_bits_indicator = zeros(1, N);
frozen_bits_indicator(setdiff(1:N, q_info_list+1)) = 1;

n = log2(N);
bit_reverted_list = bit_revert(0:(N-1), n) + 1;
rx_code_block = cell(1, code_block_number);

% parameter for SCL decoding
% frozen_indices = (find(frozen_bits_indicator(bit_reverted_list) == 1)).';
% frozen_bits = zeros(length(frozen_indices), 1);
% channel_type = 'awgn';
% param = 0.987;
% list_size = 32;

for code_block_index = 1:code_block_number
    rx_code_block_prime = polar_decode(de_rate_matched_bits{code_block_index}, frozen_bits_indicator(bit_reverted_list));
     
%     rx_code_block_prime_1 = list_decode((de_rate_matched_bits{code_block_index}).', frozen_indices, frozen_bits, channel_type, param, list_size);
%     
%     if isequal(rx_code_block_prime, rx_code_block_prime_1.')
%       disp('SCL decoding succeeds.');
%     end
    
    bit_reverted_code_block = rx_code_block_prime(bit_reverted_list);
    rx_code_block{code_block_index} = bit_reverted_code_block(sort(q_info_list+1));
    
%     crc_result = crc_for_5g(rx_code_block{code_block_index}, num2str(crc_length));
    
%     if isequal(crc_result, zeros(1, crc_length))
%         fprintf('crc passed for the code block %d\n', code_block_index);
%     else
%         fprintf('crc failed for the code block %d\n', code_block_index);
%     end    
end

rx_payload = de_segment_for_polar_code(rx_code_block, code_block_number, crc_length, payload_size);

end
