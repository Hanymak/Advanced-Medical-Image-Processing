clear all;
close all;
clc;

load('/Users/ranhao/Desktop/test_image/hand_testpoints2.mat'); %TestActiveShape_a, TestActiveShape_2016,ActiveShapeTest6_2017 
load('/Users/ranhao/Desktop/test_image/hand_Modelpoints.mat'); % hand model

xy = xy2;

Nhands = 10;
Nsample = size(xy,1) - 1; % resmapling method is N+1....

figure(1);

sampleHandPts = cell(Nhands,1);
subplot(2,2,1);
for i = 1:Nhands
    handSample = hand_points{i,1};
    handSample = handSample';
    
    plot(handSample(1,:), handSample(2,:),'r*','linewidth',1);
    hold on;
    plot(handSample(1,:), handSample(2,:),'r-','linewidth',1);
    hold on;
    
    %----- resample ------
    sampleHandPts{i} = resampling(Nsample, handSample(1,:), handSample(2,:));
    
    disp(i);
    pause;
end

init_mean = sampleHandPts{1,1};
dist = 100;

for i = 1 : 50
    
    x_vec = init_mean(1,:);
    y_vec = init_mean(2,:);

    [updatePts, transformMatrix] = pointBaseRegistration(sampleHandPts{1,1}, x_vec, y_vec);
    totalPts = updatePts;
    for j = 2:Nhands
        queryPts = sampleHandPts{j,1};
        [updatePts, transformMatrix] = pointBaseRegistration(queryPts, x_vec, y_vec);
        totalPts = totalPts + updatePts;
    end
    totalPts = totalPts / Nhands;
    
    dist = norm(init_mean - totalPts)
    if dist < 6.9
        break;
    end
    init_mean = totalPts;

end
hold off;

%-------- show mean hand space --------
subplot(2,2,2);
registerPts = sampleHandPts;
for i = 1 : Nhands

    handSample = sampleHandPts{i,1};
  
    [registerPts{i,1}, transformMatrix] = pointBaseRegistration(handSample, init_mean(1,:), init_mean(2,:));

    plot(registerPts{i,1}(1,:), registerPts{i,1}(2,:),'b*','linewidth',1);
    hold on;
    plot(registerPts{i,1}(1,:), registerPts{i,1}(2,:),'b-','linewidth',1);
    hold on;
end

subplot(2,2,3);
plot(init_mean(1,:), init_mean(2,:),'r*','linewidth',1);
hold on;
plot(init_mean(1,:), init_mean(2,:),'r-','linewidth',1);

disp('ENTER to continue to part 2');
pause;
%------- reorgnaize the sample points -----
hand_models = [];
for i = 1: Nhands
    dataVec = getDataVec(registerPts{i,1});
    hand_models = [hand_models , dataVec]; %form a matrix of all the hands
end

meanVec = getDataVec(init_mean);

%---- get cov matrix ----
% when size are too big

covSize = size(hand_models, 1);
A = [];
for i = 1 : Nhands
    A = [A,hand_models(:,i) - meanVec];
end
covMatrix = A'*A / 10;

% % -------- get the eigen vector and coeff b -------------
[eigVecMat, latent] = pcacov(covMatrix);

eigVecMat = A * eigVecMat;
for i = 1 : Nhands
    eigVecMat(:,i) = eigVecMat(:,i) / sqrt(latent(i) * Nhands);
end

figure(2);
for i = -100:10:100

    subplot(2,2,1);
    EigenShape1 = meanVec + i * squeeze(eigVecMat(:,1));
    handPts = getDataVecToPts(EigenShape1);
    
    plot(handPts(1,:), handPts(2,:),'r*','linewidth',1);
    hold on;
    plot(handPts(1,:), handPts(2,:),'r-','linewidth',1);

    hold off;

    subplot(2,2,2);
    EigenShape2 = meanVec + i * squeeze(eigVecMat(:,2));
    handPts = getDataVecToPts(EigenShape2);
    
    plot(handPts(1,:), handPts(2,:),'r*','linewidth',1);
    hold on;
    plot(handPts(1,:), handPts(2,:),'r-','linewidth',1);

    hold off;
    
    subplot(2,2,3);
    EigenShape3 = meanVec + i * squeeze(eigVecMat(:,3));
    handPts = getDataVecToPts(EigenShape3);
    
    plot(handPts(1,:), handPts(2,:),'r*','linewidth',1);
    hold on;
    plot(handPts(1,:), handPts(2,:),'r-','linewidth',1);

    hold off;
    
    subplot(2,2,4);
    EigenShape4 = meanVec + i * squeeze(eigVecMat(:,4));
    handPts = getDataVecToPts(EigenShape4);
    
    plot(handPts(1,:), handPts(2,:),'r*','linewidth',1);
    hold on;
    plot(handPts(1,:), handPts(2,:),'r-','linewidth',1);

    hold off;
    
    pause;
end

disp('ENTER to continue to part 3');
pause;

%-------- start the hand fitting process ----------
figure(3);
hlayer = ones(1,Nsample+1);

[sampledTargetPts] = resampling(Nsample, xy(:,1)', xy(:,2)');

target_X = xy(:,1)';
target_Y = xy(:,2)';

subplot(2,2,1);
plot(target_X(1,:), target_Y(1,:),'r*','linewidth',2);
hold on;
plot(target_X(1,:), target_Y(1,:),'r-','linewidth',2);
hold on;

plot(init_mean(1,:), init_mean(2,:),'g*','linewidth',1);
hold on;
plot(init_mean(1,:), init_mean(2,:),'g-','linewidth',1);
hold off;  

%---------start the active shape building ----------
[Xcm, meanTargetMat] = pointBaseRegistration(sampledTargetPts, init_mean(1,:), init_mean(2,:));
meanTargetMat = meanTargetMat^(-1);

subplot(2,2,2);
for i = 1:10
  
    Xcm = getDataVec(Xcm);
    b_vec = eigVecMat' * (Xcm - meanVec);
    
%     b_vec(9:10) = 0;
    
    % reformat to the point space
    newVec = meanVec + eigVecMat * b_vec;
    X_new = getDataVecToPts(newVec);

    [Xc, meanTargetMat] = pointBaseRegistration(X_new, sampledTargetPts(1,:), sampledTargetPts(2,:));
    
    Xc = [Xc;hlayer];
    Xcm = X_new;
    
    plot(target_X(1,:), target_Y(1,:),'r*','linewidth',1);
    hold on;
    plot(target_X(1,:), target_Y(1,:),'r-','linewidth',1);
    hold on;

    plot(Xc(1,:), Xc(2,:),'g*','linewidth',1.5);
    hold on;
    plot(Xc(1,:), Xc(2,:),'g-','linewidth',1.5);
    hold off; 

    ite = [num2str(i),' th iteration'];
    disp(ite);
    pause;
    
end
subplot(2,2,3);

plot(target_X(1,:), target_Y(1,:),'r*','linewidth',1);
hold on;
plot(target_X(1,:), target_Y(1,:),'r-','linewidth',1);
hold on;

plot(Xc(1,:), Xc(2,:),'g*','linewidth',1);
hold on;
plot(Xc(1,:), Xc(2,:),'g-','linewidth',1);
