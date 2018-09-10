function [gd_wpr] = run_imm(gd_mat, fig)
%RUN_IMM perform IMM algorithm on the specified GPS data mat file
%
%   Parameters:
%     gd_mat - GPS data file path and name
%     fig - flag to output figure or not
%
%  Yang Wang 09/08/2018

  load(gd_mat); % load in GPS data

  % copy the original struct contents
  for m = 1:length(gd)
    for fn = fieldnames(gd{m})'
      gd_wpr{m}.(fn{1}) = gd{m}.(fn{1});
    end
  end

  dims = 5;
  hdims = 3;
  nmodels = 3;

  % Sampling interval is 1 second
  dt = 1;

  % Spaces for function handles
  a_func = {};
  a_param = {};

  a_func{1} = [];
  a_func{2} = @f_turn;
  a_func{3} = [];
  a_param{1} = [];
  a_param{2} = {dt};
  a_param{3} = [];

  % Space for model parameters
  ind = cell(1,nmodels);
  F = cell(1,nmodels);
  L = cell(1,nmodels);
  Qc = cell(1,nmodels);
  A = cell(1,nmodels);
  Q = cell(1,nmodels);
  R = cell(1,nmodels);
  H = cell(1,nmodels);

  % Indices for indexing different model parameters
  ind{1} = [1 2 3 4]';
  ind{2} = [1 2 3 4 5]';
  ind{3} = [1 2]';

  % Model 1
  F{1} = [0 0 1 0;
          0 0 0 1;
          0 0 0 0;
          0 0 0 0];

  L{1} = [0 0;
          0 0;
          1 0;
          0 1];

  q1 = 0.01;
  Qc{1} = q1 * eye(2);

  [A{1}, Q{1}] = lti_disc(F{1}, L{1}, Qc{1}, dt);

  % Model 2
  A{2} = @f_turn_dx;

  Qc{2} = 0.05;

  L{2} = [0 0 0 0 1]';

  Q{2} = L{2} * Qc{2} * L{2}' * dt;

  % Model 3
  A{3} = [1 0;
          0 1];

  Q{3} = [0.01 0;
          0 0.01];

  % Process noise variance
  KF_q1 = 0.01;
  KF_Qc1 = diag([KF_q1 KF_q1]);

  % Discretization of the continous-time system.
  [KF_A1,KF_Q1] = lti_disc(F{1}, L{1}, KF_Qc1, dt);

  % Measurement models
  H{1} = [1 0 0 0;
          0 1 0 0];

  H{2} = [1 0 0 0 0;
          0 1 0 0 0];

  H{3} = [1 0;
          0 1];

  % Initial probabilities
  mu_ip = [0.01 0.01 0.98];
  mu_0j = mu_ip;

  % Transition matrix
  p_ij = [0.70 0.20 0.10;
          0.20 0.70 0.10;
          0.45 0.45 0.10];

  % Measurement noise covariance matrices
  r1 = 0.05;
  r2 = 0.15;
  R{1} = diag([r1 r2]);

  r1 = 0.15;
  r2 = 0.45;
  R{2} = diag([r1 r2]);

  r1 = 0.01;
  r2 = 0.05;
  R{3} = diag([r1 r2]);

  % Initial estimates
  % EKF based IMM
  x_ip1{1} = [0 0 0 0]';
  x_ip1{2} = [0 0 0 0 0]';
  x_ip1{3} = [0 0]';
  mu_ip1 = mu_ip;

  P_ip1{1} = diag([0.1 0.1 0.1 0.1]);
  P_ip1{2} = diag([0.1 0.1 0.1 0.1 0.1]);
  P_ip1{3} = diag([0.1 0.1]);

  for m = 1:length(gd_wpr)
    fprintf('\tIMM algorithm is working on %s GPS data\n', gd_wpr{m}.id);
    [x, y] = convert_to_xy(gd_wpr{m}.lat, gd_wpr{m}.lon);

    % add UTM coords to the struct
    gd_wpr{m}.x = x;
    gd_wpr{m}.y = y;

    X = [x-x(1) y-y(1)]';

    for l = 1:size(X,2)
      % EKF based IMM
      [x_p1,P_p1,c_j1] = eimm_predict(x_ip1,P_ip1,mu_ip1,p_ij,ind,dims, ...
                                      A,a_func,a_param,Q);
      [x_ip1,P_ip1,mu_ip1,m1,P1] = eimm_update(x_p1,P_p1,c_j1,ind,dims, ...
                                              X(:,l),H,[],R,[]);
      EIMM_MM(:,l) = m1;
      EIMM_PP(:,:,l) = P1;
      EIMM_MU(:,l) = mu_ip1';
      EIMM_MM_i(:,l) = x_ip1';
      EIMM_PP_i(:,l) = P_ip1';
    end

    % add model probabilities to the struct
    gd_wpr{m}.mu = EIMM_MU';

    clear X
    clear EIMM_*
    fprintf('\tDone.\n');
  end

end %EOF