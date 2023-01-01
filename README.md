# Linear-Sensor-Network
Para este proyecto, se tomó como referencia la simulación de eventos discretos, esto debido a que el sistema se podía representar por una serie de eventos discretos y porque las variables que definen el estado del sistema van cambiando únicamente en un conjunto discreto de instantes de tiempo. Cabe mencionar que los eventos que pueden cambiar el estado del sistema son dos: la generación de paquetes y la tx/rx de paquetes. 
En el escenario de evaluación se tiene una red lineal de sensores, con las siguientes características.

•	Número de grados = 7
•	Número de nodos por grado = [5,10,15,20]
•	Longitud del buffer de cada nodo = 15 espacios
•	Número de miniranuras en la ventana de contención = [16,32,64,128,256]
•	Duración de cada miniranura en la ventana de contención = 1ms
•	Número de ranuras de sleeping por cada ciclo = 18
•	Tasa de generación de pkts por cada nodo = [0.0003, 0.003, 0.03]
•	Número de ciclos = 100,000. Esto debido a que con 300,000 ciclos, el tiempo de espera para terminar de ejecutar una simulación era demasiado extenso.

Así mismo, hay que tener en cuenta que:

•	Se considera un ruteo simple (si un pkt se recibió o generó en el nodo x del grado i, entonces este pkt se transmitirá al nodo x del grado i-1).
•	Al generarse los pkts, estos se asignan de forma aleatoria a un nodo de toda la red (con una distribución uniforme). 
•	La generación de pkts tiene una distribución de Poisson.
•	Los canales son ideales.
•	La tasa de transmisión es independiente a la tasa de generación de pkts (específicamente, la tasa de transmisión es 1).
•	Es un ruteo constante.
•	Uso de una calendarización consecutiva.
•	Uso de un protocolo de acceso CSMA-CA.
•	La transmisión es unidireccional, del grado i al grado i-1.
•	Los nodos que contienden por transmitir son aquellos que tienen por lo menos un espacio de su buffer ocupado.
•	No existe una retransmisión en el caso de que el pkt se pierda en la transmisión.  
