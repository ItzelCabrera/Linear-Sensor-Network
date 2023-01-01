function [node_g grade_g] = get_gen_info(c_node_g,I,N)
    node_g = mod(c_node_g,N);
    grade_g = floor((c_node_g-1)/N)+1;
    if (node_g == 0)
       node_g = N; 
    end
end
