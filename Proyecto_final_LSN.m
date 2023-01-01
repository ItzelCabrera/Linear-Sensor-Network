close all;clear all;clc;

%--------------variables globales-----------------------%
I = 7; %número de grados
N_ = [5,10,15,20]; %number of nodes peer grade 15 64 0.03
buffer_length = 15;
w_ = [16 32 64 128 256]; %number of minislots in the contention window
DIFS = 10e-3; %duration Distributed Interframe Space
SIFS = 5e-3; %duration Short Interframe Space
RTS = 11e-3;%duration of ready to send
CTS = 11e-3;%duration of clear to send
ACK = 11e-3;%duration of acknowledge
DATA = 43e-3; %duration of sending data
Gamma = 1e-3; %duration of minislots from the contention window
epsilon = 18; %sleeping slots
cycles = 100000; %number of cyles to simulate
lambda_node_ = [0.0003,0.003,0.03]; %generation rate peer node

%%
%--------------atributos de los nodos-----------------------%
    %grade => grado del nodo 
    %id_n => id del nodo de cierto grado
    %CE => capacidad de energía
    %state => estado del nodo
    %buffer_c => cantidad de espacios del buffer ocupados
    %buffer => arreglo que contiene los id de los pkts
    %contador_b => contador de backoff para la contención

%%
%-------------------------------------------------------------------------- BARRIDO DE GRADOS-------------------------------------------------------------------------%

%--------------atributos de los pkts-----------------------%
    %id_pkt => id del pkt, se relaciona al contador de pkts generados en la red
    %t_stamp1 => tiempo de generación del pkt
    %t_stamp2 => tiempo en el que entra al buffer
    %t_stamp3 => tiempo en el que llega a la punta del buffer
    %t_stamp4 => tiempo en el que se tx
    %c_node_g => id (a nivel global) del nodo al que se asigna el pkt
    %node_g => id (a nivel grado) del nodo al que se asigna el pkt
    %grade_g => grado al que se le asigna el pkt

