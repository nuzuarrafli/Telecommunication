fq = 28e9; % 28 GHz
noise_floor = -90.0103;
bandwidth = 50e6; %50MHz

txA = txsite("Name","Perpustakan Unsyiah", ...
    "Latitude",5.5682, ...
    "Longitude",95.3381,...
    'AntennaHeight',15,...
    "TransmitterPower",0.01, ...
    "AntennaAngle", 30,...
    "TransmitterFrequency",fq);

show(txA)
   
txB = txsite("Name","Perpustakan Unsyiah", ...
    "Latitude",5.5682, ...
    "Longitude",95.3381,...
    'AntennaHeight',15,...
    "TransmitterPower",0.01, ...
    "AntennaAngle", 150,...
    "TransmitterFrequency",fq);

show(txB)

txC = txsite("Name","Perpustakan Unsyiah", ...
    "Latitude",5.5682, ...
    "Longitude",95.3381,...
    'AntennaHeight',15,...
    "TransmitterPower",0.01, ...
    "AntennaAngle", 270,...
    "TransmitterFrequency",fq);
show(txC)

%[lat,lon] = location(txA,10,0)
%[lat,lon] = location(txA,20,30)
%[lat,lon] = location(txA,30,60)

%[lat,lon] = location(txA,40,150)
%[lat,lon] = location(txA,50,180)
%[lat,lon] = location(txA,60,120)

%[lat,lon] = location(txA,70,270)
%[lat,lon] = location(txA,80,300)
%[lat,lon] = location(txA,90,240)

%[lat,lon] = location(txA,100,360)

rx1 = rxsite("Name","micro site 1", ...
    "Latitude",5.5682, ...
    "Longitude",95.3382);%
rx2 = rxsite("Name","micro site 2", ...
   "Latitude",  5.5683, ...
   "Longitude", 95.3383);%
rx3 = rxsite("Name","micro site 3", ...
    "Latitude", 5.5684, ...
    "Longitude", 95.3382);%
rx4 = rxsite("Name","micro site 4", ...
    "Latitude", 5.5684, ...
   "Longitude",95.3378);%
rx5 = rxsite("Name","micro site 5", ...
   "Latitude",  5.5682, ...
   "Longitude", 95.3376);%
rx6 = rxsite("Name","micro site 6", ...
    "Latitude", 5.5687, ...
    "Longitude", 95.3378);%
rx7 = rxsite("Name","micro site 7", ...
    "Latitude",5.5676, ...
    "Longitude",95.3381);%
rx8 = rxsite("Name","micro site 8", ...
   "Latitude",  5.5676, ...
   "Longitude", 95.3385);%
rx9 = rxsite("Name","micro site 9", ...
    "Latitude", 5.5675, ...
   "Longitude",  95.3377);
rx10 = rxsite("Name","micro site 10", ...
    "Latitude",5.5682, ...
    "Longitude",95.3390);%%

%dm = distance(txA,rx1)
% Unit: m

rxsA = [rx1, rx2, rx3, rx10]; %30derajat
rxsB = [rx4, rx5, rx6]; %150derajat
rxsC = [rx9, rx7, rx8];%270 derajat
show(rxsA)
show(rxsB)
show(rxsC)

% Define pattern parameters
azvec = -180:180;
elvec = -90:90;
Am = 30; % Maximum attenuation (dB)
tilt = 20; % Tilt angle
az3dB = 65; % 3 dB bandwidth in azimuth
el3dB = 65; % 3 dB bandwidth in elevation

% Define antenna pattern
[az,el] = meshgrid(azvec,elvec);
azMagPattern = -12*(az/az3dB).^2;
elMagPattern = -12*((el-tilt)/el3dB).^2;
combinedMagPattern = azMagPattern + elMagPattern;
combinedMagPattern(combinedMagPattern<-Am) = -Am; % Saturate at max attenuation
phasepattern = zeros(size(combinedMagPattern));

% Create antenna element
antennaElement = phased.CustomAntennaElement(...
    'AzimuthAngles',azvec, ...
    'ElevationAngles',elvec, ...
    'MagnitudePattern',combinedMagPattern, ...
    'PhasePattern',phasepattern);
   
% Display radiation pattern
pattern(antennaElement,fq);

% Assign array to each receiver site and point toward base station
for rx = rxsA
    rx.Antenna = antennaElement;
    rx.AntennaAngle = angle(rx, txA);
end
for rx = rxsB
    rx.Antenna = antennaElement;
    rx.AntennaAngle = angle(rx, txB);
end
for rx = rxsC
    rx.Antenna = antennaElement;
    rx.AntennaAngle = angle(rx, txC);
end


% Define array size
nrow = 16;
ncol = 16;

% Define element spacing
lambda = physconst('lightspeed')/fq;
drow = lambda/2;
dcol = lambda/2;

