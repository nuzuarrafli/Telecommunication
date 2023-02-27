fq = 28e9; % 28 GHz
noise_floor = -90.0103;
bandwidth = 500000000; %500MHz

tx = txsite("Name","Macrosite 2 A", ...
    'Latitude', 5.566622, ...
    'Longitude',95.335341, ...
    'AntennaHeight',25,...
    "TransmitterPower",0.01 , ... %in Watt
    "AntennaAngle", 0,...
    "TransmitterFrequency",fq);

show(tx)

rx1 = rxsite("Name","micro site 1", ...
    "Latitude",5.5682, ...
    "Longitude",95.3381);
rx2 = rxsite("Name","micro site 2", ...
   "Latitude",  5.5666, ...
   "Longitude", 95.3372);
rx3 = rxsite("Name","micro site 3", ...
    "Latitude", 5.5683, ...
    "Longitude", 95.3363);

rxs = [rx1, rx2, rx3];
show(rxs)

rx1.AntennaHeight = 15;
rx2.AntennaHeight = 15;
rx3.AntennaHeight = 15;

% Define pattern parameters
azvec = -180:180;
elvec = -90:90;
Am = 30; % Maximum attenuation (dB)
tilt = 0; % Tilt angle
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
f = figure;
pattern(antennaElement,fq);

% Define array size
nrow = 16;
ncol = 8;

% Define element spacing
lambda = physconst('lightspeed')/fq;
drow = lambda/2;
dcol = lambda/2;

% Define taper to reduce sidelobes 
dBdown = 30;
taperz = chebwin(nrow,dBdown);
tapery = chebwin(ncol,dBdown);
tap = taperz*tapery.'; % Multiply vector tapers to get 8-by-8 taper values

tx.Antenna = phased.URA('Size',[nrow ncol], ...
    'Element',antennaElement, ...
    'ElementSpacing',[drow dcol], ...
    'Taper',tap, ...
    'ArrayNormal','x');

pattern(tx.Antenna,fq);

% Plot pattern on the map
pattern(tx)

% Define array size
nrxrow = 16;
nrxcol = 8;

% Define element spacing
lambda = physconst("lightspeed")/fq;
drow = lambda/2;
dcol = lambda/2;
taperz1 = chebwin(nrxrow,dBdown);
tapery1 = chebwin(nrxcol,dBdown);
tap1 = taperz1*tapery1.'; % Multiply vector tapers to get 8-by-8 taper values



rxarray = phased.URA("Size",[nrxrow nrxcol], ...
    "Element",antennaElement, ...
    "ElementSpacing",[drow dcol],...
    'Taper',tap1, ...
    'ArrayNormal','x');


% Assign array to each receiver site and point toward base station
for rx = rxs
    rx.Antenna = rxarray;
    rx.AntennaAngle = angle(rx, tx);
    pattern(rx, fq)
end

steeringVector = phased.SteeringVector("SensorArray",tx.Antenna);
for rx = rxs
    % Compute steering vector for receiver site
    [az,el] = angle(tx,rx);
    sv = steeringVector(fq,[az;el]);
    
    % Update base station radiation pattern
    tx.Antenna.Taper = conj(sv);
    pattern(tx)
    
end

steeringVector = phased.SteeringVector("SensorArray",tx.Antenna);

