function  [mDistPixel] = ComputeD2Complexity(filename1, filename2)
% To compute ISmai with two-layer blk matching.
% First layer uses non-overlapping perfect match
% Second layer uses co-located area, but allow smaller blks.

% modified based on 7, to see what we get with larger image size without
% sliding window.

% within 8x8 block, try to match pixel by pixel


   sizef = 264*264;
   %sizef = 136*136;
   [ X1oriL] = ReadResizeGrayImage(filename1, sizef) ;
   [ X2oriL] = ReadResizeGrayImage(filename2, sizef) ;
   figure, imshow(uint8(X1oriL));
   figure, imshow(uint8(X2oriL));
   %[row col] = size(X2ori);
   %X1ori(1:row, 1:col) = X1ori(1:row, 1:col)/0.95; % / max(max(X1ori(1:row, 1:col))) * max(max(X2ori(1:row, 1:col))) ;
   %X1ori(1:row/3, 1:col) = X2ori(1:row/3, 1:col)  ;
   %X2ori(1:row/3, 1:col) = X2ori(1:row/3, 1:col) -25 ;
   %X2ori(row/2:row, 1:col) = X2ori(row/2:row, 1:col) -15 ;
    
   %figure
   %imshow(uint8(X1oriL));
   %figure
   %imshow(uint8(X2oriL));
   
   % watch the same size
   [rowL, colL] = size(X1oriL);
   [row2, col2] = size(X2oriL);
   if rowL ~= row2 || colL ~= col2
       fprintf('size different\n');
       mDistPixel=0;
       return ;
   end
   [~, MseMinPos] = SearchByMSE(X1oriL, X2oriL) ;
   m = floor((MseMinPos(1) - 1) / 8) + 1;
   n = mod(MseMinPos(1) - 1, 8) + 1;
   % map  X1ori(5:row-12, 5:col-12) to X2ori(m:row-17+m, n:col-17+n)
   % find the links between 8x8 blocks
   X1L = X1oriL(5:rowL-4, 5:colL-4);
   X2L = X2oriL(m:rowL-9+m, n:colL-9+n) ;
   [~, Cedges, blkcost_layer1] = DoEdmondMatch(X1L - mean(X1L(:)), X2L - mean(X2L(:)), 8) ;
   
   fprintf('blkcost_L1: %8.3f  \n', blkcost_layer1/64);

   %X1H = X1oriH(17:4*rowL-16, 17:4*colL-16);
   %X2H = X2oriH(4*m-3:4*rowL+4*m-36, 4*n-3:4*colL+4*n-36) ;
   blkcost_layer2 = DoEmdondMatchLayer2(Cedges, X1L-mean(mean(X1L)), X2L-mean(mean(X2L)));
   
   fprintf('blkcost_L2: %8.3f \n', blkcost_layer2/64);
  
   mDistPixel  = blkcost_layer2/64;
      
% search by MSE for a few locations 
function [Y, MseMinPos] = SearchByMSE(X1ori, X2ori)
   [row, col] = size(X1ori);
   
   BlkMse = zeros(64,1);
   X1 = X1ori(5:row-4, 5:col-4);
   for m=1:8
   for n=1:8    
       X2 = X2ori(m:row-9+m, n:col-9+n);           
       BlkMse((m-1)*8+n) =  sum(sum((X1-X2).^2))*64/(row-8)/(col-8) ;
   end
   end
   [Y, MseMinPos] = sort(BlkMse);
   
function [Gsmallcrop]= ReadResizeGrayImage(filename, sizef)
    I = imread(filename);
    
    n = size(I, 3);
    
    if n == 3
      G = rgb2gray(I);
    else
      G = I ;  
    end
    
    [row, col] = size(G);
     
    t = sqrt( sizef/row/col );
    Gsmall = double(imresize(G, t)) ;
    % crop it 
    [row, col] = size(Gsmall);
    Gsmallcrop = Gsmall(1:floor(row/8)*8, 1:floor(col/8)*8);
    