for N = N_
    for w = w_
        for lambda_node = lambda_node_
            lambda_sys = lambda_node*N*I;%generation rate in the system
            T = Gamma*w+ DIFS + 3*SIFS + RTS + CTS + DATA + ACK; %tiempo de ranura
            Tc = T*(epsilon+2); %tiempo de ciclo
            %--------------PASO: GENERAN LOS NODOS-----------------------%
            ct = 0; %contador temp
            for g = 1:I
                for n = 1:N
                   ct = ct + 1;
                   buffer_l = 0; 
                   nodes(ct)=  struct('grade',g,'id_n',n,'CE',100,'state','on','buffer_c',buffer_l,'buffer',zeros(1,buffer_length),'contador_b',-1);
                end
            end
            %--------------------------------RESET DE VARIABLES -----------%
            t_sim = 0;
            ta = 0; %tiempo de arribo
            contadores_b = zeros(2,N); %array para contadores de backoff en un grado=> nodes(x),contador de backoff
            next_node = -1; %bandera para conocer a qué nodo se le va a tx
            id_pkt_tx = -1; %id del pkt que se va transmitir del grado i al grado i-1
            c_pkts_red = 0;%contador global de pkts en la red -> indice de la estructura pkt()
            c_pkts_g = 0; %contador global de pkts generados en la red -> attr id_pkt de la estructura pkt()
            c_pkts_perdidos = 0; %contador global de pkts perdidos
            array_pkts_perdidos = zeros(1,I);%cuenta de pkts perdidos por grado
            array_pkts_totales = zeros(1,I);%cuenta de pkts totales por grado => nodos generados en un grado + nodos recibidos en un grado
            array_retardo1 = zeros(1,I); %cuenta el retardo desde que entra al buffer hasta que llega al header, por grados
            array_retardo2 = zeros(1,I); %cuenta el retardo desde que llega al header hasta que sale del buffer, por grados
            c_r1 = 0;
            c_r2 = 0;
            %--------------PASO: GENERA EL PRIMER PKT DE LA RED-----------------------%
            c_node_g = randi([1,N*I]); %asigna de forma aleatoria uniforme el pkt a un nodo de la red
            c_pkts_red = c_pkts_red+1; 
            c_pkts_g = c_pkts_g+1;
            array_pkts_totales(floor((c_node_g-1)/N)+1) = array_pkts_totales(floor((c_node_g-1)/N)+1) + 1; %aumenta el contador de nodos en el grado
            pkt = struct('id_pkt',c_pkts_g,'t_stamp1',t_sim,'t_stamp2',-1,'t_stamp3',-1,'t_stamp4',-1,'c_node_g',c_node_g,'node_g',-1,'grade_g',-1);
            [pkt(c_pkts_red).node_g pkt(c_pkts_red).grade_g] = get_gen_info(c_node_g,I,N); %config del nodo y grado generador
            [nodes(c_node_g).buffer ,nodes(c_node_g).buffer_c] = add_pkt(nodes(c_node_g).buffer ,nodes(c_node_g).buffer_c,c_pkts_g);%agrega el id del pkt al buffer del nodo asignado
            pkt(1).t_stamp2 = t_sim;
            pkt(1).t_stamp3 = t_sim;

            for m = 1:cycles
                for i = fliplr([1:I]) %barrido de grados, desde el grado I hasta el grado 1
                   fprintf('{ANALIZANDO EL GRADO %d}\n',i)
                   %--------------PASO: RX-----------------------%
                   if(next_node ~= -1)%en el caso de que se puedan recibir pkts del grado superior
                       fprintf('[%d] -> ',nodes(next_node).buffer_c)
                       for o = 1:c_pkts_red
                          if(pkt(o).id_pkt == id_pkt_tx)
                            apuntador = o;
                          end
                       end
                       if(nodes(next_node).buffer_c ~= buffer_length)%si hay espacio en el buffer
                           [nodes(next_node).buffer ,nodes(next_node).buffer_c] = add_pkt(nodes(next_node).buffer ,nodes(next_node).buffer_c,id_pkt_tx);
                           pkt(apuntador).t_stamp2 = t_tx; %almacena el tiempo en que entró al buffer
                           fprintf('[%d] Rx exitosa! -> ',nodes(next_node).buffer_c)
                           fprintf('\n')
                           array_pkts_totales(i) = array_pkts_totales(i)+1; %aumenta el contador de nodos en el grado
                           if(nodes(next_node).buffer_c == 1) %si ya se encuentra en el header del buffer
                               pkt(apuntador).t_stamp3 = t_tx; %tiempo en el que llega al header del buffer
                               array_retardo1(i) = array_retardo1(i) + abs(pkt(apuntador).t_stamp3 - pkt(apuntador).t_stamp2) %aumenta los retardo1 del grado x
                               c_r1 = c_r1+1;
                           end
                       else
                           fprintf('Se pierde el pkt rx del grado %d, ya que no hay espacio en el buffer[%d]\n',i+1,nodes(next_node).buffer_c);
                           %--------------proceso de control de pkts-----------------------%
                           c_pkts_perdidos = c_pkts_perdidos +1; 
                           array_pkts_perdidos(i) = array_pkts_perdidos(i)+ 1;
                           pkt(apuntador) = []; %se elimina el pkt de la red 
                           c_pkts_red = c_pkts_red -1; %un pkt menos en la red
                       end
                   else
                       fprintf('No se tienen pkts del grado superior\n')
                   end 
                   t_sim = t_sim + T ; %paramos en el t_observación, para analizar la ranura que acaba de ocurrir: rx
                   fprintf('aumento t_sim dada la rx => %d\n',t_sim)
                   while (ta<= t_sim && t_sim ~= 0)
                        c_node_g = randi([1,N*I]); %asigna de forma aleatoria uniforme el pkt a un nodo de la red
                        fprintf('crea pkt en %d\n',c_node_g)
                        c_pkts_g = c_pkts_g+1; %se genera un pkt
                        array_pkts_totales(floor((c_node_g-1)/N)+1) = array_pkts_totales(floor((c_node_g-1)/N)+1) + 1; %aumenta el contador de nodos en el grado
                        if (nodes(c_node_g).buffer_c < 15)%si hay espacio para almacenar el pkt generado
                           c_pkts_red = c_pkts_red+1;%se agrega de forma exitosa un pkt a la red
                           pkt(c_pkts_red) = struct('id_pkt',c_pkts_g,'t_stamp1',ta,'t_stamp2',-1,'t_stamp3',-1,'t_stamp4',-1,'c_node_g',c_node_g,'node_g',-1,'grade_g',-1);
                           [pkt(c_pkts_red).node_g pkt(c_pkts_red).grade_g] = get_gen_info(c_node_g,I,N); %config del nodo y grado generador
                           [nodes(c_node_g).buffer ,nodes(c_node_g).buffer_c] = add_pkt(nodes(c_node_g).buffer ,nodes(c_node_g).buffer_c,c_pkts_g);%agrega el id del pkt al buffer del nodo asignado 
                           pkt(c_pkts_red).t_stamp2 = ta; %almacena el tiempo en que entró al buffer
                           if(nodes(c_node_g).buffer_c == 1) %si ya se encuentra en el header del buffer
                               pkt(c_pkts_red).t_stamp3 = ta; %tiempo en el que llega al header del buffer
                               array_retardo1(i) = array_retardo1(i) + abs(pkt(c_pkts_red).t_stamp3 - pkt(c_pkts_red).t_stamp2) %aumenta los retardo1 del grado x
                               c_r1 = c_r1 + 1;
                           end
                        else %si no hay espacio => se pierde un pkt
                            %--------------proceso de control de pkts-----------------------%
                            disp('No hay espacio para guardar el pkt generado')
                            c_pkts_perdidos = c_pkts_perdidos +1; 
                            array_pkts_perdidos(floor((c_node_g-1)/N)+1) = array_pkts_perdidos(floor((c_node_g-1)/N)+1)+ 1;
                        end
                        ta = arrival(ta,lambda_sys); %genera un nuevo tiempo de arribo
                    end

                  %--------------PASO: TX-----------------------%
                  c = 0;
                  for n_i = (i-1)*N+1:(i-1)*N+N %recorrido de los nodos del grado i
                      c = c+1;
                      if (nodes(n_i).buffer_c >0) %si el nodo tiene algo por transmitir
                          fprintf('grado: %d id: %d espacios libres: %d\n',nodes(n_i).grade,nodes(n_i).id_n,(buffer_length-nodes(n_i).buffer_c));
                          nodes(n_i).contador_b = randi([1,w]); %asigna el contador de backoff a aquellos nodos disponibles para contender
                      %almacena un registro de los contadores backoff asignados en este nivel
                          contadores_b(1,c) = n_i;
                          contadores_b(2,c) = nodes(n_i).contador_b;
                      else
                          contadores_b(1,c) = n_i;
                          contadores_b(2,c) = 500; %se asigna un número gde para que este nodo no contienda
                      end
                  end
                   [min_c_b,nodo_g] = min(contadores_b(2,:));%se encuentra el valor mín de contador de backoff
                   %--------------caso donde no hay nodos que contengan-----------------------%
                   if(min_c_b == 500)
                       disp('No hay nodos que contengan')
                   %--------------caso donde hay 2 o más contendientes con el mismo contador de backoff-----------------------%
                   elseif(length(find(contadores_b(2,:)==min_c_b)) > 1)%verifica el alguien más tiene ese contador de backoff
                       disp('Colisión en la ventana de contensión. Pérdida de pkt :c')
                       %--------------proceso de control de pkts => no hay tx-----------------------%
                       next_node = -1;%bandera para que en el próximo nivel se detecte que no se recibirá nada
                       id_pkt_tx = -1; %bandera para que ya no se retransmita ese pkt
                       %--------------proceso para eliminar todos los pkts colisionados => tx no exitosa-----------------------%
                       aux_colisionados = find(contadores_b(2,:)== min_c_b); %obtienen los id de los nodos que colisionaron en la ventana de contensión
                       for a = 1:length(aux_colisionados) %elimina cada pkt que haya colisionado; se elimina del buffer y se disminuye el contador de espacios ocupados en el buffer
                          c_pkts_perdidos = c_pkts_perdidos+1;
                          array_pkts_perdidos(i) = array_pkts_perdidos(i)+ 1;
                          for o = 1:c_pkts_red
                              if(pkt(o).id_pkt == nodes(N*i-(N-aux_colisionados(a))).buffer(1))
                                apuntador = o;
                              end
                              if(pkt(o).id_pkt == nodes(N*i-(N-aux_colisionados(a))).buffer(2))
                                next = o;
                              end
                          end
                          c_pkts_red = c_pkts_red-1;
                          nodes(N*i-(N-aux_colisionados(a))).buffer_c = nodes(N*i-(N-aux_colisionados(a))).buffer_c-1; %disminuye el contador de espacios ocupados del buffer del nodo colisionado
                          nodes(N*i-(N-aux_colisionados(a))).buffer = sacar_pkt(nodes(N*i-(N-aux_colisionados(a))).buffer); %se pierde el pkt colisionado
                          if(nodes(N*i-(N-aux_colisionados(a))).buffer_c > 0)%si se queda un pkt en la punta
                             pkt(next).t_stamp3 = t_sim; %ya que se actualizó el buffer (libera el pkt), se graba cuando se posiciona el otro pkt en la punta
                             array_retardo1(i) = array_retardo1(i) + abs(pkt(next).t_stamp3 - pkt(next).t_stamp2); %aumenta los retardo1 del grado x
                             c_r1 = c_r1+1;
                          end
                          pkt(apuntador) = []; %se elimina el pkt de la red 
                       end
                   %--------------caso donde solo hay un ganador => tx exitosa-----------------------%
                   else
                       fprintf('Nodo ganador del grado %d con id_n = %d obtuvo el contador de backoff = %d [%d]\n',i,nodo_g,min_c_b,nodes((i-1)*N+nodo_g).buffer_c);
                       nodes((i-1)*N+nodo_g).buffer_c = nodes((i-1)*N+nodo_g).buffer_c-1; %disminuye el contador de espacios ocupados del buffer del nodo ganador
                       fprintf('¡Buffer actualizado! [%d]\n',nodes((i-1)*N+nodo_g).buffer_c)
                       for o = 1:c_pkts_red
                          if(pkt(o).id_pkt == nodes((i-1)*N+nodo_g).buffer(1))
                            apuntador = o;
                          end
                          if(pkt(o).id_pkt == nodes((i-1)*N+nodo_g).buffer(2))
                            next = o;
                          end
                       end
                       pkt(apuntador).t_stamp4 = t_sim; %antes de liberar el pkt, tomamos su id_pkt y grabamos el instante en el que sale del buffer
                       t_tx = t_sim;
                       array_retardo2(i) = array_retardo2(i) + abs(pkt(apuntador).t_stamp4 - pkt(apuntador).t_stamp3);%aumenta los retardo2 del grado x
                       c_r2 = c_r2+1;
                       [nodes((i-1)*N+nodo_g).buffer id_pkt_tx] = sacar_pkt(nodes((i-1)*N+nodo_g).buffer);%libera el espacio en el buffer del nodo ganador
                       nodes((i-1)*N+nodo_g);
                       if(nodes((i-1)*N+nodo_g).buffer_c > 0)%si se queda un pkt en la punta
                           pkt(next).t_stamp3 = t_sim; %ya que se actualizó el buffer (libera el pkt), se graba cuando se posiciona el otro pkt en la punta
                           array_retardo1(i) = array_retardo1(i) + abs(pkt(next).t_stamp3 - pkt(next).t_stamp2); %aumenta los retardo1 del grado x
                           c_r1 = c_r1+1;
                       end
                       if(i >1)%si existe un grado más por transmitir
                           next_node = (i-2)*N+nodo_g; %el nodo x del grado i le mandará el pkt al nodo x del grado i-1
                           if(mod(next_node,N) == 0) %si se asigna al nodo N del grado i-1
                               fprintf('Se tx al nodo %d del grado %d\n',N,i-1)
                           else
                               fprintf('Se tx al nodo %d del grado %d\n',mod(next_node,N),i-1)
                           end
                       else
                           disp('El pkt está dando el salto al nodo sink!')
                           id_pkt_tx = -1;
                           next_node = -1;
                           pkt(apuntador) = [];%se elimina el pkt de la red, ya que no es necesario seguir almacenándolo
                           c_pkts_red = c_pkts_red-1;
                       end
                   end

                  t_sim = t_sim + T;%paramos en el t_observación, para analizar la ranura que acaba de ocurrir: tx
                  fprintf('aumento t_sim dada la tx => %d\n',t_sim)
                  while (ta<= t_sim && t_sim ~= 0)
                    c_node_g = randi([1,N*I]); %asigna de forma aleatoria uniforme el pkt a un nodo de la red
                    fprintf('crea pkt en %d\n',c_node_g)
                    c_pkts_g = c_pkts_g+1; %se genera un pkt
                    array_pkts_totales(floor((c_node_g-1)/N)+1) = array_pkts_totales(floor((c_node_g-1)/N)+1) + 1; %aumenta el contador de nodos en el grado
                    if (nodes(c_node_g).buffer_c < 15)%si hay espacio para almacenar el pkt generado
                       c_pkts_red = c_pkts_red+1;%se agrega de forma exitosa un pkt a la red
                       pkt(c_pkts_red) = struct('id_pkt',c_pkts_g,'t_stamp1',ta,'t_stamp2',-1,'t_stamp3',-1,'t_stamp4',-1,'c_node_g',c_node_g,'node_g',-1,'grade_g',-1);
                       [pkt(c_pkts_red).node_g pkt(c_pkts_red).grade_g] = get_gen_info(c_node_g,I,N); %config del nodo y grado generador
                       [nodes(c_node_g).buffer ,nodes(c_node_g).buffer_c] = add_pkt(nodes(c_node_g).buffer ,nodes(c_node_g).buffer_c,c_pkts_g);%agrega el id del pkt al buffer del nodo asignado 
                       pkt(c_pkts_red).t_stamp2 = ta; %almacena el tiempo en que entró al buffer
                       nodes(c_node_g);
                       if(nodes(c_node_g).buffer_c == 1) %si ya se encuentra en el header del buffer
                           pkt(c_pkts_red).t_stamp3 = ta; %tiempo en el que llega al header del buffer
                           array_retardo1(i) = array_retardo1(i) + abs(pkt(c_pkts_red).t_stamp3 - pkt(c_pkts_red).t_stamp2);%aumenta los retardo1 del grado x
                           c_r1 = c_r1+1;
                       end
                    else %si no hay espacio => se pierde un pkt
                        %--------------proceso de control de pkts-----------------------%
                        disp('No hay espacio para guardar el pkt generado')
                        c_pkts_perdidos = c_pkts_perdidos +1; 
                        array_pkts_perdidos(floor((c_node_g-1)/N)+1) = array_pkts_perdidos(floor((c_node_g-1)/N)+1)+ 1;
                    end
                    ta = arrival(ta,lambda_sys); %genera un nuevo tiempo de arribo  
                  end

                   disp('**********************************************************')
                end
                fprintf('[Terminó el barrido de nodos ]\n')
                t_sim = t_sim + T*(epsilon+2-I);
            end
            %%
            %-------------------------------------------------------------------------- RESULTADOS -------------------------------------------------------------------------%
            figure()
            stem([1:I],array_pkts_perdidos*100./array_pkts_totales)
            title(['Pkts perdidos. N = ',num2str(N),'/ w = ',num2str(w),'/ lambda node = ' num2str(lambda_node), '/ lambda sys = ', num2str(lambda_sys)])
            xlabel('grado')
            ylabel('%')

            for i = 1:I
                array_retardo1(i) = array_retardo1(i)/c_r1;
                array_retardo2(i) = array_retardo2(i)/c_r2; 
            end
            figure()
            stem([1:I],array_retardo1)
            title(['Retardo 1. N = ',num2str(N),'/ w = ',num2str(w),'/ lambda node = ' num2str(lambda_node), '/ lambda sys = ', num2str(lambda_sys)])
            xlabel('grado')
            ylabel('s')

            figure()
            stem([1:I],array_retardo2)
            title(['Retardo 2. N = ',num2str(N),'/ w = ',num2str(w),'/ lambda node = ' num2str(lambda_node), '/ lambda sys = ', num2str(lambda_sys)])
            xlabel('grado')
            ylabel('s')
            clear pkt
            clear nodes
        end
    end
end
%%
%-------------------------------------------------------------------------- FUNCIONES DE UTILIDAD -------------------------------------------------------------------------%
function [node_g grade_g] = get_gen_info(c_node_g,I,N)
    node_g = mod(c_node_g,N);
    grade_g = floor((c_node_g-1)/N)+1;
    if (node_g == 0)
       node_g = N; 
    end
end

function [new_buffer,new_buffer_l] = add_pkt(buffer,buffer_l,element)
    new_buffer_l = buffer_l + 1;
    pos_inicio = find(buffer>0,1);
    pos_final = find(buffer == 0,1);
    if(isempty(pos_inicio))
        new_buffer = [element buffer(pos_final:end-1)];
    else
        new_buffer = [buffer(pos_inicio:pos_final-1) element buffer(pos_final:end-1)];
    end
end

function ta = arrival(ti,lambda)
    u = 1e6*rand()/1e6;
    newt = -(1/lambda)*log(1-u);%new time, generated by a random variable
    ta = newt + ti;
end

function [new_array,pkt_id] = sacar_pkt(buffer)
    pkt_id = buffer(1);
    aux = buffer(2:end);
    new_array = [aux 0];
end

function pos = get_apuntador(buffer)
    pos = find(buffer == 0,1);
end