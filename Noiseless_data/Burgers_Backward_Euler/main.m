function main()
clc; close all;

addpath ./Utilities
addpath ./Exact
addpath ./Kernels
addpath ./export_fig

rng('default')

global ModelInfo

set(0,'defaulttextinterpreter','latex')

%% Setup
Ntr = 24;
Ntr_artificial = 101;
dim = 1;
lb = -ones(1,dim);
ub = ones(1,dim);
jitter = 1e-8;
ModelInfo.jitter=jitter;
noise = 0.0;

plt = 1;

T = 1;
dt = 1e-2;
nu = 0.01/pi;
ModelInfo.dt = dt;
ModelInfo.nu = nu;

num_plots = 3;

nsteps = T/dt;
%% Optimize model

ModelInfo.x_u = bsxfun(@plus,lb,bsxfun(@times,   lhsdesign(Ntr,dim)    ,(ub-lb)));
ModelInfo.u = InitialCondition(ModelInfo.x_u);
ModelInfo.u = ModelInfo.u + noise*randn(size(ModelInfo.u));

ModelInfo.S0 = zeros(Ntr);

ModelInfo.x_b = [-1; 1];
ModelInfo.u_b = [0; 0];

ModelInfo.hyp = log([1 1 exp(-6)]);

xstar = linspace(-1,1,400)';

if plt == 1
    fig = figure(1);
    set(fig,'units','normalized','outerposition',[0 0 1 .5])
    clf
    color2 = [217,95,2]/255;
    k = 1;
    subplot(2,num_plots,k)
    hold
    plot(xstar,InitialCondition(xstar),'b','LineWidth',3);
    plot(ModelInfo.x_u, ModelInfo.u,'ro','MarkerSize',12,'LineWidth',3);
    xlabel('$-1 \leq x \leq 1$')
    ylabel('$u(0,x)$')
    axis square
    ylim([-1.5 1.5]);
    set(gca, 'XTick', sort(ModelInfo.x_u));
    set(gca, 'XTickLabel', [])
    set(gca,'TickLength',[0.05 0.05]);
    set(gca,'FontSize',14);
    set(gcf, 'Color', 'w');
    tit = sprintf('Time: %.2f\n%d training points', 0,Ntr);
    title(tit);
    
    drawnow;
end

error = zeros(1,nsteps);
for i = 1:nsteps
    
    [ModelInfo.hyp,~,~] = minimize(ModelInfo.hyp, @likelihood, -5000);
    
    [NLML,~]=likelihood(ModelInfo.hyp);
    
    [Kpred, Kvar] = predictor(xstar);
    Kvar = abs(diag(Kvar));
    Exact = burgers_viscous_time_exact1( nu, 400, xstar, 1, i*dt );
    error(i) = norm(Kpred-Exact,2)/norm(Exact,2);
    
    fprintf(1,'Step: %d, Time = %f, NLML = %e, error_u = %e\n', i, i*dt, NLML, error(i));
    
    x_u = bsxfun(@plus,lb,bsxfun(@times,   lhsdesign(Ntr_artificial,dim)    ,(ub-lb)));
    [ModelInfo.u, ModelInfo.S0] = predictor(x_u);
    ModelInfo.x_u = x_u;
    if plt == 1 && mod(i,floor(nsteps/(2*num_plots-1)))==0
        k = k+1;
        subplot(2,num_plots,k)
        hold
        plot(xstar,Exact,'b','LineWidth',3);
        plot(xstar, Kpred,'r--','LineWidth',3);
        [l,p] = boundedline(xstar, Kpred, 2.0*sqrt(Kvar), ':', 'alpha','cmap', color2);
        outlinebounds(l,p);
        xlabel('$-1 \leq x \leq 1$')
        ylabel('$u(t,x)$')
        axis square
        ylim([-1.5 1.5]);
        set(gca, 'XTick', sort(ModelInfo.x_u));
        set(gca, 'XTickLabel', [])
        set(gca,'TickLength',[0.05 0.05]);
        set(gca,'FontSize',14);
        set(gcf, 'Color', 'w');
        tit = sprintf('Time: %.2f\nTime: %e\n%d artificial data', i*dt,error(i),Ntr_artificial);
        title(tit);
        
        drawnow;
        
    end
    
    
end

export_fig ./Figures/Burgers_noiseless.png -r300

rmpath ./Utilities
rmpath ./Exact
rmpath ./Kernels
rmpath ./export_fig