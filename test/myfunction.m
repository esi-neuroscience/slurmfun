function out = myfunction(in1, in2)

fprintf('Creating %g random numbers\n', in1)
out = rand(in1,in2);
tWait = randi(10)+40;
fprintf('Pausing for %g s\n', tWait)
pause(tWait);

