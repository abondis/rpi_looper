// create our OSC receiver
OscRecv orec;
// port 6449
6449 => orec.port;
// start listening (launch thread)
orec.listen();

//a simple signal path
adc => LiSa saveme => dac;

//gotta tell LiSa how much memory to allocate
60::second => saveme.duration;

saveme.recRamp(200::ms);
<<< "recording 1" >>>;
1::second => now;
1 => saveme.record;
3::second => now;
0 => saveme.record;
saveme.loopStart(1, 0::second);
saveme.loopEnd(1, 3::second);
<<< "recording 2" >>>;
1::second => now;
1 => saveme.record;
10::second => now;
0 => saveme.record;
saveme.loopStart(2, 3::second);
saveme.loopEnd(2, 13::second);
saveme.loop(1,1);
saveme.loop(2,1);
<<< "playing">>>;
saveme.play(1,1);
saveme.play(2,1);
while (true) {
    1::second => now;
}
