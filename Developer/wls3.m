function sse = wls3(theta, t_obs, A_obs, K_obs, M_obs, n_obs, c, mu, opts)

    alpha = theta(1);
    Phi   = theta(2);
    gamma = theta(3);

    beta  = Phi/2;
    delta = Phi/2;

    if alpha <= mu || any([Phi,gamma] < 1e-6)
        sse = 1e10;
        return;
    end

    % Parameter structure
    p.alpha = alpha;
    p.c     = c;
    p.beta  = beta;
    p.delta = delta;
    p.gamma = gamma;
    p.mu    = mu;

    try

        sol = ode45(@(t,y) akm_moode(t,y,p), ...
                    [0 3], ...
                    [A_obs(1); K_obs(1); M_obs(1)], ...
                    opts);

        Yp = deval(sol,t_obs(2:end));

        Ap = max(Yp(1,:),0);
        Kp = max(Yp(2,:),0);
        Mp = max(Yp(3,:),0);

        w = n_obs(2:end);

        sse = sum( w .* ( ...
              (Ap-A_obs(2:end)).^2 + ...
              (Kp-K_obs(2:end)).^2 + ...
              (Mp-M_obs(2:end)).^2 ) );

    catch
        sse = 1e8;
    end

end