% Compute steering vector for receiver site
[az,el] = angle(tx,rxs);
sv = steeringVector(fq,[az el]');

% Update base station radiation pattern
tx.Antenna.Taper = conj(sum(sv,2));
pattern(tx)

% Compute signal strength (dBm)
for rx = rxs
    ss = sigstrength(rx,tx,"freespace");
    disp("Signal strength at " + rx.Name + ":")
    disp(ss + " dBm")
end

% Assume that propagation path travels through 25 m of foliage
foliageDepth = 10;
L = (0.2)*(28.^(0.3))*(foliageDepth.^(0.6));
disp("Path loss due to foliage: " + L + " dB")

% Assign foliage loss as static SystemLoss on each receiver site
for rx = rxs
    rx.SystemLoss = L;
end

% Compute signal strength with foliage loss
for rx = rxs
    rx.SystemLoss = L;
    ss = sigstrength(rx,tx,"freespace");
    disp("Signal strength at " + rx.Name + ":")
    disp(ss + " dBm")
end

% Compute signal strength including propagation through gas and rain. Use
% the "+" operator to add the propagation models to create a composite
% model including both atmospheric effects.
weatherpm = propagationModel("gas") + propagationModel("rain");
for rx = rxs
    ss = sigstrength(rx,tx,weatherpm);
    disp("Signal strength with  gas and rain at " + rx.Name + ":")
    disp(ss + " dBm")
    
    % Compute Bit Rate for each receiver site
    % eb/n0 is 17.5 in Half-QPSK
    SINR = ss - noise_floor;
    Bitrate = bandwidth*(log2(1+SINR)); %ShannonCapacity
    disp("Bitrate at " + rx.Name + ":")
    disp(Bitrate + " bit/s")
end


fq = 28e9; % 28 GHz

tx1 = txsite("Name","Macrosite 2 B", ...
    'Latitude', 5.566622, ...
    'Longitude',95.335341, ...
    'AntennaHeight',25,...
    "TransmitterPower",0.01, ...
    "AntennaAngle", 130,... %150%
    "TransmitterFrequency",fq);

show(tx1)

rx4 = rxsite("Name","micro site 4", ...
    "Latitude",5.5682, ...
    "Longitude", 95.3326);
rx5 = rxsite("Name","micro site 5", ...
   "Latitude",  5.5666, ...
   "Longitude", 95.3335);
rx6 = rxsite("Name","micro site 6", ...
    "Latitude", 5.5682, ...
    "Longitude", 95.3344);

rxs1 = [rx4, rx5, rx6];
show(rxs1)

rx4.AntennaHeight = 20;
rx5.AntennaHeight = 20;
rx6.AntennaHeight = 20;


tx1.Antenna = phased.URA('Size',[nrow ncol], ...
    'Element',antennaElement, ...
    'ElementSpacing',[drow dcol], ...
    'Taper',tap, ...
    'ArrayNormal','x');


% Plot pattern on the map
pattern(tx1)


% Assign array to each receiver site and point toward base station
for rx = rxs1
    rx.Antenna = rxarray;
    rx.AntennaAngle = angle(rx, tx1);
    pattern(rx,fq)
end

steeringVector = phased.SteeringVector("SensorArray",tx1.Antenna);
for rx = rxs1
    % Compute steering vector for receiver site
    [az,el] = angle(tx1,rx);
    sv = steeringVector(fq,[az;el]);
    
    % Update base station radiation pattern
    tx1.Antenna.Taper = conj(sv);
    pattern(tx1)
    
end

steeringVector = phased.SteeringVector("SensorArray",tx1.Antenna);

% Compute steering vector for receiver site
[az,el] = angle(tx1,rxs1);
sv = steeringVector(fq,[az el]');

% Update base station radiation pattern
tx1.Antenna.Taper = conj(sum(sv,2));
pattern(tx1)

% Compute signal strength (dBm)
for rx = rxs1
    ss = sigstrength(rx,tx1,"freespace");
    disp("Signal strength at " + rx.Name + ":")
    disp(ss + " dBm")
end

% Assume that propagation path travels through 25 m of foliage
foliageDepth = 10;
L = (0.2)*(28.^(0.3))*(foliageDepth.^(0.6));
disp("Path loss due to foliage: " + L + " dB")

% Assign foliage loss as static SystemLoss on each receiver site
for rx = rxs1
    rx.SystemLoss = L;
end

% Compute signal strength with foliage loss
for rx = rxs1
    rx.SystemLoss = L;
    ss = sigstrength(rx,tx1,"freespace");
    disp("Signal strength at " + rx.Name + ":")
    disp(ss + " dBm")
end

% Compute signal strength including propagation through gas and rain. Use
% the "+" operator to add the propagation models to create a composite
% model including both atmospheric effects.
weatherpm = propagationModel("gas") + propagationModel("rain");
for rx = rxs1
    ss = sigstrength(rx,tx1,weatherpm);
    disp("Signal strength with  gas and rain at " + rx.Name + ":")
    disp(ss + " dBm")
    
    % Compute Bit Rate for each receiver site
    SINR = ss - noise_floor;
    Bitrate = bandwidth*(log2(1+SINR)); %ShannonCapacity
    disp("Bitrate at " + rx.Name + ":")
    disp(Bitrate + " bit/s")
end



fq = 28e9; % 28 GHz

tx2 = txsite("Name","Macrosite 2 C", ...
    'Latitude', 5.566622, ...
    'Longitude',95.335341, ...
    'AntennaHeight',25,...
    "TransmitterPower",0.01, ...
    "AntennaAngle", 270,...
    "TransmitterFrequency",fq);

show(tx2)

rx7 = rxsite("Name","micro site 7", ...
    "Latitude",5.5635, ...
    "Longitude", 95.3353);
rx8 = rxsite("Name","micro site 8", ...
   "Latitude",  5.5651, ...
   "Longitude", 95.3362);
rx9 = rxsite("Name","micro site 9", ...
    "Latitude", 5.5651, ...
    "Longitude", 95.3344);

rxs2 = [rx7, rx8, rx9];
show(rxs2)

rx7.AntennaHeight = 20;
rx8.AntennaHeight = 20;
rx9.AntennaHeight = 20;


tx2.Antenna = phased.URA('Size',[nrow ncol], ...
    'Element',antennaElement, ...
    'ElementSpacing',[drow dcol], ...
    'Taper',tap, ...
    'ArrayNormal','x');


% Plot pattern on the map
pattern(tx2)



% Assign array to each receiver site and point toward base station
for rx = rxs2
    rx.Antenna = rxarray;
    rx.AntennaAngle = angle(rx, tx2);
    pattern(rx,fq)
end

steeringVector = phased.SteeringVector("SensorArray",tx2.Antenna);
for rx = rxs2
    % Compute steering vector for receiver site
    [az,el] = angle(tx2,rx);
    sv = steeringVector(fq,[az;el]);
    
    % Update base station radiation pattern
    tx1.Antenna.Taper = conj(sv);
    pattern(tx2)
    
end

steeringVector = phased.SteeringVector("SensorArray",tx1.Antenna);

% Compute steering vector for receiver site
[az,el] = angle(tx2,rxs2);
sv = steeringVector(fq,[az el]');

% Update base station radiation pattern
tx2.Antenna.Taper = conj(sum(sv,2));
pattern(tx2)

% Compute signal strength (dBm)
for rx = rxs2
    ss = sigstrength(rx,tx2,"freespace");
    disp("Signal strength at " + rx.Name + ":")
    disp(ss + " dBm")
end

% Assume that propagation path travels through 25 m of foliage
foliageDepth = 10;
L = (0.2)*(28.^(0.3))*(foliageDepth.^(0.6));
disp("Path loss due to foliage: " + L + " dB")

% Assign foliage loss as static SystemLoss on each receiver site
for rx = rxs2
    rx.SystemLoss = L;
end

% Compute signal strength with foliage loss
for rx = rxs2
    rx.SystemLoss = L;
    ss = sigstrength(rx,tx2,"freespace");
    disp("Signal strength at " + rx.Name + ":")
    disp(ss + " dBm")
end

% Compute signal strength including propagation through gas and rain. Use
% the "+" operator to add the propagation models to create a composite
% model including both atmospheric effects.
weatherpm = propagationModel("gas") + propagationModel("rain");
for rx = rxs2
    ss = sigstrength(rx,tx2,weatherpm);
    disp("Signal strength with  gas and rain at " + rx.Name + ":")
    disp(ss + " dBm")
    
    % Compute Bit Rate for each receiver site
    SINR = ss - noise_floor;
    Bitrate = bandwidth*(log2(1+SINR)); %ShannonCapacity
    disp("Bitrate at " + rx.Name + ":")
    disp(Bitrate + " bit/s")
end









    
fq = 28e9; % 28 GHz

tx3 = txsite("Name","Perpustakan Unsyiah", ...
    "Latitude", 5.5632, ...
    "Longitude",95.3295,...
    'AntennaHeight',25,...
    "TransmitterPower",0.01, ...
    "AntennaAngle", 0,... %30
    "TransmitterFrequency",fq);

show(tx3)

rx10 = rxsite("Name","Bandar Baru 10", ...
    "Latitude",5.5648, ...
    "Longitude",95.3322);
rx11 = rxsite("Name","Bandar Baru 11", ...
   "Latitude",  5.5632, ...
   "Longitude", 95.3313);
rx12 = rxsite("Name","Bandar Baru 12", ...
    "Latitude", 5.5648, ...
    "Longitude", 95.3304);

rxs3 = [rx10, rx11, rx12];
show(rxs3)

rx10.AntennaHeight = 20;
rx11.AntennaHeight = 20;
rx12.AntennaHeight = 20;


tx3.Antenna = phased.URA('Size',[nrow ncol], ...
    'Element',antennaElement, ...
    'ElementSpacing',[drow dcol], ...
    'Taper',tap, ...
    'ArrayNormal','x');


% Plot pattern on the map
pattern(tx3)



% Assign array to each receiver site and point toward base station
for rx = rxs3
    rx.Antenna = rxarray;
    rx.AntennaAngle = angle(rx, tx3);
    pattern(rx,fq)
end

steeringVector = phased.SteeringVector("SensorArray",tx3.Antenna);
for rx = rxs3
    % Compute steering vector for receiver site
    [az,el] = angle(tx3,rx);
    sv = steeringVector(fq,[az;el]);
    
    % Update base station radiation pattern
    tx.Antenna.Taper = conj(sv);
    pattern(tx3)
    
end

steeringVector = phased.SteeringVector("SensorArray",tx3.Antenna);

% Compute steering vector for receiver site
[az,el] = angle(tx3,rxs3);
sv = steeringVector(fq,[az el]');

% Update base station radiation pattern
tx3.Antenna.Taper = conj(sum(sv,2));
pattern(tx3)

% Compute signal strength (dBm)
for rx = rxs3
    ss = sigstrength(rx,tx3,"freespace");
    disp("Signal strength at " + rx.Name + ":")
    disp(ss + " dBm")
end

% Assume that propagation path travels through 25 m of foliage
foliageDepth = 10;
L = (0.2)*(28.^(0.3))*(foliageDepth.^(0.6));
disp("Path loss due to foliage: " + L + " dB")

% Assign foliage loss as static SystemLoss on each receiver site
for rx = rxs3
    rx.SystemLoss = L;
end

% Compute signal strength with foliage loss
for rx = rxs3
    rx.SystemLoss = L;
    ss = sigstrength(rx,tx3,"freespace");
    disp("Signal strength at " + rx.Name + ":")
    disp(ss + " dBm")
end

% Compute signal strength including propagation through gas and rain. Use
% the "+" operator to add the propagation models to create a composite
% model including both atmospheric effects.
weatherpm = propagationModel("gas") + propagationModel("rain");
for rx = rxs3
    ss = sigstrength(rx,tx3,weatherpm);
    disp("Signal strength with  gas and rain at " + rx.Name + ":")
    disp(ss + " dBm")
    
    % Compute Bit Rate for each receiver site
    SINR = ss - noise_floor;
    Bitrate = bandwidth*(log2(1+SINR)); %ShannonCapacity
    disp("Bitrate at " + rx.Name + ":")
    disp(Bitrate + " bit/s")
end


fq = 28e9; % 28 GHz

tx4 = txsite("Name","Perpustakan Unsyiah", ...
     "Latitude", 5.5632, ...
    "Longitude",95.3295,...
    'AntennaHeight',25,...
    "TransmitterPower",0.01, ...
    "AntennaAngle", 300,...
    "TransmitterFrequency",fq);
%'Latitude', 5.557094374686165, ...
 %   'Longitude',95.32122413575227, ...
show(tx4)

rx13 = rxsite("Name","Bandar Baru 13", ...
    "Latitude",5.5601, ...
    "Longitude",95.3295);
rx14 = rxsite("Name","Bandar Baru 14", ...
   "Latitude",  5.5616, ...
   "Longitude", 95.3304);
rx15 = rxsite("Name","Bandar Baru 15", ...
    "Latitude", 5.5616, ...
    "Longitude", 95.3286);

rxs4 = [rx13, rx14, rx15];
show(rxs4)

rx13.AntennaHeight = 20;
rx14.AntennaHeight = 20;
rx15.AntennaHeight = 20;


tx4.Antenna = phased.URA('Size',[nrow ncol], ...
    'Element',antennaElement, ...
    'ElementSpacing',[drow dcol], ...
    'Taper',tap, ...
    'ArrayNormal','x');


% Plot pattern on the map
pattern(tx4)



% Assign array to each receiver site and point toward base station
for rx = rxs4
    rx.Antenna = rxarray;
    rx.AntennaAngle = angle(rx, tx4);
    pattern(rx,fq)
end

steeringVector = phased.SteeringVector("SensorArray",tx4.Antenna);
for rx = rxs4
    % Compute steering vector for receiver site
    [az,el] = angle(tx4,rx);
    sv = steeringVector(fq,[az;el]);
    
    % Update base station radiation pattern
    tx4.Antenna.Taper = conj(sv);
    pattern(tx4)
    
end

steeringVector = phased.SteeringVector("SensorArray",tx4.Antenna);

% Compute steering vector for receiver site
[az,el] = angle(tx4,rxs4);
sv = steeringVector(fq,[az el]');

% Update base station radiation pattern
tx4.Antenna.Taper = conj(sum(sv,2));
pattern(tx4)

% Compute signal strength (dBm)
for rx = rxs4
    ss = sigstrength(rx,tx4,"freespace");
    disp("Signal strength at " + rx.Name + ":")
    disp(ss + " dBm")
end

% Assume that propagation path travels through 25 m of foliage
foliageDepth = 10;
L = (0.2)*(28.^(0.3))*(foliageDepth.^(0.6));
disp("Path loss due to foliage: " + L + " dB")

% Assign foliage loss as static SystemLoss on each receiver site
for rx = rxs4
    rx.SystemLoss = L;
end

% Compute signal strength with foliage loss
for rx = rxs4
    rx.SystemLoss = L;
    ss = sigstrength(rx,tx4,"freespace");
    disp("Signal strength at " + rx.Name + ":")
    disp(ss + " dBm")
end

% Compute signal strength including propagation through gas and rain. Use
% the "+" operator to add the propagation models to create a composite
% model including both atmospheric effects.
weatherpm = propagationModel("gas") + propagationModel("rain");
for rx = rxs4
    ss = sigstrength(rx,tx4,weatherpm);
    disp("Signal strength with  gas and rain at " + rx.Name + ":")
    disp(ss + " dBm")
    
    % Compute Bit Rate for each receiver site
    SINR = ss - noise_floor;
    Bitrate = bandwidth*(log2(1+SINR)); %ShannonCapacity
    disp("Bitrate at " + rx.Name + ":")
    disp(Bitrate + " bit/s")
end



fq = 28e9; % 28 GHz

tx5 = txsite("Name","Perpustakan Unsyiah", ...
     "Latitude", 5.5632, ...
    "Longitude",95.3295,...
    'AntennaHeight',25,...
    "TransmitterPower",0.01 , ...
    "AntennaAngle", 135,...
    "TransmitterFrequency",fq);

show(tx5)

rx16 = rxsite("Name","Bandar Baru 16", ...
    "Latitude",5.5647, ...
    "Longitude",95.3268);
rx17 = rxsite("Name","Bandar Baru 17", ...
   "Latitude",  5.5648, ...
   "Longitude", 95.3286);
rx18 = rxsite("Name","Bandar Baru 18", ...
    "Latitude", 5.5632, ...
    "Longitude",95.3277);

rxs5 = [rx16, rx17, rx18];
show(rxs5)

rx16.AntennaHeight = 20;
rx17.AntennaHeight = 20;
rx18.AntennaHeight = 20;


tx5.Antenna = phased.URA('Size',[nrow ncol], ...
    'Element',antennaElement, ...
    'ElementSpacing',[drow dcol], ...
    'Taper',tap, ...
    'ArrayNormal','x');


% Plot pattern on the map
pattern(tx5)



% Assign array to each receiver site and point toward base station
for rx = rxs5
    rx.Antenna = rxarray;
    rx.AntennaAngle = angle(rx, tx5);
    pattern(rx,fq)
end

steeringVector = phased.SteeringVector("SensorArray",tx5.Antenna);
for rx = rxs5
    % Compute steering vector for receiver site
    [az,el] = angle(tx5,rx);
    sv = steeringVector(fq,[az;el]);
    
    % Update base station radiation pattern
    tx5.Antenna.Taper = conj(sv);
    pattern(tx5)
    
end

steeringVector = phased.SteeringVector("SensorArray",tx5.Antenna);

% Compute steering vector for receiver site
[az,el] = angle(tx5,rxs5);
sv = steeringVector(fq,[az el]');

% Update base station radiation pattern
tx5.Antenna.Taper = conj(sum(sv,2));
pattern(tx5)

% Compute signal strength (dBm)
for rx = rxs5
    ss = sigstrength(rx,tx5,"freespace");
    disp("Signal strength at " + rx.Name + ":")
    disp(ss + " dBm")
end

% Assume that propagation path travels through 25 m of foliage
foliageDepth = 10;
L = (0.2)*(28.^(0.3))*(foliageDepth.^(0.6));
disp("Path loss due to foliage: " + L + " dB")

% Assign foliage loss as static SystemLoss on each receiver site
for rx = rxs5
    rx.SystemLoss = L;
end

% Compute signal strength with foliage loss
for rx = rxs5
    rx.SystemLoss = L;
    ss = sigstrength(rx,tx5,"freespace");
    disp("Signal strength at " + rx.Name + ":")
    disp(ss + " dBm")
end

% Compute signal strength including propagation through gas and rain. Use
% the "+" operator to add the propagation models to create a composite
% model including both atmospheric effects.
weatherpm = propagationModel("gas") + propagationModel("rain");
for rx = rxs5
    ss = sigstrength(rx,tx5,weatherpm);
    disp("Signal strength with  gas and rain at " + rx.Name + ":")
    disp(ss + " dBm")
    
    % Compute Bit Rate for each receiver site
    SINR = ss - noise_floor;
    Bitrate = bandwidth*(log2(1+SINR)); %ShannonCapacity
    disp("Bitrate at " + rx.Name + ":")
    disp(Bitrate + " bit/s")
end
