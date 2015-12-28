%#########################################################################
%############ EPI_NI_ADQ_V0.m ############################################
%#########################################################################
%
%NO SE UTILIZAN ACENTOS PARA FACILITAR PROBLEMAS DE COMPATIBILIDAD.
%
%Este script captura datos de la tarjeta NI-USB-9192 con la tarjeta NI9234
%conectada a ella.
%Autores: Felipe Martinez y Carlos Poblete
%INDICACIONES:
%SOLAMENTE EL NI USB-9162 debe estar conectado al PC, ningu otro adquisidor
%de datos.
%Se asignan los canales en orden, del 0 al 3.
%Limpiamos la pantalla
clc;
%Remueve todas las variables de memoria
clear all;
%Mejor aproximcion o formato de punto flotante con 15 digitos para DOUBLE
%y 7 dígitos para SINGLE
format longg;
%Define la duracion de cada registro, debiese ingresarse como parametro?
duration_time_sec=5;
%Define los SPS con que se adquiere los datos.
%debiese ingresarse como parametro? cuáles son las frecuencias de muestreo
%que acepta el dispositivo.
samples_per_sec=2048;
%Indica el registro actual e que se encuentra el script
actual_register=0;
%El numero total de registros a adquirir
max_number_register=3;
%Esta variable guarda todos los nombres de los registros.
archivos=nan;
%Elimina los warning que genera el toolbox de NI.
warning('off', 'all');
%WHILE principal de adquisición
fprintf('Bienvenido\n');
canales=99; % ASEGURAMOS QUE SE EJECUTE AL MENOS UNA VEZ LA PREGUNTA
%Se selecciona  la cantidad de canales a usar.
while (canales ~= 4)&& (canales ~= 1)&&(canales ~= 2)&&(canales ~= 3)
    canales=input('Cuantos canales se usaran [1,2,3,4]\n[hit enter for 4 channels]\n|>>');
    if isempty(canales)
        canales = 4;
    end
end
fprintf('Se empieza la adquisición para %d canales\n',canales);
%WHILE de adquisicion de datos
while(actual_register<max_number_register)
    actual_register=actual_register+1;  %se aumenta en 1 los registros
    c=datestr(clock,'yyyy-mm-ddTHH-MM-SS'); % formato de hora es tentativo, puesde estar sujeto a cambios.
    filename=['RBA',c,'.txt'];  %se crea el nombre el archivo
    fprintf('Se escribirá el siguiente archivo: %s\n',filename);
    if actual_register==1  %si esta en el primer archivo guarda en la variable
        archivos=filename;
    else   % sino agrega el nombre del archivo a la lista ya existente
        archivos=[archivos;filename]; %manda warning porque el arreglo crece dentro del loop
    end
    device=daq.getDevices; % RECUERDE QUE SOLAMENTE DEBE ESTAR UNA TARJETA ADQUISIDORA CONECTADDA.
    session=daq.createSession('ni');
    %SE GENERAN LOS CANALES DE ADQUISICION
    for j=1:canales
        v = genvarname('channel', char(j));
        eval([v ' = addAnalogInputChannel(session,device.ID,(j-1),''voltage'');']);
    end
    session.Rate=samples_per_sec;%SPS
    session.DurationInSeconds=duration_time_sec; % DURACION DE REGISTROS
    [data,time_stamp] = session.startForeground();
    ID=fopen(filename,'w');
    %SE IMPRIME EL HEADER, ESTO SE PUEDE ELIMINAR
    fprintf(ID,'%s####        HEADER         ####\n','%');
    fprintf(ID,'%s#### SPS %d\n','%',session.Rate);
    fprintf(ID,'%s#### Archivo %s\n','%',filename);
    fprintf(ID,'%s#### Duracion %d seg\n','%',session.DurationInSeconds);
    clear session; % SE ELIMINA LA SESION EN ESTA ITERACION
    for i=1:size(data,1)
        fprintf(ID,'%f;%f;%f;%f;%f',time_stamp(i),data(i,1:canales)); %SE IMPRIMEN LOS DATOS
        %SI SE SELECCIONA MENOS DE 4 CANALES, CADA LINEA DE REGISTRO
        %TERMINA CON ;
        if i < size(data,1)
            fprintf(ID,'\n');
        end
    end
    fclose(ID);
    fprintf('Se escribe correctamente %s\n',filename);
    %figure,plot(time_stamp,data);
end
fprintf('Los archivos escritos durante esta sesión\nde adquisición son:\n');
for i=1:size(archivos,1)
    fprintf('%d %s\n',i,archivos(i,:));
end
answ2=input('Cual desea plotear? [Ingrese numero, hit enter for exit]\n|>>');
while  answ2<= size(archivos,1) 
    DataImported=importdata(archivos(answ2,:));
    figure,legend,plot (DataImported.data(:,1),DataImported.data(:,2:canales+1));
    fprintf('Los archivos escritos durante esta sesión\n de adquisición son:\n');
    for i=1:size(archivos,1)
        fprintf('%d %s\n',i,archivos(i,:));
    end
    answ2=input('Cual desea plotear? [Ingrese numero, hit enter for exit]\n|>>');
end
fprintf('Ejecucion terminada');