% Define taper to reduce sidelobes 
dBdown = 30;
taperz = chebwin(nrow,dBdown);
tapery = chebwin(ncol,dBdown);
tap = taperz*tapery.'; % Multiply vector tapers to get 8-by-8 taper values
    

% Display radiation pattern
pattern(antennaElement,fq)


txA.Antenna = phased.URA('Size',[nrow ncol], ...
    'Element',antennaElement, ...
    'ElementSpacing',[drow dcol], ...
    'Taper',tap, ...
    'ArrayNormal','x');

% Plot pattern on the map
pattern(txA)

txB.Antenna = phased.URA('Size',[nrow ncol], ...
    'Element',antennaElement, ...
    'ElementSpacing',[drow dcol], ...
    'Taper',tap, ...
    'ArrayNormal','x');
% Plot pattern on the map
pattern(txB)

txC.Antenna = phased.URA('Size',[nrow ncol], ...
    'Element',antennaElement, ...
    'ElementSpacing',[drow dcol], ...
    'Taper',tap, ...
    'ArrayNormal','x');

% Plot pattern on the map
pattern(txC)

txs = [txA, txB, txC];

downtilt = 20;
for tx = txs
    tx.Antenna = antennaElement;
    tx.AntennaAngle = [tx.AntennaAngle; -downtilt];
end


% Compute signal strength (dBm)
for rx = rxsA
    ss = sigstrength(rx,txA,"freespace");
    disp("Signal strength at " + rx.Name + ":")
    disp(ss + " dBm")
end

% Compute signal strength (dBm)
for rx = rxsB
    ss = sigstrength(rx,txB,"freespace");
    disp("Signal strength at " + rx.Name + ":")
    disp(ss + " dBm")
end

% Compute signal strength (dBm)
for rx = rxsC
    ss = sigstrength(rx,txC,"freespace");
    disp("Signal strength at " + rx.Name + ":")
    disp(ss + " dBm")
end

% Assume that propagation path travels through 25 m of foliage
foliageDepth = 10;
L = (0.2)*(28.^(0.3))*(foliageDepth.^(0.6));
disp("Path loss due to foliage: " + L + " dB")

% Assign foliage loss as static SystemLoss on each receiver site
for rx = rxsA
    rx.SystemLoss = L;
end
% Compute signal strength with foliage loss
for rx = rxsA
    rx.SystemLoss = L;
    ss = sigstrength(rx,txA,"freespace");
    disp("Signal strength at " + rx.Name + ":")
    disp(ss + " dBm")
end

% Assign foliage loss as static SystemLoss on each receiver site
for rx = rxsB
    rx.SystemLoss = L;
end
% Compute signal strength with foliage loss
for rx = rxsB
    rx.SystemLoss = L;
    ss = sigstrength(rx,txB,"freespace");
    disp("Signal strength at " + rx.Name + ":")
    disp(ss + " dBm")
end

% Assign foliage loss as static SystemLoss on each receiver site
for rx = rxsC
    rx.SystemLoss = L;
end

% Compute signal strength with foliage loss
for rx = rxsC
    rx.SystemLoss = L;
    ss = sigstrength(rx,txC,"freespace");
    disp("Signal strength at " + rx.Name + ":")
    disp(ss + " dBm")
end

% Compute signal strength including propagation through gas and rain. Use
% the "+" operator to add the propagation models to create a composite
% model including both atmospheric effects.
weatherpm = propagationModel("gas") + propagationModel("rain");
for rx = rxsA
    ss = sigstrength(rx,txA,weatherpm);
    disp("Signal strength with  gas and rain at " + rx.Name + ":")
    disp(ss + " dBm")
    
    % Compute Bit Rate for each receiver site
    SINR = ss - noise_floor
    Bitrate = bandwidth*(log2(1+SINR)); %ShannonCapacity
    disp("Bitrate at " + rx.Name + ":")
    disp(Bitrate + " bit/s")
end
for rx = rxsB
    ss = sigstrength(rx,txB,weatherpm);
    disp("Signal strength with  gas and rain at " + rx.Name + ":")
    disp(ss + " dBm")
    
    % Compute Bit Rate for each receiver site
    SINR = ss - noise_floor
    Bitrate = bandwidth*(log2(1+SINR)); %ShannonCapacity
    disp("Bitrate at " + rx.Name + ":")
    disp(Bitrate + " bit/s")
end
for rx = rxsC
    ss = sigstrength(rx,txC,weatherpm);
    disp("Signal strength with  gas and rain at " + rx.Name + ":")
    disp(ss + " dBm")
    
    % Compute Bit Rate for each receiver site
    SINR = ss - noise_floor
    Bitrate = bandwidth*(log2(1+SINR)); %ShannonCapacity
    disp("Bitrate at " + rx.Name + ":")
    disp(Bitrate + " bit/s")
end

