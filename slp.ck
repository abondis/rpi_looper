// create our OSC receiver
OscRecv orec;
// port 6449
6449 => orec.port;
// start listening (launch thread)
orec.listen();

//a simple signal path
adc => LiSa saveme => dac;

//gotta tell LiSa how much memory to allocate
8 => int max_voices;
10::second => dur max_voice_dur;
max_voices * max_voice_dur => saveme.duration;

saveme.recRamp(200::ms);

//var to know if recoding or playing
string state[max_voices];
for( 0 => int i; i < max_voices ; i++ )
{
    "paused" => state[i];
}
time start_time;
dur loop_duration;
function void start_recording(int v) {
    //start recording
    //reserve 'max_voice_dur' gap for each voice
    saveme.recPos(v * max_voice_dur);
    // set this voice's starting point in the LiSa
    saveme.loopStart(v, v * max_voice_dur);
    1 => saveme.record;
    // start counting for the loop duration
    now => start_time;
    "recording" => state[v];
    // set a timeout to force stopping the loop recording at 'max_voice_dur'
    spork ~ timeout_recording(v);
}

function void timeout_recording(int v) {
    max_voice_dur => now;
    if ( state[v] == "recording") {
        stop_recording(v);
    }
}
function void stop_recording(int v) {
    //stop recording
    0 => saveme.record;
    // save loop duration
    now - start_time => loop_duration;
    <<< "loop_duration:", loop_duration>>>;
    // keep duration ?
    saveme.loopEnd(v, v * max_voice_dur + loop_duration);
    "paused" => state[v];
}

function void start_stop_recording()
{ 
    int v;
    // create an address in the receiver 
    // and store it in a new variable.
    orec.event("/record,i") @=> OscEvent record_event; 

    while ( true )
    { 
        record_event => now; // wait for events to arrive.

        // grab the next message from the queue. 
        while( record_event.nextMsg() != 0 )
        { 
            record_event.getInt() => v;
            <<< "state[v]", state[v] >>>;
            if (state[v] == "playing") {
                stop_playing(v);
            }
            if (state[v] == "paused") {
                <<< "recoding" >>>;
                start_recording(v);
            }
            else {
                if (state[v] == "recording"){
                <<< "stopped recording" >>>;
                    stop_recording(v);
                    start_playing(v);
                }
            }
        }
    }
}
function void stop_playing(int v) {
    <<< "stop recording">>>;
    "paused" => state[v];
    saveme.loop(v, 0);
    saveme.play(v, 0);
}
function void start_playing(int v) {
    <<< "start playing">>>;
    "playing" => state[v];
    saveme.loop(v, 1);
    saveme.play(v, 1);
}

function void play_loop()
{ 
    int v;
    orec.event("/play,i") @=> OscEvent play_event; 
    while ( true )
    {
        play_event => now; // wait for events to arrive.
        // grab the next message from the queue. 
        while( play_event.nextMsg() != 0 )
        {
            play_event.getInt() => v;
            <<< "play event, state[v]:", state[v] >>>;
            if (state[v] == "recording") {
                stop_recording(v);
            }
            if (state[v] == "playing") {
                <<< "stop playing">>>;
                stop_playing(v);
            }
            else {
                if (state[v] == "paused") {
                    start_playing(v);
                }
            }
        }
    }
}
spork ~ start_stop_recording();
spork ~ play_loop();

while (true) {
    10::second => now;
}