function blkcost = DoEmdondMatchLayer2(edges, X1, X2)
    Ne = size(edges, 1);
    [row, col] = size(X1);
    
    blkrowL = row/8;
    blkcolL = col/8;   
    
    totalcost = 0 ;
    
    for n=1:Ne
        Id1 = edges(n,1);
        Id2 = edges(n,2);
        
        blki1 = floor(Id1/blkcolL) + 1 ;
        blkj1 = mod(Id1, blkcolL) +1 ;
        blki2 = floor(Id2/blkcolL) + 1 ;
        blkj2 = mod(Id2, blkcolL) +1 ;
        
        %if blki1==blkrow || blki2==blkrow || blkj1==blkcol || blkj2==blkcol
        %   continue ;
        %end
        
        Center_i1 = (blki1-1)*8 + 1 ;
        Center_j1 = (blkj1-1)*8 + 1 ;
        Center_i2 = (blki2-1)*8 + 1 ;
        Center_j2 = (blkj2-1)*8 + 1 ;
        
        %i1 = Center_i1 ;
        %j1 = Center_j1 ;
        %i2 = Center_i2 ;
        %j2 = Center_j2 ;
        
           % block1 = X1(max(Center_i1-2,1):min(Center_i1+7+2, row), max(Center_j1-2,1):min(Center_j1+7+2, col)); 
           % block2 = X2(max(Center_i2-2,1):min(Center_i2+7+2, row), max(Center_j2-2,1):min(Center_j2+7+2, col)); 
            block1 = X1( Center_i1:Center_i1+7, Center_j1:Center_j1+7 );
            block2 = X2( Center_i2:Center_i2+7, Center_j2:Center_j2+7 );
        %    [ClinkMat Clink cost] = DoEdmondMatch(block1, block2, 1) ;
            
        %    totalcost = totalcost + cost ;
        [cost] = DoHungarianMatch(block1, block2, 2) ;
         totalcost = totalcost + cost*16 ;
        
        %   Given block1, search for block2    
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
    end
    
      
    blkcost = totalcost/Ne ;  % per block 
    
      %fprintf('Layer2 %f \n', blkcost);
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ClinkMat, Clink, cost] = DoEdmondMatch(X1, X2, blksize)
      [row, col] = size(X1);
      M = round(row/blksize);
      N = round(col/blksize);
      
      Len = M*N;
         
      weight = zeros(Len, Len);
      for r1=1:M
      for c1=1:N
          block1 = X1( (r1-1)*blksize+1:r1*blksize, (c1-1)*blksize+1:c1*blksize );
          for r2=1:M
          for c2=1:N
             block2 = X2( (r2-1)*blksize+1:r2*blksize, (c2-1)*blksize+1:c2*blksize );
             weight((r1-1)*N+c1, (r2-1)*N+c2) = sum(sum(((block1-block2).^2)));
          end
          end
      end
      end

      scale = 100 ;
      % from weight matrxi to graph
      weight = round(weight*scale) ;  % convert to integers
      Graph = zeros(Len*Len, 3) ;
      pos = 1; 
      for m=1:Len
      for n=1:Len
          Graph(pos, 1:3) = [ m-1, n-1+Len,  weight(m,n) ] ;
          pos = pos + 1;
      end
      end

    WriteGraphBindata('tmpdat.bin', Len, Len*Len, Graph) ;

    system('blossom.exe -e tmpdat.bin -w tmplink.bin');


    [~, Clink, ClinkMat, matchcost] = ReadLinks('tmplink.bin') ;

  
      %[link cost] = Hungarian(weight);
      
      cost = matchcost/Len/scale;  % per block 
      
      
      if 0
                  if Len<=256*256
                    [link Huncost] = Hungarian(weight);
                    if Huncost ~= matchcost
                        fprintf('Hungarian does not match with Edmond. Something wrong.\n');
                    else
                        fprintf('Hungarian matches with Edmond.\n');
                    end
                  end
      end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [cost] = DoHungarianMatch(X1, X2, blksize)
      [row1 col1] = size(X1);
      [row2 col2] = size(X2);
      row = min(row1, row2);
      col = min(col1, col2);
      M = round(row/blksize);
      N = round(col/blksize);
      
      Len = M*N;
         
      weight = zeros(Len, Len);
      for r1=1:M
      for c1=1:N
          block1 = X1( (r1-1)*blksize+1:r1*blksize, (c1-1)*blksize+1:c1*blksize );
          for r2=1:M
          for c2=1:N
             block2 = X2( (r2-1)*blksize+1:r2*blksize, (c2-1)*blksize+1:c2*blksize );
             weight((r1-1)*N+c1, (r2-1)*N+c2) = sum(sum(((block1-block2).^2)));
          end
          end
      end
      end
      [link cost] = Hungarian(weight);
      
      cost = cost/Len;  % per block 

 
%%%%%%%%%%%%%
% Clink stores (id1 id2)-pairs of edges, idx\in[0, N-1]
function   [Nnode, Clink, ClinkMat, matchcost] = ReadLinks(filename)
  fin = fopen(filename, 'r');
  
  Nnode = fscanf(fin, '%d', 1);
  Nlink = fscanf(fin, '%d', 1);
  
  Clink = zeros(Nlink, 2);
  tmp = fscanf(fin, '%d', 2*Nlink);
  for n=1:Nlink
      Clink(n,1) = tmp( n*2 -1 ) ;
      Clink(n,2) = tmp( n*2 ) ;
  end
  fclose(fin);
  
  
  % convert to matrix format for matlab use.
  ClinkMat=zeros(Nnode/2, Nnode/2);
  SingleNnode = Nnode/2 ;
  for n=1:Nlink % in C code, diff indexes are used for col and row nodes.
     Clink(n,2) = Clink(n,2) - SingleNnode ; % In C, we need to differ, but not here
     ClinkMat( Clink(n,1)+1, Clink(n,2)+1 ) = 1 ; 
  end

  fin=fopen('matchcost.dat', 'r');
  matchcost = fscanf(fin, '%f', 1);
  fclose(fin);

  
% GraphEdges store Nedge-x-3 matrix for the edges.
function WriteGraphBindata(filename, Nnode, Nedge, GraphEdges)
   fout = fopen(filename, 'wb');
    
   fwrite(fout, 2*Nnode, 'integer*4');
   fwrite(fout, Nedge, 'integer*4');
   Graphout = GraphEdges' ;  % write column by column
   fwrite(fout, Graphout, 'integer*4');
   fclose(fout);    