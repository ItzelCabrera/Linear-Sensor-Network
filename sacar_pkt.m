function [new_array,pkt_id] = sacar_pkt(buffer)
    pkt_id = buffer(1);
    aux = buffer(2:end);
    new_array = [aux 0];
end