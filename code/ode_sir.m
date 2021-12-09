function Xdot = ode_sir(t,x,p,Iapp)
   Xdot=zeros(3,1);
   Xdot(1)=-p(1)*x(1)*x(2)/p(3);
   Xdot(2)=p(1)*x(1)*x(2)/p(3)-p(2)*x(2);
   Xdot(3) = p(2)*x(2);
end
