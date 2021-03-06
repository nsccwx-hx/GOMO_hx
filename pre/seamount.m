function[tb,sb,tclim,sclim,wusurf,wvsurf,wtsurf,wssurf,uvel,vvel,swrad] = seamount(e_atmos)
    global im jm kb pi slmax kbm1 zz tbias sbias jmm1 imm1 dx dy cor h      ...
       east_c north_c east_e   ...
       north_e east_u north_u east_v north_v rot fsm dum dvm;
       
tb=zeros(im,jm,kb)   ;sb=zeros(im,jm,kb)   ;tclim=zeros(im,jm,kb);sclim=zeros(im,jm,kb); wusurf=zeros(im,jm)  ;wvsurf=zeros(im,jm)  ;
wtsurf=zeros(im,jm)  ;wssurf=zeros(im,jm)  ;swrad=zeros(im,jm)   ;

% **********************************************************************
% *                                                                    *
% * FUNCTION    :  Sets up for seamount problem.                       *
% *                                                                    *
% **********************************************************************
%
%     Set delh > 1.0 for an island or delh < 1.0 for a seamount:
delh=0.9e0;
%     Grid size:
delx=8000.e0;
%     Radius island or seamount:
ra=25000.e0;
%     Current velocity:
uvel=0.2e0;
vvel=0.0e0;
dx=repmat( (delx-delx*sin(pi*[1:im]'/im)/2.0), 1, jm );
dy=repmat( (delx-delx*sin(pi*[1:jm]/jm)/2.0), im, 1  );
cor(:,:)=1.e-4;

%     Calculate horizontal coordinates of grid points and rotation
%     angle.
%
%     NOTE that this is introduced solely for the benefit of any post-
%     processing software, and in order to conform with the requirements
%     of the NetCDF Climate and Forecast (CF) Metadata Conventions.
%
%     There are four horizontal coordinate systems, denoted by the
%     subscripts u, v, e and c ("u" is a u-point, "v" is a v-point,
%     "e" is an elevation point and "c" is a cell corner), as shown
%     below. In addition, "east_*" is an easting and "north_*" is a
%     northing. Hence the coordinates of the "u" points are given by
%     (east_u,north_u).
%
%     Also, if the centre point of the cell shown below is at
%     (east_e(i,j),north_e(i,j)), then (east_u(i,j),north_u(i,j)) are
%     the coordinates of the western of the two "u" points,
%     (east_v(i,j),north_v(i,j)) are the coordinates of the southern of
%     the two "v" points, and (east_c(i,j),north_c(i,j)) are the
%     coordinates of the southwestern corner point of the cell. The
%     southwest corner of the entire grid is at
%     (east_c(1,1),north_c(1,1)).
%
%                      |              |
%                    --c------v-------c--
%                      |              |
%                      |              |
%                      |              |
%                      |              |
%                      u      e       u
%                      |              |
%                      |              |
%                      |              |
%                      |              |
%                    --c------v-------c--
%                      |              |
%
%
%     NOTE that the following calculation of east_c and north_c only
%     works properly for a rectangular grid with east and north aligned
%     with i and j, respectively:
%

% Compute east_c and north_c with matrix style. 
% The size of L1 is im*im and the size of R1 is jm*jm.
%  L0=[0 0 0 0 0 0 0]     R0=[0 1 1 1 1]
%     [1 0 0 0 0 0 0]        [0 0 1 1 1] 
%     [1 1 0 0 0 0 0]        [0 0 0 1 1]
%     [1 1 1 0 0 0 0]        [0 0 0 0 1]
%     [1 1 1 1 0 0 0]        [0 0 0 0 0]
%     [1 1 1 1 1 0 0]        
%     [1 1 1 1 1 1 0]        
%tic;
L0=tril(ones(im,im)) - eye(im,im);
R0=triu(ones(jm,jm)) - eye(jm,jm);
east_c=L0*dx;
north_c=dy*R0;

%     The following works properly for any grid:
%
%     Elevation points:

% Define additional matrix
% L =[1  1  0  0  0  0  0  0]    R= [1  0  0  0  0]
%    [0  1  1  0  0  0  0  0]       [1  1  0  0  0]
%    [0  0  1  1  0  0  0  0]       [0  1  1  0  0]
%    [0  0  0  1  1  0  0  0]       [0  0  1  1 -1]
%    [0  0  0  0  1  1  0  0]       [0  0  0  1  3]
%    [0  0  0  0  0  1  1  0]       [0  0  0  0  1]
%    [0  0  0  0  0 -1  3  1]  
%
% T =[0    0    0    0    0   ]
%    [0    0    0    0    0   ]
%    [0    0    0    0    0   ]
%    [0    0    0    0    0   ]
%    [0    0    0    0   -0.5 ]
%    [0    0    0    0    1   ]
%    [0    0   -0.5  1    0   ]
L1=[eye(im) zeros(im,1)];
L2=[zeros(im,1) eye(im)];
L3= zeros(im,im+1); L3(im,im-1)=-1;
L4= zeros(im,im+1); L4(im,im  )= 2;
L=L1+L2+L3+L4;

R1=[eye(jm); zeros(1,jm)];
R2=[zeros(1,jm); eye(jm)];
R3= zeros(jm+1,jm); R3(jm-1,jm)=-1;
R4= zeros(jm+1,jm); R4(jm  ,jm)= 2;
R=R1+R2+R3+R4;

T=zeros(im,jm); T(im,jm-1)=1;  T(im,jm-2)=-0.5;  T(im-1,jm)=1; T(im-2,jm)=-0.5;

% Compute east_e with matrix style
A1=zeros(im+1,jm+1);
A1(1:im,1:jm)=east_c;
B1=0.25*L*A1*R;
B1(im,jm) = sum(sum(T.*B1,1),2);
east_e=B1;

% Compute north_e with matrix style
A2=zeros(im+1,jm+1);
A2(1:im,1:jm)=north_c;
B2=0.25*L*A2*R;
B2(im,jm) = sum(sum(T.*B2,1),2);
north_e=B2;


% Compute east_u with matrix style
A3=zeros(im,jm+1);
A3(1:im,1:jm)=east_c;
B3=A3*R/2.0;
east_u=B3;

% Compute north_u with matrix style
A4=zeros(im,jm+1);
A4(1:im,1:jm)=north_c;
B4=A4*R/2.0;
north_u=B4;


% Compute east_v with matrix style
A5=zeros(im+1,jm);
A5(1:im,1:jm)=east_c;
B5=L*A5/2.0;
east_v=B5;

% Compute north_v with matrix style
A6=zeros(im+1,jm);
A6(1:im,1:jm)=north_c;
B6=L*A6/2.0;
north_v=B6;

%     rot is the angle (radians, anticlockwise) of the i-axis relative
%     to east, averaged to a cell centre:
%
%     (NOTE that the following calculation of rot only works properly
%     for this particular rectangular grid)
%
rot=zeros(im,jm);

%     Define depth:

W1= east_c  - repmat( east_c ((im+1)/2,:), im, 1 );
W2= north_c - repmat( north_c(:,(jm+1)/2), 1 , jm);
h=4500.0*(1.e0-delh*exp((-W1.^2 - W2.^2)/ra^2));
h(h<1.0) = 1.0;

%     Close the north and south boundaries to form a channel:
h(:,1) =1.0;
h(:,jm)=1.0;

%     Calculate masks:
areas_masks();
    for j=2:jmm1
        for i=2:imm1
                wusurf(i,j)=1.00*(1.e-4*cos(pi*(j-1)/jmm1))  ...
                    *0.25*(dvm(i,j+1)+dvm(i-1,j+1)     ...
                    +dvm(i-1,j)+dvm(i,j));
                wvsurf(i,j)=0.e0;
        end
    end
%     Adjust bottom topography so that cell to cell variations
%     in h for not exceed parameter slmax:
if(slmax < 1.e0) 
	[h] = slpmax(h,im,jm,fsm,slmax);
end

% Set initial conditions:
for k=1:kbm1
    tb(:,:,k)=5.0+15.0*exp(zz(k)*h(:,:)/1000.0)-tbias;
    sb(:,:,k)=35.0-sbias;
    tclim(:,:,k)=tb(:,:,k);
    sclim(:,:,k)=sb(:,:,k);
end 

